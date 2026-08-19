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
        sqlite3 -batch "$DB_FILE" "$SQL" 2>/dev/null
    )

    local RC=$?

    if [ "$RC" -ne 0 ]
    then

        db_error "$RC" "$RESULT"

        return "$RC"

    fi

    echo "$RESULT" >&1

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
    "$DB_FILE" 2>&1 <<EOF
BEGIN IMMEDIATE;
${SQL}
COMMIT;
EOF
)

    local RC=$?

    if [ "$RC" -ne 0 ]; then

        sqlite3 "$DB_FILE" "ROLLBACK;" >/dev/null 2>&1

        db_error "$RC" "$RESULT"

        return "$RC"

    fi

    echo "$RESULT" >&1

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
        hits INTEGER DEFAULT 0,
        status TEXT DEFAULT 'FREE'
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

    db_exec "
    CREATE TABLE IF NOT EXISTS reputation(
    	ip TEXT PRIMARY KEY,
    	recon_score INTEGER DEFAULT 0,
    	exploit_score INTEGER DEFAULT 0,
    	credential_score INTEGER DEFAULT 0,
    	protocol_score INTEGER DEFAULT 0,
    	bot_score INTEGER DEFAULT 0,
	anomaly_score INTEGER DEFAULT 0,
	malware_score INTEGER DEFAULT 0,
	dos_score INTEGER DEFAULT 0,
	social_score INTEGER DEFAULT 0,
	last_decay INTEGER DEFAULT 0,
    	total_score INTEGER DEFAULT 0,
	status TEXT NOT NULL DEFAULT 'NEW',
    	updated INTEGER
    );
    "

    db_exec "
    CREATE TABLE IF NOT EXISTS jail_profile(
    	name TEXT PRIMARY KEY,
    	category TEXT,
    	weight REAL,
    	confidence REAL,
    	decay REAL,
    	description TEXT
    );
    "

    db_exec "
    INSERT OR IGNORE INTO jail_profile(name, category, weight, confidence, decay, description)
    VALUES
    ('recidive','EXPLOIT',25,0.99,0.99,'Persistent Abusers'),
    ('modsec-rce','EXPLOIT',25,0.99,0.99,'Remote Code Execution'),
    ('modsec-sqli','EXPLOIT',12,0.98,0.98,'SQL Injection'),
    ('modsec-lfi','EXPLOIT',8,0.95,0.97,'Local File Inclusion'),
    ('modsec-bots','RECON',3,0.60,0.95,'Reconnaissance / Scanning'),
    ('modsec-scanner','RECON',4,0.75,0.95,'Automated scanning activity'),
    ('modsec-protocol','PROTOCOL',1,0.50,0.90,'Protocol violation'),
    ('modsec-anomaly','ANOMALY',2,0.60,0.85,'Generic ModSecurity anomaly / heuristic trigger'),
    ('modsecurity-apache','ANOMALY',1,0.50,0.80,'Generic ModSecurity Apache rules triggered'),
    ('modsec-bruteforce','CREDENTIAL',10,0.90,0.97,'Brute force login'),
      ('sshd','CREDENTIAL',10,0.95,0.97,'SSH authentication attacks'),
      ('telnet','CREDENTIAL',15,0.98,0.97,'Telnet authentication attacks');
    "

    db_exec "
    CREATE TABLE IF NOT EXISTS sanction_state(
        ip TEXT PRIMARY KEY,
        ban_level INTEGER DEFAULT 0,
        ban_count INTEGER DEFAULT 0,
        ban_until INTEGER DEFAULT 0,
        permanent INTEGER DEFAULT 0,
        last_ban INTEGER DEFAULT 0,
        last_unban INTEGER DEFAULT 0,
        updated INTEGER
    );
    "
}

#############################################################
# Información de la Base
############################################################

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

#############################################################
# Obtener perfil de un jail
#############################################################

db_get_jail_profile() {

    local JAIL="$1"

    db_exec "
        SELECT weight || '|' || confidence || '|' || category
        FROM jail_profile
        WHERE name='$JAIL';
    "
}

#############################################################
# Inicializar reputación de IP
#############################################################

db_init_reputation() {

    local IP="$1"

    db_exec "
        INSERT OR IGNORE INTO reputation(ip, updated)
        VALUES('$IP', strftime('%s','now'));
    "
}

#############################################################
# Aplicar score a reputación
#############################################################

db_add_score() {

    local IP="$1"
    local CATEGORY="$2"
    local SCORE="$3"

    local NOW
    NOW=$(date +%s)

    case "$CATEGORY" in

        RECON)
            db_exec "UPDATE reputation SET recon_score = recon_score + $SCORE, updated=$NOW WHERE ip='$IP';"
        ;;

        EXPLOIT)
            db_exec "UPDATE reputation SET exploit_score = exploit_score + $SCORE, updated=$NOW WHERE ip='$IP';"
        ;;

        CREDENTIAL)
            db_exec "UPDATE reputation SET credential_score = credential_score + $SCORE, updated=$NOW WHERE ip='$IP';"
        ;;

        PROTOCOL)
            db_exec "UPDATE reputation SET protocol_score = protocol_score + $SCORE, updated=$NOW WHERE ip='$IP';"
        ;;

        BOT)
            db_exec "UPDATE reputation SET bot_score = bot_score + $SCORE, updated=$NOW WHERE ip='$IP';"
        ;;
        ANOMALY)
            db_exec "UPDATE reputation SET anomaly_score = anomaly_score + $SCORE, updated=$NOW WHERE ip='$IP';"
        ;;
	MALWARE)
            db_exec "UPDATE reputation SET malware_score = malware_score + $SCORE, updated=$NOW WHERE ip='$IP';"
        ;;
	DOS)
            db_exec "UPDATE reputation SET dos_score = dos_score + $SCORE, updated=$NOW WHERE ip='$IP';"
        ;;
	SOCIAL)
            db_exec "UPDATE reputation SET social_score = social_score + $SCORE, updated=$NOW WHERE ip='$IP';"
        ;;

    esac
}

#############################################################
# Recalcular score total
#############################################################

db_recalculate_total() {
	db_exec "
    UPDATE reputation
    SET total_score =
        recon_score +
        exploit_score +
        credential_score +
        protocol_score +
        bot_score +
	anomaly_score +
	malware_score +
	dos_score +
	social_score
    WHERE ip='$IP';
"


}

#############################################################
# Obtener score total
#############################################################

db_get_score() {

    local IP="$1"

    db_exec "
        SELECT total_score
        FROM reputation
        WHERE ip='$IP';
    "
}

db_get_reputation() {

    local IP="$1"

    db_exec "
        SELECT
            recon_score || '|' ||
            exploit_score || '|' ||
            credential_score || '|' ||
            protocol_score || '|' ||
            bot_score || '|' ||
	    anomaly_score || '|' ||
	    malware_score || '|' ||
    	    dos_score || '|' ||
	    social_score || '|' ||
            total_score || '|' ||
            updated
        FROM reputation
        WHERE ip='$IP';
    "
}

db_get_last_event() {

    local IP="$1"

    db_exec "
        SELECT action || ' @ ' || datetime(fecha, 'unixepoch')
        FROM events
        WHERE ip='$IP'
        ORDER BY fecha DESC
        LIMIT 1;
    "
}

db_get_events() {

    local IP="$1"

    db_exec "
        SELECT
            datetime(fecha, 'unixepoch') || ' | ' ||
            action || ' | ' ||
            jail
        FROM events
        WHERE ip='$IP'
        ORDER BY fecha DESC
        LIMIT 10;
    "
}

db_get_status() {

    local IP="$1"

    db_exec "
        SELECT status
        FROM reputation
        WHERE ip='$IP';
    "
}

db_set_status() {

    local IP="$1"
    local STATUS="$2"

    db_exec "
        UPDATE reputation
        SET status='$STATUS'
        WHERE ip='$IP';
    "
}

db_status_exists() {

    local IP="$1"

    db_exec "
        SELECT COUNT(*)
        FROM reputation
        WHERE ip='$IP';
    "
}

#IPs totales
db_count_ips() {
    db_exec "SELECT COUNT(*) FROM reputation;"
}

#IPs con actividad (total_score > 0)
db_count_active_ips() {
    db_exec "SELECT COUNT(*) FROM reputation WHERE total_score > 0;"
}

#IPs baneadas (score alto)
db_count_banned_ips() {
    db_exec "SELECT COUNT(*) FROM reputation WHERE total_score >= 60;"
}

#total de eventos
db_count_events() {
    db_exec "SELECT COUNT(*) FROM events;"
}

#Eventos de hoy
db_count_events_today() {
    db_exec "
        SELECT COUNT(*)
        FROM events
        WHERE date(fecha, 'unixepoch') = date('now');
    "
}

#score promedio global
db_avg_score() {
    db_exec "SELECT AVG(total_score) FROM reputation;"
}

#breakdown por categoría
db_sum_categories() {
    db_exec "
        SELECT
            COALESCE(SUM(recon_score),0) || '|' ||
            COALESCE(SUM(exploit_score),0) || '|' ||
            COALESCE(SUM(credential_score),0) || '|' ||
            COALESCE(SUM(protocol_score),0) || '|' ||
            COALESCE(SUM(bot_score),0) || '|' ||
	    COALESCE(SUM(anomaly_score),0) || '|' ||
	    COALESCE(SUM(malware_score),0) || '|' ||
	    COALESCE(SUM(dos_score),0) || '|' ||
            COALESCE(SUM(social_score),0)
        FROM reputation;
    "
}

#TOP ATTACKERS
db_top_attackers() {
    db_exec "
        SELECT
            ip,
            total_score,
            recon_score,
            exploit_score,
            credential_score,
            protocol_score,
	    bot_score,
	    anomaly_score,
	    malware_score,
	    dos_score,
            social_score
        FROM reputation
        ORDER BY total_score DESC
        LIMIT 10;
    "
}

db_top_jails() {
    db_exec "
        SELECT jail || '|' || COUNT(*)
        FROM events
        WHERE jail IS NOT NULL
          AND jail != ''
          AND jail NOT IN ('fail2ban', 'policy_apply')
        GROUP BY jail
        ORDER BY COUNT(*) DESC
        LIMIT 5;
    "
}

db_count_decay_candidates() {

    local NOW
    local MIN_AGE="${DECAY_MIN_AGE:-86400}"

    NOW=$(date +%s)

    db_exec "
        SELECT COUNT(*)
        FROM reputation
        WHERE total_score > 0
          AND updated IS NOT NULL
          AND ($NOW - updated) >= $MIN_AGE;
    "
}

#############################################################
# SANCTION STATE
#############################################################

db_init_sanction() {

    local IP="$1"
    local NOW
    NOW=$(date +%s)

    db_exec "
        INSERT OR IGNORE INTO sanction_state(
            ip,
            ban_level,
            ban_count,
            ban_until,
            permanent,
            last_ban,
            last_unban,
            updated
        )
        VALUES(
            '$IP',
            0,
            0,
            0,
            0,
            0,
            0,
            $NOW
        );
    "
}

db_get_sanction() {

    local IP="$1"

    db_exec "
        SELECT
            ban_level || '|' ||
            ban_count || '|' ||
            ban_until || '|' ||
            permanent || '|' ||
            last_ban || '|' ||
            last_unban || '|' ||
            updated
        FROM sanction_state
        WHERE ip='$IP';
    "
}

db_get_ban_level() {

    local IP="$1"

    db_exec "
        SELECT COALESCE(ban_level,0)
        FROM sanction_state
        WHERE ip='$IP';
    "
}

db_set_ban_until() {

    local IP="$1"
    local BAN_UNTIL="$2"
    local NOW
    NOW=$(date +%s)

    db_init_sanction "$IP"

    db_exec "
        UPDATE sanction_state
        SET
            ban_until = $BAN_UNTIL,
            updated = $NOW
        WHERE ip='$IP';
    "
}

db_set_permanent() {

    local IP="$1"
    local VALUE="${2:-1}"
    local NOW
    NOW=$(date +%s)

    db_init_sanction "$IP"

    db_exec "
        UPDATE sanction_state
        SET
            permanent = $VALUE,
            updated = $NOW
        WHERE ip='$IP';
    "
}

db_is_permanent() {

    local IP="$1"

    db_exec "
        SELECT COALESCE(permanent,0)
        FROM sanction_state
        WHERE ip='$IP';
    "
}

db_register_sanction_unban() {

    local IP="$1"
    local NOW
    NOW=$(date +%s)

    db_init_sanction "$IP"

    db_exec "
        UPDATE sanction_state
        SET
            ban_until = 0,
            last_unban = $NOW,
            updated = $NOW
        WHERE ip='$IP';
    "
}

db_increment_ban_level() {

    local IP="$1"
    local MAX_LEVEL="${2:-7}"
    local NOW

    NOW=$(date +%s)

    db_init_sanction "$IP"

    db_exec "
        UPDATE sanction_state
        SET
            ban_level = CASE
                WHEN ban_level < $MAX_LEVEL
                THEN ban_level + 1
                ELSE $MAX_LEVEL
            END,
            ban_count = ban_count + 1,
            last_ban = $NOW,
            updated = $NOW
        WHERE ip='$IP';
    "
}

#############################################################
# Listar todos los perfiles de jail
#############################################################

db_list_jail_profiles() {

    db_exec "
        SELECT
            name || '|' ||
            category || '|' ||
            weight || '|' ||
            confidence || '|' ||
            decay || '|' ||
            COALESCE(description, '')
        FROM jail_profile
        ORDER BY category, name;
    "
}

#############################################################
# ¿Existe un perfil para este jail?
#############################################################

db_jail_profile_exists() {

    local NAME="$1"

    local RESULT
    RESULT=$(db_exec "SELECT COUNT(*) FROM jail_profile WHERE name='$NAME';")

    [ "$RESULT" -gt 0 ]
}

#############################################################
# Crear perfil de jail
#############################################################

db_create_jail_profile() {

    local NAME="$1"
    local CATEGORY="$2"
    local WEIGHT="$3"
    local CONFIDENCE="$4"
    local DECAY="$5"
    local DESCRIPTION="$6"

    db_exec "
        INSERT INTO jail_profile(name, category, weight, confidence, decay, description)
        VALUES('$NAME', '$CATEGORY', $WEIGHT, $CONFIDENCE, $DECAY, '$DESCRIPTION');
    "
}

#############################################################
# Estadísticas de peso por categoría (referencia para admin)
#############################################################

db_category_weight_stats() {

    local CATEGORY="$1"

    db_exec "
        SELECT
            COALESCE(MIN(weight), 0) || '|' ||
            COALESCE(MAX(weight), 0) || '|' ||
            COALESCE(ROUND(AVG(weight), 1), 0) || '|' ||
            COUNT(*)
        FROM jail_profile
        WHERE category='$CATEGORY';
    "
}

#############################################################
# Modificar perfil de jail existente
#############################################################

db_update_jail_profile() {

    local NAME="$1"
    local CATEGORY="$2"
    local WEIGHT="$3"
    local CONFIDENCE="$4"
    local DECAY="$5"
    local DESCRIPTION="$6"

    db_exec "
        UPDATE jail_profile
        SET
            category = '$CATEGORY',
            weight = $WEIGHT,
            confidence = $CONFIDENCE,
            decay = $DECAY,
            description = '$DESCRIPTION'
        WHERE name = '$NAME';
    "
}

#############################################################
# Obtener perfil completo de un jail (para edición)
#############################################################

db_get_jail_profile_full() {

    local NAME="$1"

    db_exec "
        SELECT category || '|' || weight || '|' || confidence || '|' || decay || '|' || COALESCE(description, '')
        FROM jail_profile
        WHERE name='$NAME';
    "
}

#############################################################
# Eliminar perfil de jail
#############################################################

db_delete_jail_profile() {

    local NAME="$1"

    db_exec "
        DELETE FROM jail_profile
        WHERE name = '$NAME';
    "
}

#############################################################
# Validar perfiles de jail (categorías inválidas, rangos fuera de límite)
#############################################################

db_validate_jail_profiles() {

    db_exec "
        SELECT
            name || '|' || category || '|' || weight || '|' || confidence
        FROM jail_profile;
    "
}

#############################################################
# RFC-008: Modelo de categorías extensible
# Fase 1 — Crear reputation_scores (normalizada) sin tocar
# la tabla reputation existente.
#############################################################

db_init_reputation_scores() {

    db_exec "
        CREATE TABLE IF NOT EXISTS reputation_scores(
            ip TEXT NOT NULL,
            category TEXT NOT NULL,
            score INTEGER DEFAULT 0,
            PRIMARY KEY (ip, category)
        );
    "
}

#############################################################
# Migrar datos de reputation (columnas) a reputation_scores
# (filas). Aditivo: no borra ni modifica la tabla reputation.
# Idempotente: usa INSERT OR REPLACE, se puede correr de nuevo
# sin duplicar si algo falla a mitad de camino.
#############################################################

db_migrate_reputation_scores() {

    db_init_reputation_scores

    local categories="RECON EXPLOIT CREDENTIAL PROTOCOL BOT ANOMALY MALWARE DOS SOCIAL"
    local columns="recon_score exploit_score credential_score protocol_score bot_score anomaly_score malware_score dos_score social_score"

    local cat_arr=($categories)
    local col_arr=($columns)

    local i
    for i in "${!cat_arr[@]}"; do
        local cat="${cat_arr[$i]}"
        local col="${col_arr[$i]}"

        db_exec "
            INSERT OR REPLACE INTO reputation_scores (ip, category, score)
            SELECT ip, '$cat', $col
            FROM reputation
            WHERE $col > 0;
        "
    done
}

#############################################################
# Verificar que la migración fue exacta: compara, IP por IP,
# la suma de reputation_scores contra total_score de la tabla
# vieja. Devuelve las filas con discrepancia (vacío = OK).
#############################################################

db_verify_reputation_scores_migration() {

    db_exec "
        SELECT
            r.ip,
            r.total_score AS total_viejo,
            COALESCE(SUM(rs.score), 0) AS total_nuevo
        FROM reputation r
        LEFT JOIN reputation_scores rs ON rs.ip = r.ip
        GROUP BY r.ip
        HAVING total_viejo != total_nuevo;
    "
}

#############################################################
# BUG-018: Fusionar IPs duplicadas por coma sin limpiar
# (bug histórico en sensors/fail2ban.sh, rama Unban).
#
# Para cada IP que tenga una versión limpia y una versión con
# coma en reputation, suma los scores por categoría, recalcula
# total_score, mueve los eventos, y elimina la fila sucia.
#############################################################

db_merge_comma_duplicates() {

    local categories="recon_score exploit_score credential_score protocol_score bot_score anomaly_score malware_score dos_score social_score"

    local pairs
    pairs=$(db_exec "
        SELECT r1.ip
        FROM reputation r1
        JOIN reputation r2 ON r2.ip = r1.ip || ',';
    ")

    if [ -z "$pairs" ]; then
        INFO "No hay pares de IPs duplicadas por coma para fusionar."
        return 0
    fi

    local count=0

    echo "$pairs" | while IFS= read -r clean_ip; do
        [ -z "$clean_ip" ] && continue
        local dirty_ip="${clean_ip},"

        local set_clause=""
        local col
        for col in $categories; do
            if [ -n "$set_clause" ]; then
                set_clause="${set_clause}, "
            fi
            set_clause="${set_clause}${col} = ${col} + (SELECT ${col} FROM reputation WHERE ip = '${dirty_ip}')"
        done

        db_exec "UPDATE reputation SET ${set_clause} WHERE ip = '${clean_ip}';"

        local sum_expr
        sum_expr=$(echo "$categories" | tr ' ' '+')
        db_exec "UPDATE reputation SET total_score = ${sum_expr} WHERE ip = '${clean_ip}';"

        db_exec "UPDATE events SET ip = '${clean_ip}' WHERE ip = '${dirty_ip}';"

        db_exec "DELETE FROM reputation WHERE ip = '${dirty_ip}';"

        state_update "$clean_ip"

        INFO "[MERGE] Fusionado: $dirty_ip -> $clean_ip"
    done

    INFO "Fusión de IPs duplicadas completada."
}
