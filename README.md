# ARE - Abuse Reputation Engine

![License](https://img.shields.io/badge/license-GPLv3-blue.svg)

> **Comprender antes de responder.**

ARE (Abuse Reputation Engine) es un motor de reputación y decisión diseñado para analizar eventos de seguridad, construir reputación histórica y aplicar respuestas inteligentes basadas en riesgo.

Su arquitectura permite integrar múltiples fuentes de eventos, centralizar el análisis del comportamiento de las amenazas y desacoplar completamente la detección de la toma de decisiones.

Actualmente ARE utiliza herramientas como Fail2Ban y ModSecurity como sensores de eventos, mientras que el motor de reputación, el estado de las direcciones IP y las políticas de respuesta son administradas por ARE.

## ¿Qué problema resuelve ARE?

Las soluciones tradicionales de seguridad reaccionan de forma independiente ante los eventos que detectan. Un firewall bloquea, Fail2Ban aplica un ban temporal y ModSecurity protege las aplicaciones web, pero cada componente toma decisiones basadas únicamente en su propia información.

ARE incorpora una capa de inteligencia sobre estos sistemas. Su función es observar los eventos generados por múltiples sensores, construir una reputación histórica para cada dirección IP y aplicar políticas de respuesta basadas en el comportamiento acumulado y no únicamente en un evento aislado.

Este enfoque permite tomar decisiones más consistentes, reducir falsos positivos y adaptar la respuesta de seguridad según el nivel real de riesgo.

## Arquitectura General

ARE implementa una arquitectura modular basada en la separación de responsabilidades.

Cada componente cumple una función específica dentro del proceso de análisis y respuesta:

```text
+----------------------+
|      Sensores        |
|----------------------|
| Fail2Ban             |
| ModSecurity          |
| SSH                  |
| Otros                |
+----------+-----------+
           |
           v
+----------------------+
| Abuse Reputation     |
| Engine (ARE)         |
|----------------------|
| Reputation Engine    |
| State Engine         |
| Policy Engine        |
+----------+-----------+
           |
           v
+----------------------+
| Firewall Backend     |
|----------------------|
| IPSet                |
| IPTables             |
| IP6Tables            |
+----------+-----------+
           |
           v
+----------------------+
| Acción               |
|----------------------|
| ALLOW                |
| WATCH                |
| FILTER               |
| BANNED               |
+----------------------+
```

Esta arquitectura desacopla completamente la detección de amenazas de la toma de decisiones, permitiendo incorporar nuevos sensores o mecanismos de respuesta sin modificar el núcleo del sistema.

## Características Principales

ARE ha sido diseñado para evolucionar de forma modular, permitiendo incorporar nuevos sensores, motores de decisión y mecanismos de respuesta sin modificar su arquitectura principal.

Entre sus capacidades actuales se encuentran:

- Motor de reputación basado en categorías de amenaza.
- Evaluación histórica del comportamiento de cada dirección IP.
- Motor de estados para el ciclo de vida de las IP.
- Policy Engine desacoplado del mecanismo de detección.
- Framework de sensores para integración con múltiples fuentes de eventos.
- Backend de firewall independiente del motor de decisión.
- Persistencia mediante SQLite.
- Dashboard operativo para consulta de reputación, eventos y estadísticas.
- Integración con Fail2Ban y ModSecurity.
- Soporte para IPv4 e IPv6.
- Arquitectura modular preparada para futuras ampliaciones.

Actualmente ARE clasifica los eventos en las siguientes categorías de reputación:

| Categoría | Descripción |
|-----------|-------------|
| RECON | Actividades de reconocimiento y exploración. |
| EXPLOIT | Intentos de explotación de vulnerabilidades. |
| CREDENTIAL | Ataques contra credenciales y autenticación. |
| PROTOCOL | Violaciones o anomalías del protocolo. |
| BOT | Actividad automatizada identificada. |
| ANOMALY | Comportamientos anómalos o no clasificados. |
| MALWARE | Actividad relacionada con software malicioso. |
| DOS | Ataques de denegación de servicio. |
| SOCIAL | Eventos asociados a técnicas de ingeniería social. |

## Estado del Proyecto

ARE evoluciona mediante versiones incrementales, priorizando la estabilidad del núcleo antes de incorporar nuevas capacidades.

### Versión estable

**v1.0.x**

Incluye el núcleo funcional del proyecto:

- Reputation Engine.
- State Engine.
- Policy Engine.
- Firewall Backend.
- Persistencia SQLite.
- Dashboard operativo.
- Integración con ModSecurity y Fail2Ban.

### Rama de desarrollo

**v1.1-dev**

La rama actual incorpora mejoras compatibles con la arquitectura existente, entre ellas:

- Sensor Framework.
- Sensor Fail2Ban (`FOUND`).
- Cursor persistente para sensores.
- Ejecución automática mediante `systemd timer`.
- Ampliación del modelo de categorías de reputación.
- Dashboard con estadísticas ampliadas y TOP JAILS.

El desarrollo de nuevas funcionalidades sigue una metodología incremental, donde cada bloque debe quedar completamente implementado, probado y documentado antes de considerarse finalizado.

## Instalación

### Requisitos

ARE está diseñado para ejecutarse sobre sistemas GNU/Linux.

Requisitos recomendados:

- Bash 4.x o superior.
- SQLite 3.
- IPSet.
- IPTables / IP6Tables.
- systemd.
- Fail2Ban (opcional).
- ModSecurity (opcional).

Las instrucciones de instalación y configuración se encuentran disponibles en la documentación del proyecto y evolucionan junto con cada versión estable.

## Uso Básico

ARE proporciona una interfaz de línea de comandos para consultar información de reputación, eventos y estadísticas del sistema.

### Ver estadísticas generales

```bash
./f2b-ipset.sh stats
```

### Consultar la reputación de una dirección IP

```bash
./f2b-ipset.sh score <IP>
```

Ejemplo:

```bash
./f2b-ipset.sh score 192.168.1.10
```

### Consultar el historial de eventos

```bash
./f2b-ipset.sh events <IP>
```

### Procesar un evento FOUND

```bash
./f2b-ipset.sh found <IP> <JAIL>
```

Ejemplo:

```bash
./f2b-ipset.sh found 192.168.1.10 modsec-protocol
```

Estas herramientas permiten consultar el estado del motor de reputación y verificar el comportamiento de ARE durante su funcionamiento.

## Documentación

ARE mantiene una documentación técnica organizada, donde cada documento posee una responsabilidad específica.

| Documento | Descripción |
|-----------|-------------|
| `README.md` | Presentación general del proyecto. |
| `docs/ARCHITECTURE.md` | Arquitectura general y componentes del sistema. |
| `docs/DESIGN.md` | Principios y decisiones de diseño. |
| `docs/ROADMAP.md` | Plan de evolución del proyecto. |
| `docs/CHANGELOG.md` | Historial de versiones y cambios. |
| `docs/TODO.md` | Gestión de tareas, bugs, RFC y nuevas funcionalidades. |
| `docs/DEVELOPMENT.md` | Metodología oficial de desarrollo. |
| `docs/CONTRIBUTING.md` | Guía para colaboradores. |
| `docs/GOVERNANCE.md` | Modelo de gobierno y evolución del proyecto. |
| `docs/SECURITY.md` | Política de seguridad y gestión de vulnerabilidades. |

## Licencia

ARE se distribuye bajo los términos de la licencia **GNU General Public License v3.0 (GPL-3.0)**.

Esto garantiza que el proyecto pueda ser utilizado, estudiado, modificado y redistribuido respetando las condiciones establecidas por dicha licencia.

Consulte el archivo `LICENSE` para obtener el texto completo de la licencia.

## Filosofía del Proyecto

ARE fue concebido bajo un principio fundamental:

> **Comprender antes de responder.**

La seguridad no debe depender de decisiones aisladas ni de eventos individuales. Cada dirección IP construye una reputación basada en su comportamiento, permitiendo que las respuestas sean proporcionales al riesgo observado.

El proyecto evoluciona mediante pequeñas mejoras incrementales, priorizando la estabilidad del núcleo, la modularidad de sus componentes y una arquitectura preparada para crecer sin perder coherencia.

Toda nueva funcionalidad es analizada, documentada y validada antes de incorporarse al proyecto, garantizando que cada versión represente un estado consistente y mantenible.

ARE no pretende reemplazar las herramientas de seguridad existentes. Su propósito es complementarlas, actuando como un motor central de reputación y decisión capaz de transformar eventos independientes en respuestas inteligentes.
