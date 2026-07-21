# ARE Design

## Introducción

Este documento define los principios de diseño utilizados durante el desarrollo de ARE (Abuse Reputation Engine).

Su propósito es garantizar que todas las decisiones de implementación mantengan una arquitectura coherente, modular y preparada para evolucionar sin introducir deuda técnica.

Las decisiones de diseño complementan la arquitectura del proyecto y sirven como referencia para el desarrollo de nuevas funcionalidades.

---

# Filosofía del proyecto

ARE fue diseñado bajo un principio fundamental:

> **Comprender antes de responder.**

Las decisiones de seguridad no deben depender de un único evento sino del comportamiento histórico observado.

La arquitectura separa completamente:

- observación;
- evaluación;
- decisión;
- ejecución.

Esta separación permite que cada componente evolucione de forma independiente.

---

# Principios de diseño

## Responsabilidad única

Cada componente implementa una única responsabilidad claramente definida.

Ejemplos:

- Sensor Framework observa.
- Reputation Engine calcula reputación.
- State Engine determina estados.
- Policy Engine decide.
- Firewall Backend ejecuta.
- Installer Engine administra el ciclo de vida del producto.

---

## Modularidad

ARE está compuesto por módulos independientes.

La incorporación de nuevos componentes no requiere modificar el resto del sistema.

---

## Bajo acoplamiento

Los motores sólo dependen de interfaces claramente definidas.

La implementación interna de un componente no afecta a los demás.

---

## Alta cohesión

Cada módulo agrupa únicamente funciones relacionadas con una misma responsabilidad.

---

## Simplicidad

Se priorizan soluciones simples antes que implementaciones complejas.

Las funciones pequeñas y reutilizables tienen preferencia sobre bloques monolíticos.

---

## Configuración desacoplada

Toda configuración reside fuera del Core.

Ubicación oficial:

```text
/etc/f2b-ipset
```

El código distribuido nunca contiene parámetros específicos del entorno.

---

## Persistencia

Toda la información necesaria para la toma de decisiones permanece almacenada de forma persistente.

ARE diferencia claramente entre:

- configuración;
- reputación;
- estados;
- eventos.

---

# Sensor Framework

Los sensores constituyen la capa de observación del sistema.

Su única responsabilidad consiste en transformar eventos externos al formato interno utilizado por ARE.

Los sensores nunca:

- modifican reputación;
- cambian estados;
- aplican bloqueos;
- ejecutan acciones.

Actualmente se implementa:

- Fail2Ban Sensor (`FOUND`).

La arquitectura permite incorporar nuevos sensores sin modificar el núcleo.

---

# Modelo de decisión

ARE adopta un modelo de decisión basado en riesgo.

Las respuestas no dependen únicamente del tiempo de bloqueo ni del último evento recibido.

Cada decisión considera:

- reputación acumulada;
- estado actual;
- historial;
- políticas configuradas.

El resultado puede evolucionar progresivamente conforme cambia el comportamiento observado.

---

# Ciclo de vida de una dirección IP

## 1. Observación

Los sensores reciben eventos desde sistemas externos.

Ejemplos:

- Fail2Ban;
- ModSecurity;
- SSH;
- Apache;
- futuros sensores.

---

## 2. Reputación

Cada evento incrementa la reputación según el perfil configurado.

Cada perfil define:

- categoría;
- peso;
- confianza;
- decaimiento.

---

## 3. Estado

El State Engine determina el estado operativo de la dirección IP.

Estados actuales:

- NEW;
- WATCH;
- FILTER;
- BANNED.

---

## 4. Evaluación

El Policy Engine analiza:

- reputación;
- estado;
- historial;
- políticas.

Como resultado genera una decisión.

---

## 5. Respuesta

Las decisiones disponibles son:

- ALLOW;
- WATCH;
- FILTER;
- TEMP_BAN;
- BAN.

La ejecución corresponde exclusivamente al Firewall Backend.

---

## 6. Recuperación

La reputación disminuye progresivamente mediante el mecanismo de decaimiento.

La recuperación nunca elimina automáticamente:

- reputación;
- historial;
- eventos.

---

## 7. Reevaluación

Cada modificación relevante provoca una nueva evaluación del riesgo.

Una dirección IP puede cambiar de estado únicamente como consecuencia de una nueva decisión del Policy Engine.

---

# Installer Engine

El Installer Engine constituye un componente independiente de la arquitectura.

Responsabilidades:

- instalación;
- actualización;
- reparación;
- validación;
- desinstalación.

Todas las operaciones reutilizan un único Installer Core.

El Installer protege automáticamente:

- configuración;
- datos persistentes;
- historial.

---

# Evolución

Toda nueva funcionalidad deberá respetar los principios definidos en este documento.

La evolución del proyecto deberá favorecer:

- extensión antes que modificación;
- reutilización antes que duplicación;
- estabilidad antes que complejidad.

---

# Principios finales

Las decisiones de diseño de ARE se resumen en los siguientes principios:

1. Una responsabilidad por componente.
2. Arquitectura antes que implementación.
3. Configuración desacoplada.
4. Persistencia del conocimiento.
5. Separación entre decisión y ejecución.
6. Reutilización del código.
7. Evolución incremental.
8. Estabilidad como prioridad.
9. Documentación sincronizada con el código.
10. Ausencia de lógica duplicada.
