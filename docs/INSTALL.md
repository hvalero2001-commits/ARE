# ARE Installation Guide

## Introducción

Este documento describe el ciclo de vida completo de la instalación de ARE (Abuse Reputation Engine).

El Installer Engine administra la instalación, actualización, reparación, validación y desinstalación del producto mediante un único núcleo reutilizable.

Su objetivo es mantener instalaciones consistentes, preservar la configuración del administrador y garantizar la integridad del sistema durante toda la vida útil del software.

---

# Requisitos

## Sistema operativo

- Linux

## Dependencias

- Bash 4.x o superior
- SQLite 3
- IPSet
- iptables
- ip6tables
- systemd

## Integraciones soportadas

- Fail2Ban
- ModSecurity

## Permisos

Todas las operaciones del Installer requieren privilegios de administrador.

---

# Distribución del producto

## Core

```text
/opt/f2b-ipset
```

Contiene exclusivamente el código fuente distribuido con ARE.

Nunca almacena información persistente.

---

## Configuración

```text
/etc/f2b-ipset
```

Contiene:

- config.conf
- policy.conf
- whitelist.conf

Estos archivos pertenecen al administrador.

Nunca son sobrescritos automáticamente durante `upgrade` ni `repair`.

---

## Datos persistentes

```text
/var/lib/f2b-ipset
```

Contiene:

- SQLite
- reputación
- eventos
- estados
- configuración persistente

---

## Logs

```text
/var/log/are
```

Contiene:

- are.log

---

## Ejecutables

```text
/usr/local/sbin
```

Enlaces oficiales:

```text
are
are-installer
are-fail2ban-sensor
```

---

## systemd

```text
/etc/systemd/system
```

Unidades oficiales:

- are-fail2ban-found.service
- are-fail2ban-found.timer

---

## Logrotate

```text
/etc/logrotate.d/are
```

---

# Estados de instalación

El Installer Engine determina automáticamente el estado del producto.

Estados posibles:

## NEW

ARE no se encuentra instalado.

Permite:

- install

---

## INSTALLED

La instalación es válida.

Permite:

- verify
- upgrade
- uninstall

---

## INCOMPLETE

La instalación presenta archivos faltantes o inconsistencias.

Permite:

- repair

---

# Operaciones soportadas

## install

Realiza una instalación inicial.

Flujo:

```text
Detectar estado
        │
        ▼
Crear estructura
        │
        ▼
Instalar Core
        │
        ▼
Instalar configuración
        │
        ▼
Crear enlaces
        │
        ▼
Asignar permisos
        │
        ▼
Inicializar SQLite
        │
        ▼
Preparar logging
        │
        ▼
Instalar systemd
        │
        ▼
Instalar logrotate
        │
        ▼
Validación final
```

Si ARE ya está instalado la operación finaliza sin modificar el sistema.

---

## upgrade

Actualiza el Core del producto.

Conserva automáticamente:

- configuración;
- SQLite;
- reputación;
- eventos;
- logs.

Actualiza:

- código;
- documentación;
- scripts;
- servicios;
- enlaces;
- permisos;
- Installer.

Nunca sobrescribe la configuración persistente.

---

## repair

Reconstruye una instalación incompleta.

Restaura únicamente los componentes faltantes.

Puede restaurar:

- Core;
- ejecutables;
- enlaces;
- permisos;
- servicios;
- logrotate;
- archivos del paquete.

Nunca modifica:

- configuración;
- SQLite;
- reputación;
- eventos.

---

## verify

Realiza una validación completa.

Comprueba:

- integridad del Core;
- manifiesto;
- permisos;
- ejecutables;
- enlaces;
- SQLite;
- IPSet;
- Firewall;
- systemd;
- logrotate;
- runtime.

El resultado determina si la instalación se encuentra en estado:

- NEW;
- INSTALLED;
- INCOMPLETE.

---

## uninstall

Elimina exclusivamente los componentes distribuidos por ARE.

Elimina:

- Core;
- ejecutables;
- enlaces;
- unidades systemd;
- logrotate.

Conserva:

- configuración;
- SQLite;
- reputación;
- eventos;
- logs.

La eliminación de información persistente permanece bajo control exclusivo del administrador.

---

# Arquitectura del Installer Engine

```text
                are-installer
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼

    install        upgrade       repair

        └──────────────┬──────────────┘
                       ▼

               Installer Core

                       │

      verify_root()
      verify_dependencies()
      detect_state()
      create_directories()
      install_core()
      install_configuration()
      create_links()
      install_permissions()
      initialize_database()
      prepare_logging()
      install_systemd()
      install_logrotate()
      validate_installation()
```

Todas las operaciones reutilizan exactamente el mismo núcleo.

No existe lógica duplicada.

---

# Manifest del producto

El Installer Engine utiliza `manifest/product.sh` como definición oficial del paquete.

El Manifest centraliza:

- directorios;
- archivos;
- configuración;
- ejecutables;
- enlaces;
- unidades systemd;
- logrotate;
- exclusiones;
- datos persistentes.

Toda modificación del paquete deberá realizarse únicamente en el Manifest.

---

# Configuración

Las plantillas oficiales residen en:

```text
/opt/f2b-ipset/templates/config
```

Durante la instalación se copian a:

```text
/etc/f2b-ipset
```

Una vez creadas pasan a ser propiedad del administrador.

---

# Principios

El Installer Engine se rige por los siguientes principios:

- una única implementación por responsabilidad;
- operaciones idempotentes;
- reutilización del Installer Core;
- configuración persistente protegida;
- validación automática;
- recuperación segura;
- ausencia de lógica duplicada.

---

# Flujo recomendado

Instalación inicial:

```text
install
        │
        ▼
verify
```

Actualización:

```text
upgrade
        │
        ▼
verify
```

Recuperación:

```text
repair
        │
        ▼
verify
```

Desinstalación:

```text
uninstall
```

---

# Compatibilidad

Versión 1.1

- Linux
- SQLite
- IPSet
- iptables
- ip6tables
- systemd
- Fail2Ban
- ModSecurity
