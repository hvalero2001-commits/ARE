# ARE User Guide

## Introducción

Esta guía describe el uso operativo de ARE (Abuse Reputation Engine).

Está dirigida a administradores responsables de operar, supervisar y mantener una instalación de ARE v1.1.

---

# Requisitos

ARE debe encontrarse instalado y validado.

Verificar la instalación mediante:

```bash
are-installer verify
```

---

# Interfaz de comandos

La interfaz oficial de ARE se encuentra disponible mediante el comando:

```bash
are
```

Comandos operativos:

```text
are stats
are top
are score <IP>
are events <IP>
are found <IP> <JAIL>
are ban <IP> <JAIL>
are unban <IP>
are external-unban <IP> [JAIL]
are autoban
are decay-dry-run
are decay-apply
```

El Installer Engine utiliza el comando:

```text
are-installer
```

con las siguientes operaciones:

```text
are-installer install
are-installer upgrade
are-installer repair
are-installer verify
are-installer uninstall
```

---

# Estadísticas

Mostrar información general del sistema:

```bash
are stats
```

La información incluye:

* IPs registradas;
* IPs activas;
* IPs baneadas;
* eventos totales;
* eventos del día;
* score promedio;
* IPs candidatas para decay;
* actividad por categoría;
* principales Jails.

El comando es de consulta y no modifica la reputación.

---

# Top de amenazas

Mostrar las principales IPs según su reputación:

```bash
are top
```

La salida presenta las IPs con mayor score y parte de su composición de reputación.

---

# Consultar reputación

Consultar la reputación de una dirección IP:

```bash
are score <IP>
```

Ejemplo:

```bash
are score 192.168.1.10
```

La información incluye:

* reputación por categoría;
* score total;
* nivel de amenaza;
* último evento;
* última actividad;
* antigüedad;
* estado de sanción;
* nivel de sanción;
* cantidad de sanciones;
* última sanción;
* último unban.

---

# Consultar eventos

Consultar los eventos registrados para una dirección IP:

```bash
are events <IP>
```

Ejemplo:

```bash
are events 192.168.1.10
```

Los eventos representan la actividad registrada por ARE para la dirección consultada.

---

# Procesar un evento FOUND

Procesar manualmente un evento procedente de un sensor:

```bash
are found <IP> <JAIL>
```

Ejemplo:

```bash
are found 192.168.1.10 modsec-protocol
```

ARE:

1. registra la evidencia;
2. obtiene el perfil del Jail;
3. calcula el score correspondiente;
4. actualiza la reputación;
5. recalcula el estado;
6. evalúa la política;
7. aplica la decisión;
8. registra el evento.

---

# Ban

Procesar un evento de ban:

```bash
are ban <IP> <JAIL>
```

El Jail determina el perfil utilizado para calcular el score y la categoría de reputación.

ARE actualiza la reputación, recalcula el estado, evalúa la política y aplica la decisión correspondiente.

---

# Unban

Eliminar una sanción activa para una dirección IP:

```bash
are unban <IP>
```

ARE determina automáticamente el backend correspondiente para IPv4 o IPv6 y registra el evento `UNBAN`.

---

# Unban externo

Procesar un unban generado externamente:

```bash
are external-unban <IP> [JAIL]
```

Si no se especifica un Jail, se utiliza:

```text
fail2ban
```

El evento se registra como `EXTERNAL_UNBAN` y ARE vuelve a evaluar el estado y la política de la dirección IP.

---

# Autoban

Ejecutar el mecanismo de enforcement automático:

```bash
are autoban
```

---

# Decay

### Simulación

Consultar qué IPs son candidatas para decay sin aplicar modificaciones:

```bash
are decay-dry-run
```

### Aplicación

Aplicar el decay sobre las IPs que cumplen las condiciones configuradas:

```bash
are decay-apply
```

El proceso reduce proporcionalmente los scores de reputación que cumplen los criterios de antigüedad establecidos.

Después de aplicar el decay, ARE recalcula el estado y vuelve a evaluar la política.

---

# Verificar la instalación

Comprobar el estado de la instalación:

```bash
are-installer verify
```

La validación comprueba los componentes administrados por ARE, incluyendo:

* integridad;
* enlaces;
* comandos;
* permisos;
* base de datos;
* runtime;
* firewall;
* systemd;
* logrotate.

La operación es de verificación y no constituye una actualización del producto.

---

# Reparar

Reparar una instalación detectada como incompleta:

```bash
are-installer repair
```

La operación reconstruye los componentes administrados por el Installer.

La configuración persistente y los datos de la instalación no forman parte de los archivos distribuidos del Core.

---

# Actualizar

Actualizar una instalación existente:

```bash
are-installer upgrade
```

El Installer reutiliza el mismo núcleo de instalación y conserva los componentes persistentes de la instalación, incluyendo la configuración y la base de datos.

---

# Instalar

Instalar ARE desde un árbol fuente:

```bash
are-installer install
```

La instalación debe ejecutarse desde un árbol fuente diferente de la instalación activa.

La instalación crea los directorios, archivos, configuración, enlaces, base de datos, unidades systemd y configuración de logrotate definidos por el Manifest.

---

# Desinstalar

Eliminar ARE:

```bash
are-installer uninstall
```

La operación elimina los componentes administrados por el Installer según el modelo definido por el producto.

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

Datos:

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

# Whitelist

ARE permite definir direcciones IP que no deben recibir sanciones.

La whitelist se administra mediante:

/etc/f2b-ipset/whitelist.conf

El archivo utiliza una dirección IP por línea. Se admiten direcciones IPv4 e IPv6.

Una IP incluida en la whitelist queda excluida de la aplicación de sanciones. ARE verifica la whitelist antes de procesar acciones que puedan generar un bloqueo.

Las IPs whitelistadas pueden seguir apareciendo como fuente de eventos o ser consultadas mediante el dashboard. La whitelist no elimina información de reputación existente.

Si una IP whitelistada no posee un registro de reputación, `are score <IP>` muestra:

```text
Estado................ WHITELIST
Reputación............ Sin datos
```

---

# Flujo operativo

El flujo general de ARE es:

```text
Evento
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
Policy Engine
   │
   ▼
Decisión
   │
   ▼
Firewall
```

Las consultas operativas principales son:

```bash
are stats
are top
are score <IP>
are events <IP>
```

Las operaciones de mantenimiento se realizan mediante:

```bash
are-installer verify
are-installer repair
are-installer upgrade
are-installer uninstall
```

---

# Buenas prácticas

* Verificar la instalación después de cambios de mantenimiento.
* Mantener copias de seguridad de la base de datos.
* Mantener protegida la configuración de ARE.
* Revisar periódicamente las estadísticas y eventos.
* Supervisar los sensores y las decisiones aplicadas por ARE.

---

# Solución de problemas

### Verificar instalación

```bash
are-installer verify
```

### Reparar instalación incompleta

```bash
are-installer repair
```

### Consultar una IP

```bash
are score <IP>
```

### Consultar eventos

```bash
are events <IP>
```

### Consultar estadísticas

```bash
are stats
```

---

# Compatibilidad

Versión:

```text
ARE v1.1
```

Esta guía corresponde a la versión 1.1 del producto.

---

# Referencias

Para información adicional consultar:

* `README.md`
* `docs/ARCHITECTURE.md`
* `docs/DESIGN.md`
* `docs/INSTALL.md`
* `docs/CHANGELOG.md`

La documentación técnica complementa esta guía con información sobre arquitectura, diseño, instalación y evolución del proyecto.
