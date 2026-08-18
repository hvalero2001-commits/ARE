ARE TODO

Este documento mantiene el registro de trabajo del proyecto ARE (Abuse Reputation Engine).

El TODO no sustituye al CHANGELOG:

TODO = trabajo pendiente y estado de tareas.

CHANGELOG = historial de cambios realizados.

ARCHITECTURE / DESIGN = definición técnica y arquitectura.

GOVERNANCE = reglas de evolución del proyecto.

La evolución histórica de v1.x se conserva como referencia. Los elementos ya implementados no se presentan nuevamente como trabajo abierto.

ESTADO ACTUAL — ARE v2.0

Versión: v2.0.0
Rama de desarrollo histórica: v2.0-dev
Estado documental: v2.0 implementada y validada según el CHANGELOG y las validaciones registradas.

La v2 consolida la identidad ARE y abandona como estructura operativa la antigua organización f2b-ipset.

Estructura oficial:

/opt/are                 Producto
/opt/are/config          Configuración
/var/lib/are             Datos persistentes
/var/log/are             Logs
/usr/local/sbin          Enlaces ejecutables oficiales
/etc/systemd/system      Unidades systemd
/etc/logrotate.d         Configuración logrotate

El Product Manifest:

manifest/product.sh

es la referencia oficial de los componentes administrados por ARE.

Base persistente:

/var/lib/are/are.db

V2 — TRABAJO DE LA VERSIÓN

V2-001 — Product Manifest

Estado: ✔ Resuelto / Validado

Implementado y validado:

identidad del producto;

versión;

directorios;

archivos;

configuración;

datos persistentes;

unidades systemd;

enlaces ejecutables;

logrotate;

exclusiones.

El Installer Engine utiliza el Product Manifest como referencia de los componentes administrados.

V2-002 — Identidad y estructura del producto

Estado: ✔ Resuelto / Validado

Implementado:

identidad operativa ARE;

producto en /opt/are;

configuración separada;

datos persistentes en /var/lib/are;

logs en /var/log/are;

enlaces oficiales en /usr/local/sbin.

Las referencias f2b-ipset que permanezcan en documentación histórica no representan la estructura operativa de v2.

V2-003 — Installer Engine

Estado: ✔ Resuelto / Validado

Operaciones:

install
upgrade
repair
verify
uninstall

Validado:

uso del Product Manifest;

detección de instalaciones existentes;

conservación de configuración;

conservación de datos persistentes;

actualización de componentes administrados;

reconstrucción de instalaciones incompletas;

validación posterior de la instalación.

La documentación de instalación establece además que repair no debe modificar reputación, configuración ni base de datos y que uninstall no elimina automáticamente los datos persistentes.

V2-004 — Separación PRODUCT / CONFIG / DATA

Estado: ✔ Resuelto / Validado

ARE v2 mantiene separadas:

PRODUCT
CONFIG
DATA

El mantenimiento del producto no debe destruir ni sustituir configuración ni datos persistentes.

Esta separación forma parte de la arquitectura de v2 y del Installer Engine.

V2-005 — Base de datos persistente

Estado: ✔ Resuelto / Validado

Base oficial:

/var/lib/are/are.db

Estructuras operativas documentadas:

hosts
events
config
jails
reputation
jail_profile
sanction_state

Los datos históricos necesarios fueron incorporados a la estructura persistente de v2.

V2-006 — Enlaces oficiales

Estado: ✔ Resuelto / Validado

Componentes administrados:

are
are-installer
are-fail2ban-sensor

CLI principal:

/usr/local/sbin/are -> /opt/are/are.sh

V2-007 — Entorno de ejecución

Estado: ✔ Resuelto / Validado

El Installer Engine garantiza la disponibilidad de:

/usr/local/sbin

durante:

install
upgrade
repair

La modificación necesaria de /root/.bash_profile se realiza de forma idempotente.

V2-008 — Fail2Ban Sensor

Estado: ✔ Resuelto / Validado

El Sensor Framework incorpora el sensor oficial de Fail2Ban.

Eventos relevantes:

FOUND
EXTERNAL_UNBAN

El sensor utiliza cursor/offset persistente para evitar reprocesamiento.

EXTERNAL_UNBAN no libera directamente una IP. El evento vuelve a pasar por la evaluación de ARE.

La funcionalidad fue validada durante la evolución de v1.1 y forma parte de la base operativa de v2.

V2-009 — Reputation Decay

Estado: ✔ Resuelto / Validado

El Decay Engine forma parte del ciclo operativo.

Unidades:

are-fail2ban-decay.service
are-fail2ban-decay.timer

Modos:

dry-run
apply

Validado:

reducción controlada del score;

actualización del State Engine;

reevaluación mediante Policy Engine;

control mediante last_decay;

prevención de múltiples reducciones dentro de la misma ventana;

ejecución mediante systemd;

recuperación únicamente cuando corresponde según la decisión del Policy Engine.

Durante la evolución del proyecto se corrigieron las incoherencias encontradas en el ciclo de decay, incluyendo la interacción con FILTER y el estado de la IP.

V2-010 — Ban Lifecycle Engine

Estado: ✔ Resuelto / Validado

El Ban Lifecycle Engine quedó implementado como parte de la evolución previa a v2.

Componentes validados:

sanction_state;

niveles de sanción;

contador histórico;

ban_until;

sanciones temporales;

escalado progresivo;

escalado a ban permanente;

integración con policy/apply.sh.

La fase de escalado permanente fue validada con:

BAN|0|BAN_LEVEL_MAX

y con persistencia del estado permanente.

V2-011 — Acción FILTER

Estado: ✔ Resuelto / Validado

Se corrigió la incoherencia entre State Engine, Policy Engine y Apply.

policy/apply.sh implementa FILTER.

Conjuntos:

FILTER_SET4
FILTER_SET6

La decisión FILTER dejó de producir:

UNKNOWN ACTION: FILTER

La funcionalidad fue validada con IPv4 y registrada en eventos.

V2-012 — Centralización de rutas

Estado: ✔ Resuelto / Validado

Las rutas operativas fueron centralizadas durante v1.1 como preparación directa para la migración a la identidad ARE.

Se validó:

configuración centralizada;

resolución dinámica del directorio del proyecto;

uso de variables oficiales;

eliminación de dependencias estáticas del runtime;

funcionamiento del sensor;

continuidad del flujo:

FOUND
  ↓
Reputation
  ↓
Policy
  ↓
Apply

La migración posterior a /opt/are forma parte de v2.

V2-013 — Dashboard y estado de sanción

Estado: ✔ Resuelto / Validado

El dashboard de reputación incorpora información de sanction_state, incluyendo:

nivel;

cantidad de sanciones;

tipo de sanción;

finalización del ban temporal;

estado permanente;

último ban;

último unban.

También se incorporaron las mejoras de categorías y estadísticas realizadas durante v1.1.

V2-014 — Estadísticas y TOP JAILS

Estado: ✔ Resuelto / Validado

stats incorpora actividad por jail y TOP JAILS utilizando la tabla:

events

Se excluyen eventos internos que no representan actividad de jail.

V2-015 — Categorías adicionales del Reputation Engine

Estado: ✔ Resuelto / Validado

El modelo de reputación incorpora:

ANOMALY
MALWARE
DOS
SOCIAL

Las categorías están integradas en:

base de datos;

Reputation Engine;

estadísticas;

score;

cálculo de total_score;

perfiles de jail.

VALIDACIÓN INTEGRAL DE V2

V2-016 — Cadena operativa completa

Estado: ✔ Resuelto / Validado

La arquitectura operativa validada es:

Sensor / evento externo
        ↓
Sensor Framework
        ↓
evento ARE
        ↓
Reputation Engine
        ↓
State Engine
        ↓
Policy Engine
        ↓
Apply
        ↓
Backend
        ↓
estado persistente

Para Fail2Ban:

Fail2Ban
   ↓
Sensor
   ↓
FOUND / EXTERNAL_UNBAN
   ↓
ARE
   ↓
Reputation
   ↓
State
   ↓
Policy
   ↓
Apply

Esta cadena no debe volver a registrarse como tarea abierta salvo que aparezca una nueva falla verificable.

V2-017 — Validación Installer ↔ Product Manifest

Estado: ✔ Resuelto / Validado

El Installer Engine utiliza el Product Manifest como fuente de los componentes administrados.

La estructura de instalación, configuración, datos, systemd, enlaces y logrotate queda definida desde esa referencia.

V2-018 — Validación de instalación y upgrade

Estado: ✔ Resuelto / Validado

Se validó:

install
upgrade

El upgrade conserva:

CONFIG
DATA

y actualiza los componentes correspondientes al producto.

La instalación segura de configuración conserva archivos físicos personalizados y evita sobrescrituras innecesarias.

V2-019 — Validación de reparación

Estado: ✔ Resuelto / Validado

repair restaura componentes faltantes o dañados sin destruir:

reputation
configuration
database

V2-020 — Validación de desinstalación

Estado: ✔ Resuelto / Validado

uninstall elimina los componentes del producto y servicios correspondientes, pero no elimina automáticamente:

configuration
database
historical reputation

La eliminación de datos persistentes requiere una acción explícita del administrador.

HISTORIAL V1.x — CONSERVADO

Los siguientes elementos pertenecen al desarrollo histórico de ARE v1.x. No son trabajo abierto de v2.

BUG-001 — handle_unban()

Estado: ✔ Resuelto
Versión: v1.0.1

BUG-002 — Sincronización Backend ↔ Fail2Ban

Estado: ✔ Resuelto / Integrado
Versión de origen: v1.x

El registro pertenece a la línea histórica de v1.x. La evolución posterior del Sensor Framework resolvió el problema mediante el procesamiento integrado de eventos de Fail2Ban, incluyendo FOUND y EXTERNAL_UNBAN.

El estado histórico se conserva por trazabilidad, pero BUG-002 no constituye trabajo abierto en ARE v2.0.

BUG-005 — Inicialización duplicada del backend

Estado: ✔ Resuelto
Versión: v1.1-dev

BUG-006 — Categoría ANOMALY ausente de estadísticas

Estado: ✔ Resuelto
Versión: v1.1-dev

BUG-007 — Eventos BAN/UNBAN de Fail2Ban

Estado: ✔ Resuelto
Versión: v1.1-dev

La solución incorporó el sensor Fail2Ban unificado y el tratamiento de EXTERNAL_UNBAN.

BUG-008 — Incoherencia State Engine / Policy Engine para FILTER

Estado: ✔ Resuelto
Versión: v1.1-dev

BUG-009 — policy/apply.sh sin FILTER

Estado: ✔ Resuelto
Versión: v1.1-dev

BUG-010 — Ban Lifecycle y escalado permanente

Estado: ✔ Resuelto
Versión: v1.1-dev

TASKS HISTÓRICAS

TASK-001 — Reorganizar reglas del Policy Engine

Estado: ✔ Resuelto

Las reglas fueron trasladadas a:

policy/rules/

TASK-002 — Cursor persistente para sensores

Estado: ✔ Resuelto

El cursor/offset persistente quedó implementado dentro del Sensor Framework.

TASK-003 — Automatizar ejecución del Fail2Ban Sensor

Estado: ✔ Resuelto

Se implementaron service y timer de systemd.

TASK-004 — Estadísticas por jail

Estado: ✔ Resuelto

La capacidad fue incorporada mediante estadísticas y TOP JAILS.

TASK-005 — Ampliar categorías del Reputation Engine

Estado: ✔ Resuelto

TASK-006 — Perfiles sshd, telnet y recidive

Estado: ✔ Resuelto

TASK-007 — Información temporal del Dashboard

Estado: ✔ Resuelto

TASK-008 — Control de frecuencia del Decay Engine

Estado: ✔ Resuelto

Se incorporó:

last_decay

TASK-009 — Consolidar módulo Policy

Estado: ✔ Resuelto

Las fases de reorganización quedaron completadas.

TASK-010 — Ban Lifecycle Engine

Estado: ✔ Resuelto

Todas las fases registradas en el TODO histórico fueron completadas, incluyendo integración de TEMP_BAN y escalado permanente.

TASK-011 — Mostrar estado de sanción

Estado: ✔ Resuelto

TASK-012 — Centralizar rutas

Estado: ✔ Resuelto

TASK-014 — Crear instalador modular de ARE

Estado: ✔ Resuelto

La evolución de esta tarea desembocó en el Installer Engine de v2.

Validado:

upgrade desde instalación existente;

instalación segura de configuración;

conservación de datos;

enlaces;

systemd;

validación posterior.

FEATURES HISTÓRICAS

FEAT-001 — Fail2Ban Sensor

Estado: ✔ Operativo / Validado

Incluye:

FOUND;

cursor persistente;

dry-run;

execute;

systemd timer;

SQLite;

Policy Engine;

validación en producción.

FEAT-003 — TOP JAILS

Estado: ✔ Resuelto

FEAT-004 — Reputation Decay Engine

Estado: ✔ Resuelto

La recuperación controlada fue implementada y posteriormente integrada al ciclo operativo mediante systemd.

RFC

RFC-001 — CLI oficial are

Estado histórico: ✔ Implementado en v2

El comando oficial es:

/usr/local/sbin/are

RFC-002 — Sensor Framework

Estado: ✔ Implementado

El Sensor Framework forma parte de la arquitectura operativa.

RFC-003 — Identity Migration

Estado: ✔ Implementado en v2

La identidad oficial es:

ARE

La estructura operativa pasó a:

/opt/are

con separación de configuración y datos persistentes.

RFC-004 — ARE como autoridad principal de decisión

Estado: ✔ Implementado / Integrado

El tratamiento de eventos externos se realiza mediante la lógica de ARE y su Policy Engine.

Fail2Ban actúa como fuente de eventos dentro del Sensor Framework.

RFC-005 — Reputation Decay y ciclo autónomo

Estado: ✔ Implementado / Integrado

El mecanismo de decay y recuperación forma parte del ciclo operativo de ARE.

IDEAS

Las ideas siguientes no constituyen tareas de v2.0 mientras no exista una decisión explícita de incorporarlas a una versión:

Exportación de métricas.

Correlación entre múltiples sensores.

Motor de perfiles dinámicos.

Integración con plataformas SIEM.

Dashboard avanzado.

Nuevas capacidades de automatización no definidas por la arquitectura actual.

Una IDEA no debe transformarse automáticamente en una tarea de implementación.

REGLAS DEL TODO

1. No inventar trabajo abierto

Un elemento no se marca OPEN por el simple hecho de existir en una versión histórica del TODO.

Debe existir evidencia actual de que permanece pendiente.

2. No reabrir trabajo cerrado

Una tarea resuelta históricamente permanece resuelta.

Si posteriormente aparece una nueva falla, se crea un nuevo BUG/TASK con su propia evidencia.

3. No duplicar CHANGELOG

Los cambios realizados permanecen registrados en:

docs/CHANGELOG.md

El TODO únicamente mantiene el estado de trabajo.

4. No borrar la trazabilidad histórica

La evolución de v1.x se conserva para explicar cómo se llegó a v2.

5. Código, pruebas y documentación deben coincidir

Una capacidad no se considera cerrada si existe una discrepancia demostrable entre implementación, pruebas y documentación.

ESTADO DE TRABAJO ABIERTO

A partir de la documentación e historial analizados, no se registra aquí ninguna tarea funcional de ARE v2.0 como OPEN.

Esto no significa que el proyecto no pueda recibir nuevos BUG, TASK, FEATURE o RFC.

Significa únicamente que los elementos revisados y documentados como parte de la construcción de v2 fueron completados y validados, y que no corresponde reabrirlos artificialmente.

Una nueva incidencia deberá incorporarse únicamente después de:

Evidencia
   ↓
Análisis
   ↓
Clasificación
   ↓
TODO
   ↓
Corrección
   ↓
Prueba
   ↓
Cierre

CRITERIO DE CIERRE

Una tarea queda cerrada únicamente cuando:

la implementación existe;

la validación correspondiente fue realizada;

no queda trabajo definido dentro de la propia tarea;

la documentación correspondiente refleja el estado real.

Una nueva falla posterior no reabre automáticamente la tarea anterior: debe registrarse como una nueva incidencia relacionada con ella.

REFERENCIAS DE DOCUMENTACIÓN

docs/ARCHITECTURE.md
docs/BAN_LIFECYCLE.md
docs/CHANGELOG.md
docs/CONTRIBUTING.md
docs/DESIGN.md
docs/DEVELOPMENT.md
docs/GOVERNANCE.md
docs/INSTALL.md
docs/PHILOSOPHY.md
docs/PROJECT.md
docs/ROADMAP.md
docs/SECURITY.md
docs/TODO.md
docs/USER_GUIDE.md

El Product Manifest es la referencia para la estructura administrada del producto:

manifest/product.sh
