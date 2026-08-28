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
        sqlite3 -batch -cmd ".timeout 3000" "$DB_FILE" "$SQL" 2>/dev/null
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
      ('telnet','CREDENTIAL',15,0.98,0.97,'Telnet authentication attacks'),
      ('web-correlation','BOT',8,0.88,0.95,'Scraping distribuido de catalogo/carrito, correlacion multi-IP');
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

    #############################################################
    # RFC-017: Registro de sensores, activar/desactivar
    #############################################################

    db_exec "
    CREATE TABLE IF NOT EXISTS sensor_registry(
        name TEXT PRIMARY KEY,
        pattern TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        systemd_timer TEXT,
        description TEXT
    );
    "

    db_exec "
    INSERT OR IGNORE INTO sensor_registry(name, pattern, enabled, systemd_timer, description)
    VALUES
    ('fail2ban','polling',1,'are-fail2ban-found.timer','Sensor Fail2Ban, offset persistente, filtro dinámico contra jail_profile'),
    ('spamassassin','polling',1,'are-spamassassin.timer','Sensor SpamAssassin, categoría SOCIAL, 3 bandas por score'),
    ('apache_evasive','callback',1,NULL,'Sensor Apache/mod_evasive, invocado por DOSSystemCommand, sin timer systemd'),
    ('web-correlation','polling',1,'are-web-correlation.timer','Sensor de correlación web, scraping distribuido de catálogo/carrito, categoría BOT');
    "

    # RFC-008: reputation_scores es el almacenamiento real del score
    # por categoría desde v2.1 — faltaba en toda instalación nueva,
    # solo se creaba como parte de la migración v2.0->v2.1
    # (db_migrate_reputation_scores), que una instalación nueva sin
    # datos previos nunca ejecuta.
    db_init_reputation_scores
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

    db_exec "INSERT OR IGNORE INTO reputation (ip, updated) VALUES ('$IP', $NOW);"

    db_exec "
        INSERT INTO reputation_scores (ip, category, score)
        VALUES ('$IP', '$CATEGORY', $SCORE)
        ON CONFLICT(ip, category) DO UPDATE SET score = score + $SCORE;
    "

    db_exec "UPDATE reputation SET updated=$NOW WHERE ip='$IP';"
}

#############################################################
# Recalcular score total
#############################################################

db_recalculate_total() {

    # RFC-008 Fase 4: total_score ya no existe como columna
    # almacenada — se deriva siempre al vuelo en db_get_score() y
    # en el resto de las funciones de estadísticas. Esta función se
    # conserva vacía (no-op) para no tener que modificar cada punto
    # de are.sh que la invoca después de cada evento.
    return 0
}

#############################################################
# Obtener score total
#############################################################

db_get_score() {

    local IP="$1"

    db_exec "
        SELECT COALESCE(SUM(score),0)
        FROM reputation_scores
        WHERE ip='$IP';
    "
}

db_get_reputation() {
    local IP="$1"
    db_exec "
        SELECT
            COALESCE(MAX(CASE WHEN category='RECON' THEN score END), 0) || '|' ||
            COALESCE(MAX(CASE WHEN category='EXPLOIT' THEN score END), 0) || '|' ||
            COALESCE(MAX(CASE WHEN category='CREDENTIAL' THEN score END), 0) || '|' ||
            COALESCE(MAX(CASE WHEN category='PROTOCOL' THEN score END), 0) || '|' ||
            COALESCE(MAX(CASE WHEN category='BOT' THEN score END), 0) || '|' ||
            COALESCE(MAX(CASE WHEN category='ANOMALY' THEN score END), 0) || '|' ||
            COALESCE(MAX(CASE WHEN category='MALWARE' THEN score END), 0) || '|' ||
            COALESCE(MAX(CASE WHEN category='DOS' THEN score END), 0) || '|' ||
            COALESCE(MAX(CASE WHEN category='SOCIAL' THEN score END), 0) || '|' ||
            (SELECT COALESCE(SUM(score),0) FROM reputation_scores WHERE ip='$IP') || '|' ||
            COALESCE((SELECT updated FROM reputation WHERE ip='$IP'), 0)
        FROM reputation_scores
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

#IPs con actividad (score total > 0)
db_count_active_ips() {
    db_exec "
        SELECT COUNT(DISTINCT ip)
        FROM reputation_scores
        WHERE score > 0;
    "
}

#IPs baneadas (score alto)
db_count_banned_ips() {
    db_exec "
        SELECT COUNT(*)
        FROM (
            SELECT ip, SUM(score) AS total
            FROM reputation_scores
            GROUP BY ip
            HAVING total >= 60
        );
    "
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

#score promedio global (incluye IPs sin actividad, como el score 0)
db_avg_score() {
    db_exec "
        SELECT AVG(t.total)
        FROM (
            SELECT r.ip, COALESCE(SUM(rs.score), 0) AS total
            FROM reputation r
            LEFT JOIN reputation_scores rs ON rs.ip = r.ip
            GROUP BY r.ip
        ) t;
    "
}

#breakdown por categoría
db_sum_categories() {
    db_exec "
        SELECT
            COALESCE(SUM(CASE WHEN category='RECON' THEN score ELSE 0 END),0) || '|' ||
            COALESCE(SUM(CASE WHEN category='EXPLOIT' THEN score ELSE 0 END),0) || '|' ||
            COALESCE(SUM(CASE WHEN category='CREDENTIAL' THEN score ELSE 0 END),0) || '|' ||
            COALESCE(SUM(CASE WHEN category='PROTOCOL' THEN score ELSE 0 END),0) || '|' ||
            COALESCE(SUM(CASE WHEN category='BOT' THEN score ELSE 0 END),0) || '|' ||
            COALESCE(SUM(CASE WHEN category='ANOMALY' THEN score ELSE 0 END),0) || '|' ||
            COALESCE(SUM(CASE WHEN category='MALWARE' THEN score ELSE 0 END),0) || '|' ||
            COALESCE(SUM(CASE WHEN category='DOS' THEN score ELSE 0 END),0) || '|' ||
            COALESCE(SUM(CASE WHEN category='SOCIAL' THEN score ELSE 0 END),0)
        FROM reputation_scores;
    "
}

#TOP ATTACKERS
db_top_attackers() {
    db_exec "
        SELECT
            r.ip,
            COALESCE((SELECT SUM(score) FROM reputation_scores WHERE ip = r.ip), 0) AS total,
            COALESCE(MAX(CASE WHEN rs.category='RECON' THEN rs.score END), 0),
            COALESCE(MAX(CASE WHEN rs.category='EXPLOIT' THEN rs.score END), 0),
            COALESCE(MAX(CASE WHEN rs.category='CREDENTIAL' THEN rs.score END), 0),
            COALESCE(MAX(CASE WHEN rs.category='PROTOCOL' THEN rs.score END), 0),
            COALESCE(MAX(CASE WHEN rs.category='BOT' THEN rs.score END), 0),
            COALESCE(MAX(CASE WHEN rs.category='ANOMALY' THEN rs.score END), 0),
            COALESCE(MAX(CASE WHEN rs.category='MALWARE' THEN rs.score END), 0),
            COALESCE(MAX(CASE WHEN rs.category='DOS' THEN rs.score END), 0),
            COALESCE(MAX(CASE WHEN rs.category='SOCIAL' THEN rs.score END), 0)
        FROM reputation r
        LEFT JOIN reputation_scores rs ON rs.ip = r.ip
        GROUP BY r.ip
        ORDER BY total DESC
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
        FROM reputation r
        WHERE (SELECT COALESCE(SUM(score),0) FROM reputation_scores WHERE ip = r.ip) > 0
          AND r.updated IS NOT NULL
          AND ($NOW - r.updated) >= $MIN_AGE;
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

#############################################################
# RFC-017: Registro de sensores, activar/desactivar
#############################################################

#############################################################
# Listar todos los sensores registrados
#############################################################

db_list_sensor_registry() {

    db_exec "
        SELECT
            name || '|' ||
            pattern || '|' ||
            enabled || '|' ||
            COALESCE(systemd_timer, '') || '|' ||
            COALESCE(description, '')
        FROM sensor_registry
        ORDER BY name;
    "
}

#############################################################
# Obtener un sensor puntual
#############################################################

db_get_sensor() {

    local NAME="$1"

    db_exec "
        SELECT
            pattern || '|' ||
            enabled || '|' ||
            COALESCE(systemd_timer, '') || '|' ||
            COALESCE(description, '')
        FROM sensor_registry
        WHERE name='$NAME';
    "
}

#############################################################
# ¿Existe este sensor en el registro?
#############################################################

db_sensor_exists() {

    local NAME="$1"

    local RESULT
    RESULT=$(db_exec "SELECT COUNT(*) FROM sensor_registry WHERE name='$NAME';")

    [ "$RESULT" -gt 0 ]
}

#############################################################
# Activar / desactivar un sensor
#############################################################

db_set_sensor_enabled() {

    local NAME="$1"
    local ENABLED="$2"

    db_exec "
        UPDATE sensor_registry
        SET enabled = $ENABLED
        WHERE name = '$NAME';
    "
}
