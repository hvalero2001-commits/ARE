# Changelog

Todos los cambios relevantes de ARE (Abuse Reputation Engine) serán documentados en este archivo.

El proyecto sigue un versionado basado en versiones estables.

---

# v1.0.1

**Fecha:** 2026-07-05

## Resumen

Primera actualización de mantenimiento de ARE centrada en estabilizar el núcleo del sistema y completar el ciclo de vida de las direcciones IP.

## Nuevas funcionalidades

- Implementación completa del flujo `UNBAN`.
- Integración del backend con IPSet para eliminación de direcciones IP.
- Reorganización del Policy Engine.
- Centralización de la inicialización del backend.
- Reorganización de la documentación del proyecto.

## Correcciones

- Corregida la ausencia de `handle_unban()`.
- Eliminada la doble inicialización de IPSet y Firewall.
- Limpieza y modularización del backend.

## Arquitectura

- Reorganización del módulo `policy/rules/`.
- Separación del proceso de inicialización del backend.

---

# v1.0.0

**Fecha:** 2026-07-05

## Resumen

Primera versión estable de ARE.

## Funcionalidades principales

- Reputation Engine.
- State Engine.
- Policy Engine.
- Firewall Backend basado en IPSet.
- Persistencia mediante SQLite.
- Dashboard.
- Integración con Fail2Ban.
- Integración con ModSecurity.
- Soporte IPv4 e IPv6.

## Estado

Versión inicial estable utilizada en producción.

---

## Licencia

GPL v3
