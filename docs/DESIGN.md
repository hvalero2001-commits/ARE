# ARE Design

## 1. Filosofía del proyecto

...

## 2. Principios de diseño

### Responsabilidad única

Cada módulo de ARE debe cumplir una única función.

### Modularidad

...

### Simplicidad

...

### Sensores

Los sensores constituyen la capa de observación de ARE.

Su única responsabilidad es transformar eventos generados por sistemas externos en eventos comprensibles para el motor de reputación.

Los sensores nunca toman decisiones de seguridad.

Toda decisión corresponde exclusivamente al Policy Engine.

## 3. Decisiones arquitectónicas

...

## 4. Convenciones

...

## 5. Evolución

...



## Ciclo de Vida de una Dirección IP

Cada dirección IP observada por ARE evoluciona a través de un ciclo de vida basado en su comportamiento.

## Modelo de Decisión Basado en Riesgo

ARE adopta un modelo de decisión basado en el comportamiento observado de cada dirección IP.

A diferencia de los mecanismos tradicionales, donde el tiempo de bloqueo es determinado previamente por una herramienta externa, ARE utiliza la reputación acumulada como criterio principal para decidir la respuesta.

Como consecuencia:

- El bloqueo deja de depender del tiempo y pasa a depender del riesgo.
- La respuesta evoluciona progresivamente según el comportamiento observado.
- La reputación se recupera de forma gradual cuando cesa la actividad maliciosa.
- La reincidencia incrementa progresivamente las medidas de contención.
- Una amenaza persistente puede finalizar en un bloqueo permanente cuando la reputación alcanza el nivel de riesgo definido por el administrador.

Este modelo permite que el ciclo completo de observación, evaluación, respuesta y recuperación sea administrado por ARE, manteniendo una política coherente y proporcional al riesgo real de cada dirección IP.

### 1. Observación

ARE recibe eventos desde uno o más sensores.

Ejemplos:

- ModSecurity
- Fail2Ban
- SSH
- Telnet
- Apache
- Otros sensores futuros

Los sensores únicamente reportan eventos. No toman decisiones sobre la respuesta final.

### 2. Reputación

Cada evento incrementa la reputación negativa de la IP según el perfil configurado para la jail correspondiente.

Cada perfil define:

- categoría
- peso
- confianza
- factor de decaimiento

### 3. Evaluación

El Policy Engine analiza:

- score acumulado
- estado actual
- historial
- categoría
- reglas configuradas

Como resultado determina la acción apropiada.

### 4. Respuesta

Las acciones posibles incluyen:

- ALLOW
- WATCH
- FILTER
- TEMP_BAN
- BAN

La decisión siempre pertenece a ARE.

### 5. Recuperación

Cuando una IP deja de generar actividad maliciosa, su reputación disminuye progresivamente mediante el mecanismo de decaimiento (Decay Engine).

La recuperación nunca es inmediata.

### 6. Reevaluación

Cada modificación del score provoca una nueva evaluación del riesgo.

Una IP podrá cambiar de estado únicamente como consecuencia de una nueva decisión del Policy Engine.

### 7. Liberación

La liberación de una IP será consecuencia de una decisión de ARE.

Los eventos externos de tipo `UNBAN` se consideran únicamente información adicional y no implican la eliminación automática del bloqueo.
