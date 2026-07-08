# Changelog

Todos los cambios relevantes de ARE (Abuse Reputation Engine) serán documentados en este archivo.

El proyecto sigue un versionado basado en versiones estables.

---

# v1.1-dev

**Fecha:** 2026-07-07

## Resumen

Inicio del desarrollo de la rama v1.1, incorporando mejoras en el modelo de reputación, nuevos mecanismos de observación y mejoras operativas del Dashboard sin modificar la arquitectura principal de ARE.

## Nuevas funcionalidades

- Incorporación del primer Sensor oficial para eventos `FOUND` de Fail2Ban.
- Integración del sensor mediante `systemd` Timer.
- Incorporación de las categorías:
  - ANOMALY
  - MALWARE
  - DOS
  - SOCIAL
- Nuevo panel **TOP JAILS** dentro del Dashboard.
- Ampliación del Dashboard para mostrar todas las categorías de reputación.

## Correcciones

- Corrección de la categoría `ANOMALY` en el Reputation Engine.
- Corrección del cálculo de `total_score`.
- Corrección de `stats` para mostrar todas las categorías.
- Corrección de `score` para visualizar las nuevas categorías.
- Actualización de la creación inicial de la base de datos con las nuevas columnas de reputación.

## Arquitectura

- Se consolida el modelo oficial de categorías del Reputation Engine para la rama v1.x.
- Se incorpora la primera implementación del Sensor Framework mediante el sensor de eventos `FOUND` de Fail2Ban.
- El Dashboard incorpora información operacional basada en la tabla `events`, separando la actividad del sistema de la reputación acumulada.

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
