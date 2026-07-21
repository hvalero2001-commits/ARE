# ARE User Guide

## Introducción

Esta guía describe el uso cotidiano de ARE (Abuse Reputation Engine).

Está dirigida a administradores de sistemas responsables de operar, supervisar y mantener una instalación de ARE.

No explica la arquitectura interna del proyecto. Esa información se encuentra en la documentación técnica correspondiente.

---

# Requisitos

ARE debe encontrarse correctamente instalado y validado.

Verificar el estado mediante:

```bash
are-installer verify
```

Si la instalación es correcta, el resultado finalizará con:

```text
ARE está instalado correctamente.
```

---

# Comandos disponibles

ARE proporciona una interfaz de línea de comandos para consultar el estado del motor de reputación y administrar el sistema.

Comandos principales:

```text
are stats
are score <IP>
are events <IP>
are found <IP> <JAIL>

are-installer install
are-installer upgrade
are-installer repair
are-installer verify
are-installer uninstall
```

---

# Estadísticas

Mostrar información general del sistema.

```bash
are stats
```

La salida incluye información como:

- direcciones IP registradas;
- direcciones IP activas;
- IPs bloqueadas;
- categorías de reputación;
- actividad por Jail;
- estadísticas generales.

Este comando no modifica información del sistema.

---

# Consultar reputación

Mostrar la reputación de una dirección IP.

```bash
are score 192.168.1.10
```

La información incluye:

- score total;
- categorías;
- estado;
- historial de sanción;
- última actividad;
- información temporal;
- reputación acumulada.

---

# Consultar eventos

Mostrar el historial registrado para una dirección IP.

```bash
are events 192.168.1.10
```

Los eventos aparecen ordenados cronológicamente.

Cada registro representa evidencia utilizada por el Reputation Engine.

---

# Registrar un evento FOUND

Procesar manualmente un evento procedente de un Sensor.

```bash
are found 192.168.1.10 modsec-protocol
```

El comando:

- registra el evento;
- actualiza la reputación;
- recalcula el estado;
- ejecuta el Policy Engine;
- aplica la decisión correspondiente.

Su uso principal es:

- pruebas;
- validación;
- integración de sensores.

---

# Verificar la instalación

Comprobar la integridad del producto.

```bash
are-installer verify
```

Se validan automáticamente:

- estructura;
- manifiesto;
- permisos;
- enlaces;
- ejecutables;
- SQLite;
- Backend;
- Firewall;
- systemd;
- logrotate;
- runtime.

No modifica información del sistema.

---

# Reparar una instalación

Restaurar componentes faltantes.

```bash
are-installer repair
```

La operación reconstruye únicamente archivos distribuidos con ARE.

Nunca modifica:

- configuración;
- SQLite;
- reputación;
- eventos.

---

# Actualizar

Actualizar el producto.

```bash
are-installer upgrade
```

La actualización conserva automáticamente:

- configuración;
- base de datos;
- reputación;
- historial;
- registros.

---

# Desinstalar

Eliminar el producto.

```bash
are-installer uninstall
```

La desinstalación elimina únicamente los componentes distribuidos por ARE.

Se conservan:

- configuración;
- SQLite;
- reputación;
- historial;
- logs.

---

# Ubicaciones importantes

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

---

# Buenas prácticas

Se recomienda:

- verificar la instalación después de cada actualización;
- mantener copias de seguridad de SQLite;
- conservar la configuración bajo control de versiones;
- revisar periódicamente las estadísticas;
- supervisar los eventos registrados por los sensores.

---

# Solución de problemas

## Verificar instalación

```bash
are-installer verify
```

---

## Reparar componentes

```bash
are-installer repair
```

---

## Consultar reputación

```bash
are score <IP>
```

---

## Consultar eventos

```bash
are events <IP>
```

---

## Revisar estadísticas

```bash
are stats
```

---

# Flujo operativo recomendado

Durante la operación normal de ARE se recomienda seguir el siguiente flujo.

```text
Eventos
      │
      ▼
Reputación
      │
      ▼
Score
      │
      ▼
Estado
      │
      ▼
Decisión
      │
      ▼
Firewall
```

La administración diaria se basa principalmente en los comandos:

- `are stats`
- `are score`
- `are events`

El Installer Engine sólo interviene durante tareas de mantenimiento.

---

# Compatibilidad

Versión soportada:

```text
ARE v1.1
```

Esta guía corresponde exclusivamente a la versión estable del proyecto.

---

# Referencias

Para obtener información adicional consultar:

- README.md
- PROJECT.md
- PHILOSOPHY.md
- ARCHITECTURE.md
- INSTALL.md
- CHANGELOG.md

La documentación técnica complementa esta guía y describe el funcionamiento interno del proyecto.
