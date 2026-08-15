# ARE Design

## Introducción

Este documento define los principios de diseño utilizados durante el desarrollo de ARE (Abuse Reputation Engine).

Su propósito es garantizar que todas las decisiones de implementación mantengan una arquitectura coherente y modular.

Las decisiones de diseño complementan la arquitectura del proyecto y sirven como referencia para el desarrollo de nuevas funcionalidades.

---

# Filosofía del proyecto

ARE fue diseñado bajo un principio fundamental:

> **Comprender antes de responder.**

Las decisiones de seguridad no deben depender de un único evento sino del comportamiento histórico observado.

La arquitectura separa:

* observación;
* evaluación;
* decisión;
* ejecución.

Esta separación permite que cada componente mantenga una responsabilidad definida.

---

# Principios de diseño

## Responsabilidad única

Cada componente implementa una responsabilidad claramente definida.

Ejemplos:

* Sensor Framework observa.
* Reputation Engine gestiona la reputación.
* State Engine determina estados.
* Policy Engine decide.
* Firewall Backend ejecuta las acciones sobre el sistema.
* Installer Engine administra el ciclo de vida del producto.

---

## Modularidad

ARE está compuesto por módulos independientes.

La incorporación de nuevos componentes debe minimizar las modificaciones sobre el resto del sistema.

---

## Bajo acoplamiento

Los motores dependen de interfaces y funciones claramente definidas.

La implementación interna de un componente debe mantenerse separada de las responsabilidades de los demás.

---

## Alta cohesión

Cada módulo agrupa únicamente funciones relacionadas con una misma responsabilidad.

---

## Simplicidad

Se priorizan soluciones simples antes que implementaciones innecesariamente complejas.

Las funciones pequeñas y reutilizables tienen preferencia sobre bloques monolíticos.

---

## Configuración desacoplada

La configuración del entorno reside fuera del Core.

Ubicación oficial:

```text
/etc/f2b-ipset
```

El código distribuido no debe contener parámetros específicos del entorno.

---

## Persistencia

ARE mantiene de forma persistente la información necesaria para gestionar la reputación, los estados y los eventos.

Se diferencian:

* configuración;
* reputación;
* estados;
* eventos;
* información asociada al ciclo de sanciones.

---

# Sensor Framework

Los sensores constituyen la capa de observación del sistema.

Su responsabilidad consiste en transformar eventos externos al formato interno utilizado por ARE.

El sensor de Fail2Ban actualmente implementado procesa:

* `FOUND`;
* `EXTERNAL_UNBAN`.

El procesamiento del sensor puede ejecutarse en modo de simulación (`--dry-run`) o ejecución (`--execute`).

La arquitectura permite incorporar nuevos sensores sin modificar el núcleo de ARE.

---

# Modelo de decisión

ARE utiliza la reputación y el estado de una dirección IP como entradas para la evaluación de políticas.

El flujo principal considera:

* reputación acumulada;
* estado actual;
* política configurada.

El resultado de la evaluación determina la acción que será aplicada.

Las decisiones implementadas incluyen:

* `ALLOW`;
* `WATCH`;
* `FILTER`;
* `TEMP_BAN`;
* `BAN`.

---

# Ciclo de vida de una dirección IP

## 1. Observación

Los sensores reciben eventos desde sistemas externos.

El Sensor Framework transforma los eventos admitidos al flujo interno de ARE.

Actualmente se encuentra implementado el sensor de Fail2Ban.

---

## 2. Reputación

Cada evento `FOUND` procesado por el flujo de ARE puede generar una modificación de la reputación de la dirección IP.

El perfil asociado al jail determina:

* peso;
* confianza;
* categoría.

La puntuación resultante se incorpora a la reputación persistente de la dirección IP.

---

## 3. Estado

El State Engine determina el estado operativo de la dirección IP en función de su puntuación.

Estados implementados:

* `NEW`;
* `WATCH`;
* `FILTER`;
* `BANNED`.

---

## 4. Evaluación

El Policy Engine recibe:

* puntuación total;
* estado actual.

A partir de estos valores genera una decisión.

---

## 5. Respuesta

Las decisiones implementadas son:

* `ALLOW`;
* `WATCH`;
* `FILTER`;
* `TEMP_BAN`;
* `BAN`.

La aplicación de estas decisiones corresponde al flujo de Policy Apply y al Backend utilizado por ARE.

---

## 6. Sanciones temporales

Cuando la decisión es `TEMP_BAN`, el flujo de aplicación consulta el Ban Lifecycle Engine.

El Ban Lifecycle Engine determina el nivel de sanción siguiente y la duración correspondiente según la configuración disponible.

La información del ciclo de sanción se almacena de forma persistente.

---

## 7. Persistencia

La reputación, los estados y los eventos permanecen registrados en SQLite.

La aplicación de una sanción no elimina automáticamente la reputación histórica de la dirección IP.

---

# Installer Engine

El Installer Engine constituye un componente independiente de la arquitectura.

Sus operaciones comprenden:

* instalación;
* actualización;
* reparación;
* validación;
* desinstalación.

El Installer Engine utiliza el Manifest del producto como referencia de los componentes administrados por el instalador.

---

# Evolución

Toda nueva funcionalidad deberá respetar los principios definidos en este documento.

La evolución del proyecto deberá favorecer:

* extensión antes que modificación;
* reutilización antes que duplicación;
* estabilidad antes que complejidad.

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
