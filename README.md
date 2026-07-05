# ARE - Abuse Reputation Engine

![License](https://img.shields.io/badge/license-GPLv3-blue.svg)

## Descripción

ARE (Abuse Reputation Engine) es un motor de reputación y decisión diseñado para complementar sistemas de detección como Fail2Ban y ModSecurity.

Su objetivo no es reemplazar estas herramientas, sino convertir los eventos de seguridad en decisiones inteligentes basadas en reputación acumulativa, estados de confianza y políticas configurables.

ARE analiza cada evento recibido, calcula el riesgo asociado a la dirección IP, mantiene un historial persistente y aplica automáticamente la respuesta definida por el motor de políticas mediante un backend desacoplado.

## Características

* Motor de reputación basado en categorías de ataque.
* State Engine (NEW, WATCH, FILTER y BANNED).
* Policy Engine configurable.
* Persistencia mediante SQLite.
* Soporte para IPv4 e IPv6.
* Backend desacoplado para aplicar acciones de firewall.
* Integración con Fail2Ban como fuente de eventos.
* Compatibilidad con ModSecurity (OWASP Core Rule Set).
* Dashboard para consulta de reputación y eventos.
* Arquitectura modular preparada para futuras ampliaciones.

## Arquitectura

```
             +------------------+
             |    ModSecurity   |
             +---------+--------+
                       |
                       v
             +------------------+
             |    Fail2Ban      |
             |  (Sensor Layer)  |
             +---------+--------+
                       |
                       v
             +------------------+
             |       ARE        |
             |------------------|
             | Reputation Engine|
             | State Engine     |
             | Policy Engine    |
             +---------+--------+
                       |
                       v
             +------------------+
             | Firewall Backend |
             +---------+--------+
                       |
                       v
               IPSet / Firewall
```

## Flujo de funcionamiento

1. Fail2Ban detecta un evento de seguridad.
2. El evento es enviado a ARE.
3. ARE identifica la categoría del ataque.
4. Se actualiza la reputación de la dirección IP.
5. El State Engine determina el estado actual.
6. El Policy Engine evalúa el riesgo.
7. El backend aplica la acción correspondiente sobre el firewall.
8. Toda la información queda registrada en SQLite.

## Categorías de eventos

* EXPLOIT
* RECON
* PROTOCOL
* CREDENTIAL
* ANOMALY

Cada categoría posee un peso y un nivel de confianza configurables para el cálculo de reputación.

## Componentes principales

* Reputation Engine
* State Engine
* Policy Engine
* Firewall Backend
* Dashboard
* SQLite Database

## Backend

La arquitectura desacopla el motor de decisión del mecanismo utilizado para aplicar las acciones.

La versión 1 utiliza IPSet como backend de referencia, permitiendo incorporar otros mecanismos en futuras versiones sin modificar el núcleo del sistema.

## Estado del proyecto

Versión estable **v1.0.0**

ARE v1 implementa el núcleo funcional del sistema de reputación y decisión automática para la protección de servidores Linux.

## Licencia

Este proyecto se distribuye bajo los términos de la licencia **GNU General Public License v3.0 (GPLv3)**.

