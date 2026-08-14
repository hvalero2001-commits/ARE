# ARE TODO

Este documento mantiene el registro de trabajo y evolución técnica de ARE (Abuse Reputation Engine).

El documento conserva tanto el historial técnico relevante como el trabajo pendiente. Las tareas resueltas permanecen documentadas cuando contienen decisiones, fases, validaciones o información útil para comprender la evolución del proyecto.

Se organiza en:

* Bugs
* Tasks
* Features
* RFC
* Ideas

---

# BUGS

## BUG-002

**Título:** Verificar sincronización Backend ↔ Fail2Ban

**Estado:** En observación

**Prioridad:** Media

**Descripción**

Continuar validando durante la operación en producción que todas las acciones generadas por Fail2Ban sean procesadas correctamente por ARE.

El objetivo es garantizar que la transición entre los eventos generados por Fail2Ban y las decisiones ejecutadas por ARE permanezca sincronizada.

---

# TASKS

## TASK-013

**Título:** Consolidación y limpieza de documentación técnica

**Estado:** En progreso

**Prioridad:** Alta

**Objetivo**

Revisar y normalizar la documentación oficial de ARE para garantizar que refleje el estado real del proyecto y conserve la trazabilidad técnica de su evolución.

**Alcance**

* corregir estados históricos;
* eliminar contradicciones entre documentos;
* conservar decisiones y validaciones relevantes;
* sincronizar versiones;
* separar trabajo histórico de trabajo pendiente;
* mantener la documentación técnica de las fases de implementación;
* evitar pérdida de información durante futuras reorganizaciones documentales.

**Documentos relacionados**

* `docs/PHILOSOPHY.md`
* `docs/PROJECT.md`
* `docs/ROADMAP.md`
* `docs/SECURITY.md`
* `docs/TODO.md`
* `docs/CHANGELOG.md`

---

# FEATURES

## FEAT-001

**Título:** Sensor Fail2Ban

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Implementado**

* Evento `FOUND`.
* Sensor Fail2Ban.
* Cursor persistente.
* Modo `--dry-run`.
* Modo `--execute`.
* Ejecución automática mediante systemd timer.
* Registro en SQLite.
* Integración con Policy Engine.
* Validación en producción.

**Evolución**

El sensor fue incorporado como primera implementación del Sensor Framework.

El procesamiento utiliza un offset persistente para evitar reprocesar eventos ya procesados.

El framework permite incorporar nuevos sensores sin modificar el núcleo de ARE.

**Pendiente histórico**

Quedan registradas como parte de la evolución del sensor las tareas de limpieza y normalización de configuración que fueron identificadas durante su desarrollo. Estas tareas deberán considerarse únicamente si todavía existen dependencias en la implementación actual.

---

## FEAT-003

**Título:** Mostrar TOP JAILS en `stats`

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Objetivo**

Mostrar en el dashboard estadístico cuáles jails generan mayor actividad.

**Fuente de datos**

Tabla `events`.

**Implementación**

* `stats` muestra TOP JAILS.
* Se excluyen eventos internos como `fail2ban` y `policy_apply`.
* La información se obtiene desde `events`.

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

## FEAT-004

**Título:** Reputation Decay Engine

**Estado:** ✔ Resuelto — recuperación controlada inicial

**Versión:** v1.1.0

**Prioridad:** Alta

**Objetivo**

Implementar un mecanismo de reducción gradual del score de reputación para IPs sin actividad reciente.

**Reglas iniciales**

* Aplicar decay únicamente a IPs sin actividad durante al menos 24 horas.
* Utilizar un factor inicial de reducción de `0.95`.
* Recalcular `total_score` después de aplicar decay.
* Reevaluar la IP mediante el State Engine.
* Reevaluar la IP mediante el Policy Engine.
* No eliminar la reputación de forma inmediata.

**Parámetros iniciales**

```text
DECAY_MIN_AGE=86400
DECAY_FACTOR=0.95
```

**Modos**

`decay-dry-run`:

* muestra IPs candidatas;
* calcula el score estimado;
* no modifica datos.

`decay-apply`:

* aplica la reducción real;
* actualiza `last_decay`;
* reevalúa State Engine;
* reevalúa Policy Engine;
* no ejecuta directamente cambios sobre firewall.

**Control de frecuencia**

Se incorporó:

```text
last_decay
```

en la tabla `reputation`.

Su finalidad es impedir que una misma IP reciba múltiples reducciones dentro de la misma ventana de recuperación.

**Validación**

* Score reducido correctamente.
* State Engine actualizado.
* Policy Engine evaluado.
* `decay-dry-run` muestra candidatas.
* `decay-dry-run` calcula score estimado.
* `decay-apply` reduce score real.
* `decay-apply` actualiza `last_decay`.
* Se evita aplicar decay múltiples veces dentro de la misma ventana.
* Se validó el procesamiento de 487 IPs.
* Una segunda ejecución sin transcurrir la ventana no genera nuevas candidatas.

**Recuperación controlada**

La recuperación se encuentra vinculada a la decisión del Policy Engine.

* `ALLOW` puede generar liberación.
* `WATCH` no libera automáticamente.
* `FILTER` no libera automáticamente.
* `TEMP_BAN` no libera automáticamente.
* `BAN` no libera automáticamente.

**Siguiente etapa**

Evaluar la activación controlada de las decisiones generadas por el Decay Engine sobre el estado del firewall, manteniendo separadas la recuperación de reputación y la decisión de aplicación.

---

# HISTORIAL DE TASKS RESUELTAS

## TASK-001

**Título:** Reorganizar reglas del Policy Engine

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Descripción**

Las reglas fueron reorganizadas dentro de:

```text
policy/rules/
```

La reorganización permitió separar las reglas de decisión de la implementación general del Policy Engine.

---

## TASK-002

**Título:** Cursor persistente para sensores

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Descripción**

Implementación de un mecanismo persistente de offset para evitar reprocesar eventos ya leídos desde los logs.

El mecanismo quedó integrado en el Sensor Fail2Ban.

---

## TASK-003

**Título:** Automatizar ejecución del Fail2Ban Sensor

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Descripción**

Se creó un servicio y un timer de systemd para ejecutar automáticamente el sensor Fail2Ban.

La ejecución periódica permite procesar nuevos eventos sin intervención manual.

---

## TASK-004

**Título:** Agregar estadísticas por jail

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Descripción**

Se incorporó la sección TOP JAILS al comando `stats`.

La información se obtiene desde la tabla `events`, permitiendo distinguir actividad por jail sin depender de la tabla `reputation`.

---

## TASK-005

**Título:** Ampliar categorías del Reputation Engine

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Objetivo**

Expandir el modelo de reputación para soportar categorías adicionales de amenazas.

**Categorías incorporadas**

* ANOMALY
* MALWARE
* DOS
* SOCIAL

**Implementación**

* Base de datos.
* `database.sh`.
* `dashboard/stats.sh`.
* `dashboard/score.sh`.
* cálculo de `total_score`.

**Validación**

* Nuevas columnas agregadas a `reputation`.
* Todas las categorías integradas al modelo.
* `stats` muestra las categorías.
* `score <ip>` muestra las categorías.
* `total_score` incluye las categorías.

**Regla**

Los jails continúan mapeándose mediante `jail_profile` hacia una categoría de reputación.

No se crean columnas específicas por jail.

---

## TASK-006

**Título:** Incorporar perfiles de reputación para sshd, telnet y recidive

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Objetivo**

Asignar perfiles de reputación a jails críticos.

**Jails**

* `sshd` → `CREDENTIAL`
* `telnet` → `CREDENTIAL`
* `recidive` → `EXPLOIT`

**Validación**

* `sshd` agregado como perfil `CREDENTIAL`.
* `telnet` agregado como perfil `CREDENTIAL`.
* `recidive` validado como perfil existente `EXPLOIT`.
* Sensor Fail2Ban permite `sshd` y `telnet`.
* `FOUND sshd` suma score correctamente.
* `FOUND telnet` suma score correctamente.

---

## TASK-007

**Título:** Mejorar Dashboard de Reputación con información temporal

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Media

**Objetivo**

Mejorar la salida de `score <IP>` para mostrar información temporal comprensible.

**Implementación**

Se reemplazó la presentación directa del timestamp Unix por información temporal legible para administración.

**Validación**

* `score` muestra fecha legible de última actividad.
* `score` muestra antigüedad relativa.
* Se eliminó la presentación del timestamp Unix como única información temporal.

---

## TASK-008

**Título:** Controlar frecuencia de ejecución del Decay Engine

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Problema**

`updated` representa la última actividad o modificación de reputación, pero no la última ejecución del decay.

Utilizarlo directamente para controlar ejecuciones podía provocar múltiples reducciones dentro de una misma ventana.

**Solución**

Se agregó:

```text
last_decay
```

a `reputation`.

**Validación**

* `db_init()` crea `last_decay` en instalaciones nuevas.
* `decay-dry-run` respeta `last_decay`.
* `decay-apply` actualiza `last_decay`.
* Se evita aplicar decay múltiples veces dentro de la misma ventana.
* Validado con 487 IPs procesadas.

---

## TASK-009

**Título:** Consolidar el módulo Policy

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Objetivo**

Mover progresivamente los archivos `policy*.sh` desde la raíz hacia `policy/`, sin modificar la lógica funcional.

### Fase 1 — `policy_apply.sh`

✔ Resuelta.

* Movido a `policy/apply.sh`.
* `bootstrap.sh` actualizado.
* Se agregó wrapper `apply_decision()` para mantener compatibilidad.
* Validado con `top`.
* Validado con `found modsec-protocol`.

### Fase 2 — Context

✔ Resuelta.

* `policy_context.sh` movido a `policy/context.sh`.
* `policy_context_api.sh` movido a `policy/context_api.sh`.
* `bootstrap.sh` actualizado.
* Referencia antigua corregida en `policy/rules/anomaly.sh`.
* Validado con `top`.
* Validado con `found modsec-protocol`.

### Fase 3 — Decision

✔ Resuelta.

* `policy_decision.sh` movido a `policy/decision.sh`.
* `policy_decision_engine.sh` movido a `policy/decision_engine.sh`.
* `bootstrap.sh` actualizado.
* Referencias internas corregidas.
* Validado con `top`.
* Validado con `found modsec-protocol`.

### Fase 4 — Engine

✔ Resuelta.

* `policy_engine.sh` movido a `policy/engine.sh`.
* `policy_risk.sh` movido a `policy/risk.sh`.
* `policy_env.sh` movido a `policy/env.sh`.
* `policy.sh` movido a `policy/policy.sh`.
* `bootstrap.sh` actualizado.
* Validado con `top`.
* Validado con `found modsec-protocol`.

---

## TASK-010

**Título:** Implementar Ban Lifecycle Engine

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Objetivo**

Implementar un motor encargado de administrar el ciclo de vida de las sanciones aplicadas por ARE.

El Ban Lifecycle Engine no determina si una IP es peligrosa. Esa decisión corresponde al Reputation Engine, State Engine y Policy Engine.

Su responsabilidad consiste en determinar cómo evoluciona una sanción cuando ARE decide aplicar `TEMP_BAN` o `BAN`.

### Persistencia

Se creó:

```text
sanction_state
```

para almacenar el estado de sanción de cada IP.

**Información administrada**

* nivel de ban;
* cantidad de sanciones;
* duración;
* finalización del ban;
* estado permanente.

### Funciones de persistencia

* `db_init_sanction()`
* `db_increment_ban_level()`
* `db_get_ban_level()`

La persistencia fue validada con `sanction-test`.

IP utilizada durante la validación:

```text
84.84.84.84
```

### Simulation Mode

Se implementó el cálculo de la siguiente sanción sin modificar firewall, reputation, policy ni DB.

**Entrada**

* IP
* `ban_level`
* `ban_count`
* `permanent`

**Salida**

```text
ACTION|TIME|REASON
```

**Política inicial**

* Nivel 1: 1 hora.
* Nivel 2: 6 horas.
* Nivel 3: 24 horas.
* Nivel 4: 7 días.
* Nivel 5: 15 días.
* Nivel 6: 30 días.
* Nivel 7: permanente.

El nivel máximo se controla mediante:

```text
BAN_LEVEL_MAX
```

`ban_level` queda limitado al máximo configurado, mientras `ban_count` continúa acumulando las sanciones históricas.

### Integración con TEMP_BAN

✔ Resuelta.

Flujo implementado:

```text
Policy Engine
      ↓
Ban Lifecycle Engine
      ↓
siguiente nivel
      ↓
ban_level / ban_count
      ↓
ban_until
      ↓
Backend
```

Validación:

* `TEMP_BAN` integrado.
* Primera sanción calculada como `BAN_LEVEL_1`.
* Duración aplicada: `3600` segundos.
* `ban_level`, `ban_count` y `ban_until` actualizados.
* Backend ejecutó el bloqueo temporal.

### Escalado permanente

✔ Resuelto.

Se implementó el escalado hasta ban permanente.

Con el nivel previo al máximo:

```text
BAN|0|BAN_LEVEL_MAX
```

se ejecuta el bloqueo permanente.

Validación:

* `policy/apply.sh` ejecuta escalado permanente.
* La IP se elimina del conjunto `FILTER`.
* La IP se incorpora al conjunto permanente.
* `sanction_state` conserva:

```text
ban_level = 7
ban_count = 7
ban_until = 0
permanent = 1
```

---

## TASK-011

**Título:** Mostrar estado de sanción en el dashboard de reputación

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Objetivo**

Mostrar en `score <IP>` el estado almacenado en `sanction_state`.

**Datos**

* Nivel actual de sanción.
* Cantidad total de sanciones.
* Tipo de sanción actual.
* Fecha de finalización del ban temporal.
* Estado permanente.
* Último ban.
* Último unban.

**Archivos relacionados**

* `dashboard/score.sh`
* `database.sh`
* `sanction_state`

**Validación**

* Dashboard consulta `sanction_state`.
* Muestra nivel actual.
* Muestra cantidad total.
* Distingue sanción temporal y permanente.
* Muestra fecha de finalización cuando corresponde.
* Muestra último ban y último unban.
* Validado con IP `84.84.84.84`.

---

## TASK-012

**Título:** Centralizar rutas y eliminar dependencias estáticas

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Objetivo**

Eliminar rutas estáticas del código fuente y centralizar las ubicaciones operativas mediante `config.conf`.

**Alcance**

* Ruta del código.
* Ruta de configuración.
* Ruta de datos.
* Ruta de base de datos.
* Ruta de logs.
* Ruta de sensores.
* Ruta de archivos temporales.
* Ejecutable principal.

**Regla**

No renombrar directorios ni ejecutables hasta eliminar previamente las dependencias estáticas.

### Inventario inicial

Se encontraron referencias en:

* `dashboard.sh`
* `bootstrap.sh`
* `f2b-ipset.sh`
* `policy/apply.sh`
* `policy/engine.sh`
* `policy/env.sh`
* `policy/policy.sh`
* `sensors/fail2ban.sh`
* `testing/run_tests.sh`
* `tmp/sync-f2b-are.sh`
* `config.conf`

También se detectaron referencias antiguas en `policy/env.sh` y `policy/policy.sh`.

### Exclusiones

Inicialmente se excluyeron:

* `docs/`
* archivos `.save`
* ejemplos históricos;
* archivos temporales no utilizados en producción.

Los directorios `testing/` y `tmp/` quedaron fuera del runtime de producción.

### Implementación

* Variables oficiales definidas en `config.conf`.
* `f2b-ipset.sh` localiza dinámicamente su configuración mediante `BASH_SOURCE`.
* `bootstrap.sh` utiliza `ARE_HOME` y `ARE_POLICY_CONFIG`.
* Módulos de producción consumen variables oficiales.
* Sensor Fail2Ban resuelve dinámicamente la ubicación del proyecto.
* Se eliminaron dependencias operativas de rutas fijas externas a la configuración.

### Validación

* Sensor obtiene su ubicación mediante `BASH_SOURCE`.
* Usa `ARE_BIN` y `ARE_DATA`.
* No depende de rutas estáticas en `/opt` ni `/var/lib`.
* Validado mediante `are-fail2ban-found.service`.
* Flujo `FOUND → Reputation → Policy → Apply` operativo.
* Validado mediante `stats`.
* Validado mediante servicio del sensor Fail2Ban.

---

## TASK-014

**Título:** Crear instalador modular de ARE

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Objetivo**

Crear un Installer Engine que implemente el procedimiento definido en `docs/INSTALL.md`.

**Principios**

* Una responsabilidad por función.
* No sobrescribir configuraciones existentes.
* No eliminar datos persistentes.
* No modificar automáticamente Fail2Ban, ModSecurity o Apache.
* Detener la instalación ante errores críticos.
* Verificar cada etapa antes de continuar.

**Funciones**

* `install_verify_root`
* `install_verify_dependencies`
* `install_create_directories`
* `install_copy_files`
* `install_install_configs`
* `install_create_links`
* `install_permissions`
* `install_database`
* `install_systemd`
* `install_validate`
* `install_finish`

### Upgrade desde paquete externo

✔ Validado.

* Installer Engine detecta instalación existente.
* Copia únicamente `PRODUCT_DIRS` y `PRODUCT_FILES`.
* Conserva configuración y datos persistentes.
* Actualiza enlaces oficiales.
* Actualiza unidades systemd.
* Validación integral satisfactoria.

### Instalación segura de configuración

✔ Validada.

Se creó:

```text
templates/config/
```

como origen oficial de configuración.

Los archivos administrados se obtienen mediante:

```text
PRODUCT_CONFIG_FILES
```

`install_install_configs()`:

* crea enlaces únicamente cuando el destino no existe;
* conserva archivos físicos personalizados;
* reconoce enlaces correctos;
* conserva e informa enlaces rotos;
* conserva e informa enlaces válidos con destino diferente;
* detiene la instalación cuando falta una plantilla obligatoria.

La implementación fue validada en laboratorio aislado y la instalación activa de producción no fue modificada durante esa validación.

---

# RFC

## RFC-001

**Título:** Renombrar CLI oficial a `are`

**Estado:** Draft

**Objetivo**

Establecer `are` como CLI oficial del proyecto.

La decisión deberá contemplar compatibilidad con el nombre histórico utilizado por las instalaciones existentes.

---

## RFC-002

**Título:** Sensor Framework

**Estado:** Accepted

**Versión:** v1.1.0

**Descripción**

ARE incorpora una capa de sensores encargada de transformar eventos externos en eventos internos procesables por el motor de reputación.

El primer sensor oficial corresponde a Fail2Ban.

**Resultado**

El Sensor Framework quedó incorporado en v1.1 y el sensor Fail2Ban constituye su primera implementación oficial.

---

## RFC-003

**Título:** Identity Migration

**Estado:** Draft

**Versión objetivo:** Posterior a v1.1

**Descripción**

Evaluar la transición desde la identidad histórica `f2b-ipset` hacia el nombre oficial del proyecto:

**ARE — Abuse Reputation Engine**

**Objetivo**

Alinear progresivamente:

* comandos;
* rutas;
* servicios;
* configuración;
* documentación;
* identidad del paquete.

**Alcance propuesto**

* Crear CLI oficial `are`.
* Mantener compatibilidad temporal con `f2b-ipset.sh`.
* Evaluar migración futura de `/opt/f2b-ipset/` hacia `/opt/are/`.
* Evaluar migración futura de configuración hacia `/etc/are/`.
* Evaluar migración futura de base de datos hacia rutas ARE.
* Actualizar documentación afectada.

**Regla**

La migración deberá realizarse gradualmente para no romper instalaciones existentes.

---

## RFC-004

**Título:** ARE como autoridad principal de decisión

**Estado:** Draft

**Descripción**

Evaluar la transición del modelo actual hacia un modelo donde Fail2Ban actúe principalmente como fuente de eventos y ARE asuma la autoridad sobre las decisiones de bloqueo, filtrado, liberación y escalado.

**Objetivo**

Permitir que ARE determine la respuesta final utilizando:

* reputación;
* score;
* historial;
* reincidencia;
* estado de la IP;
* política configurada.

El objetivo es evitar que una acción externa de Fail2Ban contradiga una decisión de ARE.

**Impacto esperado**

* Mayor autonomía de ARE.
* Mayor coherencia entre reputación y firewall.
* Control centralizado del ciclo de vida de una IP.
* Fail2Ban como sensor y no como autoridad final.

**Puntos a definir**

* Tratamiento de eventos `BAN`.
* Tratamiento de eventos `UNBAN`.
* Condiciones para liberar una IP.
* Integración con Ban Lifecycle.
* Condiciones para bloqueo permanente.
* Relación entre decisiones de ARE y acciones externas.

**Validación inicial**

Se implementó y validó manualmente:

```bash
./f2b-ipset.sh external-unban <IP> <JAIL>
```

Esta validación no implica que la RFC haya sido aceptada.

---

## RFC-005

**Título:** Ciclo autónomo de recuperación y sanción

**Estado:** Draft

**Descripción**

Definir la evolución futura del ciclo completo de una IP cuando ARE controle de forma autónoma la relación entre reputación, estado, sanciones y recuperación.

La parte correspondiente al cálculo básico de Reputation Decay ya fue implementada en v1.1 y no debe considerarse pendiente dentro de esta RFC.

**Objetivo futuro**

Evaluar un ciclo compuesto por:

```text
observación
    ↓
reputación
    ↓
decisión
    ↓
sanción
    ↓
escalado
    ↓
recuperación
    ↓
reevaluación
    ↓
liberación
```

**Principios**

* Una IP deja de ser peligrosa gradualmente.
* La reputación no se elimina de golpe.
* La liberación debe ser consecuencia de una decisión de ARE.
* Fail2Ban actúa como fuente de información.
* Los límites de escalado deben ser configurables.

**Puntos pendientes de definición**

* Frecuencia definitiva del Decay Engine.
* Fórmula definitiva de recuperación.
* Umbral de liberación.
* Relación entre score y estado de sanción.
* Condiciones para liberar un `TEMP_BAN`.
* Condiciones para conservar un bloqueo aunque el score disminuya.
* Relación entre reincidencia y Ban Lifecycle.
* Condición definitiva para `BAN` permanente.
* Tratamiento de `EXTERNAL_UNBAN`.

---

# IDEAS

## IDEA-001

**Título:** Exportación de métricas

Evaluar mecanismos para exportar métricas de ARE hacia sistemas externos.

---

## IDEA-002

**Título:** API REST

Evaluar una API para consulta e integración externa.

---

## IDEA-003

**Título:** Backend Manager

Evaluar una capa de administración de múltiples backends de firewall.

---

## IDEA-004

**Título:** Dashboard avanzado

Evaluar ampliaciones del dashboard, incluyendo:

* métricas históricas;
* gráficos;
* consultas avanzadas;
* análisis temporal;
* evolución de reputación.

---

# HISTORIAL DE BUGS RESUELTOS

Las siguientes incidencias forman parte del historial técnico de ARE y se conservan para trazabilidad.

## BUG-001

**Título:** Implementar `handle_unban()`

**Estado:** ✔ Resuelto

**Versión:** v1.0.1

**Corrección**

Se incorporó `handle_unban()` para completar el flujo de liberación de direcciones IP.

---

## BUG-005

**Título:** Inicialización duplicada del backend

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Corrección**

Se eliminó la doble inicialización de IPSet y Firewall centralizando el proceso en:

```text
backend/init.sh
```

---

## BUG-006

**Título:** La categoría ANOMALY no se refleja en las estadísticas

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Media

**Problema**

La categoría `ANOMALY` era utilizada por el Policy Engine y los perfiles de jail, pero no formaba parte inicialmente del modelo de reputación persistente.

**Impacto**

* Dashboard incompleto.
* Estadísticas inconsistentes.
* Categorías del motor y Dashboard no coincidentes.

**Corrección**

Se incorporó `ANOMALY` al modelo persistente junto con:

* `MALWARE`
* `DOS`
* `SOCIAL`

**Validación**

* `stats` muestra `Anomaly`.
* `score <ip>` muestra `Anomaly`.
* `FOUND modsec-anomaly` incrementa correctamente el total.

---

## BUG-007

**Título:** ARE no procesa correctamente eventos BAN/UNBAN provenientes de Fail2Ban

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Problema**

ARE procesaba eventos `FOUND`, pero determinados eventos `BAN` y `UNBAN` generados por Fail2Ban no quedaban registrados correctamente en el historial.

**Evidencia inicial**

Fail2Ban registraba eventos `Unban`, pero la consulta:

```text
events <IP>
```

no mostraba la actividad correspondiente.

**Impacto**

* El ciclo `FOUND → BAN → UNBAN` podía quedar incompleto.
* El historial podía no representar la actividad real.
* ARE dependía parcialmente de la acción directa de Fail2Ban.

**Corrección**

El sensor Fail2Ban unificado incorporó el procesamiento de:

* `FOUND`
* `UNBAN`

Los eventos externos de liberación se registran como:

```text
EXTERNAL_UNBAN
```

`EXTERNAL_UNBAN` no libera directamente la IP.

ARE reevalúa la IP mediante el Policy Engine.

**Archivos relacionados**

* `sensors/fail2ban_found.sh`
* `/etc/fail2ban/action.d/ipset-smart.conf`
* `f2b-ipset.sh`
* `database.sh`

**Validación**

Validado en producción con:

```text
103.59.161.151
```

---

## BUG-008

**Título:** Incoherencia entre State Engine y Policy Engine para estado FILTER

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Problema**

Durante la ejecución del Decay Engine se detectaron IPs con:

```text
STATUS=NEW
```

mientras el Policy Engine devolvía:

```text
FILTER
```

para:

```text
LOW_RISK
```

**Evidencia**

```text
SCORE=23->21 STATUS=NEW POLICY=FILTER REASON=LOW_RISK
```

**Corrección**

Se modificó `state_update()` para reconocer `FILTER`.

**Validación**

El Decay Engine dejó de producir la incoherencia:

```text
STATUS=NEW POLICY=FILTER
```

Validado mediante:

```text
decay-apply
```

---

## BUG-009

**Título:** `policy/apply.sh` no implementa la acción FILTER

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Problema**

El Policy Engine devolvía correctamente `FILTER`, pero `policy/apply.sh` no tenía una rama para ejecutar dicha acción.

**Evidencia**

```text
Policy decision: FILTER (LOW_RISK)
[APPLY] UNKNOWN ACTION: FILTER
```

**Corrección**

Se agregó soporte para:

```text
FILTER
```

IPv4 utiliza:

```text
FILTER_SET4
```

IPv6 utiliza:

```text
FILTER_SET6
```

`BAN` y `TEMP_BAN` utilizan sus conjuntos correspondientes.

**Validación**

Validado con:

```text
87.87.87.87
```

La IP fue incorporada correctamente a:

```text
are-filter
```

y el evento `FILTER` quedó registrado.

---

## BUG-010

**Título:** Ban Lifecycle no reconoce escalado permanente por salida multilínea

**Estado:** ✔ Resuelto

**Versión:** v1.1.0

**Prioridad:** Alta

**Problema**

Ban Lifecycle devolvía:

```text
BAN|0|BAN_LEVEL_MAX
```

pero `policy/apply.sh` interpretaba incorrectamente el resultado como un ban temporal.

**Evidencia**

```text
[APPLY] Ban Lifecycle:
BAN|0|BAN_LEVEL_MAX

[APPLY] EXECUTE: TEMP BAN (0 sec)
```

**Corrección**

Se normalizó la salida de:

```text
ban_lifecycle_calculate()
```

y `policy/apply.sh` reconoce correctamente:

```text
BAN|0|BAN_LEVEL_MAX
```

**Validación**

El escalado permanente se ejecuta correctamente.

---

# OBSERVACIONES

La documentación de trabajo debe mantenerse sincronizada con el estado real de ARE.

Las entradas históricas resueltas se conservan cuando aportan:

* contexto;
* decisiones arquitectónicas;
* fases de implementación;
* evidencias;
* validaciones;
* información necesaria para comprender la evolución del sistema.

Las funcionalidades ya incorporadas en una versión estable no deberán reaparecer como trabajo pendiente.

Las RFC representan propuestas sujetas a decisión y no deben confundirse con funcionalidades implementadas.

Las ideas no constituyen compromisos de implementación.

La versión estable documentada actualmente es:

```text
v1.1.0
```

El trabajo futuro deberá incorporarse al Roadmap antes de convertirse en una línea formal de desarrollo.
