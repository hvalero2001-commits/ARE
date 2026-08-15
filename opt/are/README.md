# ARE - Abuse Reputation Engine

![License](https://img.shields.io/badge/license-GPLv3-blue.svg)

> **Comprender antes de responder.**

ARE (Abuse Reputation Engine) es un motor de reputación y decisión diseñado para analizar eventos de seguridad, construir reputación histórica y aplicar respuestas basadas en riesgo.

Su arquitectura separa la detección de eventos, el análisis de reputación, la evaluación de políticas y la aplicación de decisiones de seguridad.

## ¿Qué problema resuelve ARE?

Las herramientas de seguridad tradicionales reaccionan principalmente a los eventos que detectan. Un firewall bloquea, Fail2Ban aplica sanciones y ModSecurity detecta y bloquea solicitudes según sus propias reglas.

ARE incorpora una capa centralizada de reputación y decisión. Los eventos recibidos de los sensores generan evidencia asociada a una dirección IP, la cual permite construir una reputación histórica y determinar el estado y la respuesta correspondiente.

De esta forma, la decisión puede considerar el comportamiento acumulado de una dirección IP y no únicamente un evento aislado.

## Arquitectura General

ARE implementa una arquitectura modular basada en la separación de responsabilidades.

```text
+----------------------+
|      Sensores        |
|----------------------|
| Fail2Ban             |
| ModSecurity          |
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
|       Decisión       |
|----------------------|
| ALLOW                |
| WATCH                |
| FILTER               |
| BANNED               |
+----------------------+
```

La arquitectura permite incorporar sensores y mecanismos de respuesta manteniendo separados los componentes de detección, reputación, decisión y aplicación.

## Características Principales

Entre las capacidades actuales de ARE se encuentran:

* Motor de reputación basado en categorías de amenaza.
* Evaluación histórica del comportamiento de cada dirección IP.
* Motor de estados para el ciclo de vida de las IP.
* Policy Engine separado del mecanismo de detección.
* Framework de sensores.
* Sensor de integración con Fail2Ban.
* Persistencia mediante SQLite.
* Dashboard operativo para reputación, eventos y estadísticas.
* Backend de firewall basado en IPSet, IPTables e IP6Tables.
* Integración con ModSecurity y Fail2Ban.
* Soporte para IPv4 e IPv6.
* Decay de reputación.
* Gestión de sanciones.
* Installer Engine para instalación y mantenimiento.

Las categorías de reputación utilizadas actualmente son:

| Categoría  | Descripción                                        |
| ---------- | -------------------------------------------------- |
| RECON      | Actividades de reconocimiento y exploración.       |
| EXPLOIT    | Intentos de explotación de vulnerabilidades.       |
| CREDENTIAL | Ataques contra credenciales y autenticación.       |
| PROTOCOL   | Violaciones o anomalías del protocolo.             |
| BOT        | Actividad automatizada identificada.               |
| ANOMALY    | Comportamientos anómalos o no clasificados.        |
| MALWARE    | Actividad relacionada con software malicioso.      |
| DOS        | Ataques de denegación de servicio.                 |
| SOCIAL     | Eventos asociados a técnicas de ingeniería social. |

## Estado del Proyecto

### Versión

**ARE v1.1.0**

La versión 1.1 incorpora el Installer Engine, el Sensor Framework, la ampliación del modelo de reputación, la gestión de sanciones y mejoras en los mecanismos de reputación y mantenimiento.

## Instalación

### Requisitos

ARE está diseñado para ejecutarse sobre sistemas GNU/Linux.

Requisitos:

* Bash.
* SQLite 3.
* IPSet.
* IPTables.
* IP6Tables.
* systemd.

Fail2Ban y ModSecurity pueden actuar como fuentes de eventos según la integración configurada.

### Instalación

El Installer Engine utiliza `manifest/product.sh` como definición de los componentes administrados.

La instalación se ejecuta desde un árbol fuente separado de la instalación activa:

```bash
are-installer install
```

La instalación crea y configura los componentes de ARE en sus ubicaciones correspondientes.

Después de instalar, verificar:

```bash
are-installer verify
```

## Uso

La interfaz oficial de ARE es:

```bash
are
```

### Estadísticas

```bash
are stats
```

### Top de amenazas

```bash
are top
```

### Consultar reputación

```bash
are score <IP>
```

Ejemplo:

```bash
are score 192.168.1.10
```

### Consultar eventos

```bash
are events <IP>
```

### Procesar un evento FOUND

```bash
are found <IP> <JAIL>
```

Ejemplo:

```bash
are found 192.168.1.10 modsec-protocol
```

### Gestionar un UNBAN

```bash
are unban <IP>
```

### Procesar un UNBAN externo

```bash
are external-unban <IP> [JAIL]
```

Si no se especifica el Jail, ARE utiliza `fail2ban`.

### Decay

Simular el decay sin modificar la reputación:

```bash
are decay-dry-run
```

Aplicar el decay:

```bash
are decay-apply
```

## Installer Engine

El Installer Engine administra el ciclo de vida de la instalación.

### Verificar

```bash
are-installer verify
```

### Actualizar

```bash
are-installer upgrade
```

### Reparar

```bash
are-installer repair
```

### Desinstalar

```bash
are-installer uninstall
```

Las operaciones de mantenimiento utilizan el Manifest del producto como referencia de los componentes administrados.

## Ubicaciones principales

Core:

```text
/opt/f2b-ipset
```

Configuración:

```text
/etc/f2b-ipset
```

Base de datos:

```text
/var/lib/f2b-ipset
```

Logs:

```text
/var/log/are
```

Ejecutables:

```text
/usr/local/sbin
```

## Documentación

| Documento              | Descripción                                     |
| ---------------------- | ----------------------------------------------- |
| `README.md`            | Presentación general y uso básico del proyecto. |
| `docs/USER_GUIDE.md`   | Guía de operación y administración.             |
| `docs/ARCHITECTURE.md` | Arquitectura y componentes del sistema.         |
| `docs/DESIGN.md`       | Principios y decisiones de diseño.              |
| `docs/ROADMAP.md`      | Evolución planificada del proyecto.             |
| `docs/CHANGELOG.md`    | Historial de versiones y cambios.               |
| `docs/DEVELOPMENT.md`  | Metodología de desarrollo.                      |
| `docs/CONTRIBUTING.md` | Guía para colaboradores.                        |
| `docs/GOVERNANCE.md`   | Gobierno y evolución del proyecto.              |
| `docs/SECURITY.md`     | Seguridad y gestión de vulnerabilidades.        |

## Licencia

ARE se distribuye bajo los términos de la **GNU General Public License v3.0 (GPL-3.0)**.

Consulte `LICENSE` para obtener el texto completo de la licencia.

## Filosofía del Proyecto

ARE fue concebido bajo un principio fundamental:

> **Comprender antes de responder.**

La seguridad no debe depender de decisiones aisladas ni de eventos individuales. Cada dirección IP construye una reputación basada en su comportamiento, permitiendo que las respuestas sean proporcionales al riesgo observado.

ARE no pretende reemplazar las herramientas de seguridad existentes. Su propósito es complementarlas mediante un motor centralizado de reputación y decisión capaz de transformar eventos independientes en respuestas basadas en el riesgo acumulado.
