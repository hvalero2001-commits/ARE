#!/bin/bash
#############################################################
#
# F2B-IPSET
# Database Module
# Version 2.0.1
#
#############################################################

#############################################################
# Ejecutar SQL
#############################################################

db_exec() {

    local SQL="$1"

    local RESULT

    RESULT=$(
        sqlite3 \
            -batch \
            -cmd ".timeout ${DB_TIMEOUT}" \
            "$DB_FILE" \
            "$SQL" 2>&1
    )

    local RC=$?

    if [ "$RC" -ne 0 ]
    then

        db_error "$RC" "$RESULT"

        return "$RC"

    fi

    echo "$RESULT"

    return 0

}

#############################################################
# Ejecutar Transacción
#############################################################

db_transaction() {

    local SQL="$1"

    local RESULT

    RESULT=$(
        sqlite3 \
            -batch \
            -cmd ".timeout ${DB_TIMEOUT}" \
            "$DB_FILE" <<EOF
		BEGIN IMMEDIATE;
		${SQL}
		COMMIT;
		EOF
    		2>&1
    )

    local RC=$?

    if [ "$RC" -ne 0 ]; then

        sqlite3 "$DB_FILE" "ROLLBACK;" >/dev/null 2>&1

        db_error "$RC" "$RESULT"

        return "$RC"

    fi

    echo "$RESULT"

    return 0

}

#############################################################
# Error Handler
#############################################################

db_error() {

    local RC="$1"

    local MSG="$2"

    ERROR "SQLite Error [$RC]: $MSG"

    return "$RC"

}

#############################################################
# Verificar Base
#############################################################

db_check() {

    db_exec "SELECT 1;" >/dev/null

}

#############################################################

db_begin(){

    db_exec "BEGIN TRANSACTION;"

}
#############################################################

db_commit(){

    db_exec "COMMIT;"

}
#############################################################

db_rollback(){

    db_exec "ROLLBACK;"

}

#############################################################
# Inicializa la Base de Datos
#############################################################

db_init() {

    # Crear la base si no existe
    if [ ! -f "$DB_FILE" ]; then

        INFO "Creando base de datos..."

        sqlite3 "$DB_FILE" ""

    fi

    db_exec "
    CREATE TABLE IF NOT EXISTS hosts(
        ip TEXT PRIMARY KEY,
        family TEXT,
        first_seen INTEGER,
        last_seen INTEGER,
        status TEXT,
        ban_until INTEGER
    );
    "

    db_exec "
    CREATE TABLE IF NOT EXISTS reputation(
        ip TEXT PRIMARY KEY,
        recon_score INTEGER,
        exploit_score INTEGER,
        credential_score INTEGER,
        protocol_score INTEGER,
        bot_score INTEGER,
        total_score INTEGER,
        updated INTEGER
    );
    "

    db_exec "
    CREATE TABLE IF NOT EXISTS jail_profile(
        name TEXT PRIMARY KEY
        category TEXT,
        weight INTEGER,
        decay REAL,
        description TEXT
    );
    "

    db_exec "
    CREATE TABLE IF NOT EXISTS events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha INTEGER,
        ip TEXT,
        action TEXT,
        jail TEXT,
        timeout INTEGER
    );
    "

    db_exec "
    CREATE TABLE IF NOT EXISTS config(
        key TEXT PRIMARY KEY,
        value TEXT
    );
    "

    db_exec "
    CREATE TABLE IF NOT EXISTS jails(
        name TEXT PRIMARY KEY,
        hits INTEGER DEFAULT 0
    );
    "

    db_exec "
    INSERT OR IGNORE INTO config
    VALUES('version','2.0');
    "

}

#############################################################
# Información de la Base
#############################################################

db_info() {

    INFO "========== DATABASE =========="

    INFO "Archivo..... $DB_FILE"

    INFO "Versión..... $(sqlite3 "$DB_FILE" "select sqlite_version();")"

    INFO "Hosts....... $(db_exec 'select count(*) from hosts;')"

    INFO "Eventos..... $(db_exec 'select count(*) from events;')"

}

#############################################################
# Devuelve la versión del esquema
#############################################################

db_get_version() {

    db_exec "SELECT value FROM config WHERE key='version';"

}

#############################################################
# ¿Existe el host?
#############################################################

db_host_exists() {

    local IP="$1"

    local RESULT

    RESULT=$(db_exec "SELECT COUNT(*) FROM hosts WHERE ip='$IP';")

    [ "$RESULT" -gt 0 ]

}

#############################################################
# Registrar Host
#############################################################

db_add_host() {

    local IP="$1"

    local FAMILY="$2"

    local NOW

    NOW=$(date +%s)

    db_exec "

        INSERT INTO hosts(

            ip,

            family,

            first_seen,

            last_seen,

            hits,

            status

        )

        VALUES(

            '$IP',

            '$FAMILY',

            $NOW,

            $NOW,

            1,

            'FREE'

        );

    "

}

#############################################################
# Obtener Hits
#############################################################

db_get_hits(){

    local IP="$1"

    db_exec "

        SELECT hits

        FROM hosts

        WHERE ip='$IP';

    "

}

#############################################################
# Incrementar Hits
#############################################################

db_increment_hits(){

    local IP="$1"

    local NOW

    NOW=$(date +%s)

    db_exec "

        UPDATE hosts

        SET

            hits=hits+1,

            last_seen=$NOW

        WHERE ip='$IP';

    "

}

#############################################################
# Registrar Evento
#############################################################

db_add_event(){

    local IP="$1"

    local ACTION="$2"

    local JAIL="$3"

    local TIMEOUT="$4"

    local NOW

    NOW=$(date +%s)

    db_exec "

        INSERT INTO events(

            fecha,

            ip,

            action,

            jail,

            timeout

        )

        VALUES(

            $NOW,

            '$IP',

            '$ACTION',

            '$JAIL',

            '$TIMEOUT'

        );

    "

}
