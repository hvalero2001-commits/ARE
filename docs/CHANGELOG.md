# Changelog

## v1.0.1

Fecha: 2026-07-05

### Resumen

Primera versión de mantenimiento de ARE, enfocada en estabilización y corrección de errores detectados tras la puesta en producción de la versión 1.0.0.

---

### Correcciones

* Implementación completa del flujo **UNBAN**.
* Incorporación de `handle_unban()`.
* Incorporación de `apply_unban()`.
* Integración del backend IPSet para eliminación de direcciones IP.
* Corrección de funciones duplicadas en `infrastructure/ipset.sh`.
* Validación completa del ciclo **BAN → UNBAN** sobre servidor en producción.
* Se mantiene intacta la reputación, el historial y el estado de las IP durante el proceso de UNBAN.
* Reorganización de reglas del Policy Engine hacia `policy/rules/`.
* Corregida la inicialización duplicada del backend.

---

### Estado del sistema

Versión estable de mantenimiento.

Se completa el ciclo de vida operativo de una dirección IP dentro de ARE:

* BAN
* UNBAN
* Persistencia del historial
* Persistencia de reputación
* Separación completa entre el motor de decisión y el backend de firewall.

---

## v1.0.0

Fecha: 2026-07-05

### Resumen

Primera versión estable de ARE (Abuse / Reputation Engine), desplegada en entorno de producción.

---

### Funcionalidades principales

* Motor de políticas (Policy Engine) basado en reputación y estado
* Sistema de reputación de IP con acumulación por categorías
* State Engine (NEW / WATCH / FILTER / BANNED)
* Integración con backend de firewall mediante IPSet
* Soporte IPv4 e IPv6
* Persistencia de datos en SQLite
* Sistema de eventos históricos por IP
* Clasificación de tráfico en categorías:

  * EXPLOIT
  * RECON
  * PROTOCOL
  * CREDENTIAL
  * ANOMALY
* Integración con Fail2Ban como fuente de telemetría
* Backend de inicialización y bootstrap del sistema
* Sistema de logging estructurado
* Dashboard de estado y reputación

---

### Integraciones

* Fail2Ban (sensor de eventos)
* ModSecurity (OWASP CRS)
* IPSet (enforcement firewall layer)
* iptables / ip6tables

---

### Estado del sistema

Versión inicial estable en producción.

ARE v1.0.0 representa el núcleo funcional del sistema de reputación, capaz de:

* Recibir eventos de seguridad
* Calcular score por categoría
* Evaluar riesgo
* Tomar decisiones automáticas
* Aplicar acciones en firewall
* Mantener historial persistente

---

### Licencia

GPLv3

