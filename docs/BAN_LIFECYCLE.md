# ARE Ban Lifecycle

## Introducción

El Ban Lifecycle Engine administra el ciclo de vida de las sanciones aplicadas por ARE.

Su responsabilidad no consiste en determinar si una dirección IP representa una amenaza. Esa decisión corresponde al flujo formado por el Reputation Engine, State Engine y Policy Engine.

El Ban Lifecycle Engine ejecuta la política decidida por ARE y administra su evolución a lo largo del tiempo.

---

# Objetivo

El objetivo del Ban Lifecycle Engine es garantizar que las sanciones evolucionen de forma consistente según el comportamiento histórico observado.

En ARE una sanción representa el resultado de un proceso de decisión y no una respuesta aislada a un único evento.

---

# Principios

El ciclo de vida de una sanción se basa en los siguientes principios:

- la reputación es persistente;
- las decisiones son acumulativas;
- las sanciones pueden evolucionar;
- la reincidencia incrementa el nivel de respuesta;
- las políticas determinan la duración y el tipo de sanción.

---

# Flujo general

```text
Evento
    │
    ▼
Sensor Framework
    │
    ▼
Reputation Engine
    │
    ▼
State Engine
    │
    ▼
Policy Engine
    │
    ▼
Ban Lifecycle Engine
    │
    ▼
Firewall Backend
    │
    ▼
Sistema operativo
```

Cada componente posee una única responsabilidad.

---

# Estados de una dirección IP

El Ban Lifecycle Engine administra la transición entre los estados definidos por el State Engine.

Estados soportados:

- NEW
- WATCH
- FILTER
- BANNED

El Ban Lifecycle Engine nunca modifica directamente la reputación.

---

# Decisiones soportadas

El Policy Engine puede generar las siguientes decisiones:

- ALLOW
- WATCH
- FILTER
- TEMP_BAN
- BAN

El Ban Lifecycle Engine interpreta cada decisión y ejecuta la política correspondiente.

---

# ALLOW

No se aplica ninguna sanción.

La reputación permanece registrada.

La dirección IP continúa siendo monitorizada.

---

# WATCH

La dirección IP permanece bajo observación.

No se modifica el Firewall.

La reputación continúa evolucionando.

---

# FILTER

Se aplican medidas preventivas definidas por la política activa.

La implementación depende del Backend utilizado.

---

# TEMP_BAN

Se aplica una sanción temporal.

La duración depende de:

- política;
- categoría;
- reputación;
- reincidencia.

Al finalizar la sanción la dirección IP vuelve a ser evaluada por ARE.

La expiración de un bloqueo no elimina la reputación acumulada.

---

# BAN

Se aplica una sanción permanente o de larga duración.

Su eliminación requiere una decisión explícita del administrador o una política específica de recuperación.

---

# Reincidencia

La reincidencia constituye uno de los factores considerados por el Policy Engine.

Una dirección IP que acumula múltiples sanciones podrá evolucionar hacia respuestas más restrictivas.

El Ban Lifecycle Engine únicamente ejecuta dicha evolución.

---

# Recuperación

Una dirección IP puede abandonar un estado restrictivo únicamente cuando las políticas así lo permitan.

La recuperación nunca implica eliminar automáticamente:

- historial;
- reputación;
- eventos registrados.

---

# Persistencia

Toda la información necesaria para administrar el ciclo de vida permanece almacenada de forma persistente mediante SQLite.

Entre otros elementos:

- reputación;
- estados;
- eventos;
- historial de sanciones;
- configuración.

---

# Relación con otros motores

El Ban Lifecycle Engine depende de la salida generada por:

- Sensor Framework;
- Reputation Engine;
- State Engine;
- Policy Engine.

Nunca sustituye las responsabilidades de dichos componentes.

---

# Firewall Backend

El Ban Lifecycle Engine nunca interactúa directamente con el Firewall.

Toda modificación del sistema operativo se realiza exclusivamente a través del Firewall Backend.

Actualmente:

- IPSet
- iptables
- ip6tables

La incorporación de nuevos Backends no modifica el comportamiento del Ban Lifecycle Engine.

---

# Filosofía

Las sanciones representan una consecuencia del comportamiento histórico observado y no únicamente del último evento recibido.

ARE prioriza respuestas consistentes, progresivas y basadas en evidencia antes que bloqueos aislados.

La evolución de una dirección IP constituye un proceso continuo administrado por el conjunto formado por el Reputation Engine, State Engine, Policy Engine y Ban Lifecycle Engine.
