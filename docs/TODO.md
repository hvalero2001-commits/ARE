# ARE TODO

Este documento mantiene el registro de trabajo activo del proyecto.

Se divide en:

- Bugs
- Tasks
- Features
- RFC
- Ideas

---

# BUGS

## BUG-001

**Título:** Implementar `handle_unban()`

**Estado:** ✔ Resuelto

**Versión:** v1.0.1

---

## BUG-002

**Título:** Verificar sincronización Backend ↔ Fail2Ban

**Estado:** En observación

**Prioridad:** Media

**Descripción**

Continuar validando durante operación en producción que todas las acciones generadas por Fail2Ban sean procesadas correctamente por ARE.

---

## BUG-005

**Título:** Inicialización duplicada del backend

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Descripción**

Se eliminó la doble inicialización de IPSet y Firewall centralizando el proceso en `backend/init.sh`.

---

## BUG-006

**Título:** La categoría ANOMALY no se refleja en las estadísticas

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Prioridad:** Media

**Descripción**

La categoría ANOMALY ya es utilizada por el Policy Engine y los perfiles de jail, pero actualmente no existe dentro del modelo de reputación persistente (`reputation`).

Como consecuencia, el Dashboard no puede mostrar estadísticas correctas de dicha categoría.

**Impacto**

- Dashboard incompleto.
- Estadísticas inconsistentes.
- Categorías del motor y del Dashboard no coinciden.

**Validación**

- `stats` muestra `Anomaly`.
- `score <ip>` muestra `Anomaly`.
- `FOUND modsec-anomaly` suma correctamente al total.

---

## BUG-007

## BUG-007

**Título:** ARE no procesa correctamente eventos BAN/UNBAN provenientes de Fail2Ban

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Prioridad:** Alta

**Descripción**

Se detectó que ARE procesa correctamente eventos `FOUND` mediante el sensor Fail2Ban, pero algunos eventos `BAN` y `UNBAN` generados por Fail2Ban no quedan registrados en el historial de ARE.

**Evidencia**

Fail2Ban registra eventos `Unban`, pero al consultar `events <IP>` no aparece información asociada en ARE.

**Impacto**

- El ciclo completo `FOUND → BAN → UNBAN` puede quedar incompleto.
- El historial de reputación puede no reflejar correctamente la actividad real.
- ARE depende parcialmente de que la acción directa de Fail2Ban ejecute correctamente `ban/unban`.

**Hipótesis inicial**

Actualmente existe un sensor para eventos `FOUND`, pero no existe un sensor equivalente para eventos `BAN` y `UNBAN` leídos desde el log de Fail2Ban.

**Archivos relacionados**

- `sensors/fail2ban_found.sh`
- `/etc/fail2ban/action.d/ipset-smart.conf`
- `f2b-ipset.sh`
- `database.sh`

**Validación**

- El sensor Fail2Ban unificado procesa eventos `FOUND`.
- El sensor Fail2Ban unificado procesa eventos `UNBAN`.
- Los eventos `UNBAN` externos se registran como `EXTERNAL_UNBAN`.
- `EXTERNAL_UNBAN` no libera directamente la IP.
- ARE reevalúa la IP mediante el Policy Engine.
- Validado en producción con IP `103.59.161.151`

---

# TASKS

## TASK-001

**Título:** Reorganizar reglas del Policy Engine

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Descripción**

Las reglas fueron movidas al módulo:

```
policy/rules/
```

---

## TASK-002

**Título:** Cursor persistente para sensores

**Estado:** OPEN

**Prioridad:** Alta

**Descripción**

Implementar un mecanismo persistente de offset para evitar reprocesar eventos ya leídos desde los logs.

---

## TASK-003

**Título:** Automatizar ejecución del Fail2Ban Sensor

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Descripción**

Se creó un `systemd service` y un `systemd timer` para ejecutar automáticamente el sensor Fail2Ban FOUND cada minuto.

---

## TASK-004

**Título:** Agregar estadísticas por jail

**Estado:** OPEN

**Versión:** v1.1-dev

**Descripción**

Evaluar una sección adicional en `stats` para mostrar actividad por jail, por ejemplo:

- recidive
- sshd
- modsec-rce
- modsec-protocol
- modsec-bruteforce

Esto debe calcularse desde la tabla `events`, no desde `reputation`

---

## TASK-005

**Título:** Ampliar categorías del Reputation Engine

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Prioridad:** Alta

**Objetivo**

Expandir el modelo de reputación para soportar categorías adicionales de amenazas.

**Categorías objetivo**

- ANOMALY
- MALWARE
- DOS
- SOCIAL

**Alcance inicial**

Implementar primero `ANOMALY` de punta a punta:

- Base de datos.
- `database.sh`.
- `dashboard/stats.sh`.
- `dashboard/score.sh`.

**Validación**

- Nuevas columnas agregadas a `reputation`.
- `ANOMALY`, `MALWARE`, `DOS` y `SOCIAL` integradas al modelo.
- `stats` muestra todas las categorías.
- `score <ip>` muestra todas las categorías.
- `total_score` incluye todas las categorías.

**Nota**

Los jails seguirán mapeándose mediante `jail_profile` hacia una categoría de reputación. No se crearán columnas específicas por jail.

---

# FEATURES

## FEAT-001

**Estado:** ✔ Operativo en producción

**Implementado**

- Evento FOUND.
- Sensor Fail2Ban.
- Cursor persistente.
- Modo `--dry-run`.
- Modo `--execute`.
- Ejecución automática mediante systemd timer.
- Registro en SQLite.
- Integración con Policy Engine.
- Validación en producción.

**Pendiente**

- Limpieza final del sensor.
- Mover configuración fija a `config.conf`.

---

## FEAT-003

## FEAT-003

**Título:** Mostrar TOP JAILS en `stats`

**Estado:** ✔ Resuelto

**Versión:** v1.1-dev

**Validación**

- `stats` muestra TOP JAILS.
- Se excluyen eventos internos como `fail2ban` y `policy_apply`.
- La información se obtiene desde la tabla `events`.

**Prioridad:** Media

**Objetivo**

Mostrar en el dashboard estadístico cuáles jails generan mayor actividad.

**Fuente de datos**

Tabla `events`.

**Salida esperada**

```text
TOP JAILS:
modsec-protocol ........ 132
modsec-bruteforce ...... 78
modsec-rce ............. 34
sshd ................... 15
recidive ............... 6
```

---

# RFC

## RFC-001

**Título:** Renombrar CLI oficial a `are`

**Estado:** Draft

**Versión objetivo:** v1.1

---

## RFC-002

**Título:** Sensor Framework

**Estado:** Accepted

**Versión objetivo:** v1.1

**Descripción**

ARE incorpora una capa de sensores encargada de transformar eventos externos en eventos internos procesables por el motor de reputación.

El primer sensor implementado corresponde a Fail2Ban para el procesamiento de eventos FOUND.

---

## RFC-003

**Título:** Identity Migration

**Estado:** Draft

**Versión objetivo:** v1.1

**Descripción**

Completar la transición desde la identidad histórica `f2b-ipset` hacia el nombre oficial del proyecto: **ARE (Abuse Reputation Engine)**.

**Objetivo**

Alinear nombres de comandos, rutas, servicios, configuración y documentación con la identidad oficial del proyecto.

**Alcance inicial**

- Crear CLI oficial `are`.
- Mantener compatibilidad temporal con `f2b-ipset.sh`.
- Evaluar migración futura de `/opt/f2b-ipset/` hacia `/opt/are/`.
- Evaluar migración futura de configuración hacia `/etc/are/`.
- Evaluar migración futura de base de datos hacia rutas ARE.
- Actualizar documentación afectada.

**Nota**

Esta migración debe realizarse de forma gradual para no romper instalaciones existentes.

**Estado:** ✔ Validado en producción

**Implementado**

- Evento FOUND.
- Procesamiento desde Sensor Fail2Ban.
- Cursor persistente.
- Modo `--dry-run`.
- Modo `--execute`.
- Registro en SQLite.
- Integración con Policy Engine.
- Pruebas manuales y producción real satisfactorias.

**Pendiente**

- Ejecución continua.
- Limpieza final del sensor.
- Definir política de ejecución automática.

---

## RFC-004

**Título:** ARE como autoridad principal de decisión

**Estado:** Draft

**Versión objetivo:** v1.1

**Descripción**

Evaluar la transición del modelo actual, donde Fail2Ban ejecuta decisiones de `BAN` y `UNBAN`, hacia un modelo donde Fail2Ban actúa únicamente como fuente de eventos y ARE asume la autoridad principal sobre las decisiones de bloqueo, filtrado, liberación y escalado.

**Objetivo**

Permitir que ARE decida la respuesta final según reputación, score, historial, reincidencia y estado de la IP, evitando que un `UNBAN` externo contradiga una decisión tomada por el Policy Engine.

**Impacto esperado**

- Mayor autonomía de ARE.
- Mejor coherencia entre reputación y firewall.
- Control centralizado del ciclo de vida de una IP.
- Fail2Ban pasa a actuar como sensor, no como autoridad de decisión.

**Puntos a definir**

- Cómo tratar eventos `BAN` de Fail2Ban.
- Cómo tratar eventos `UNBAN` de Fail2Ban.
- Cuándo ARE debe liberar una IP.
- Cómo calcular escalado por reincidencia.
- Tiempo máximo de bloqueo temporal.
- Condiciones para bloqueo permanente.

**Validación inicial**

Se implementó y validó manualmente el comando:

```bash
./f2b-ipset.sh external-unban <IP> <JAIL>
```

---

# IDEAS

## IDEA-001

Exportación de métricas.

---

## IDEA-002

API REST.

---

## IDEA-003

Backend Manager.

---

## IDEA-004

Reputation Decay Engine.

---

## IDEA-005

Dashboard avanzado.

---

# OBSERVACIONES

La rama **v1.1-dev** se utiliza para el desarrollo activo de nuevas funcionalidades.

Las versiones **1.0.x** permanecen destinadas exclusivamente a mantenimiento y corrección de errores.
