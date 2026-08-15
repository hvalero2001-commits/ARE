# ARE Development Guide

## Introducción

Este documento define la metodología de desarrollo de ARE (Abuse Reputation Engine).

Su objetivo es establecer un proceso controlado para realizar cambios sobre el proyecto, manteniendo la estabilidad del sistema, la coherencia de la arquitectura y la documentación sincronizada con el código.

La documentación forma parte del desarrollo y debe reflejar el estado real del proyecto.

---

# Filosofía

El desarrollo de ARE se basa en un principio fundamental:

> **Comprender antes de implementar.**

Antes de modificar código debe comprenderse el comportamiento existente y verificarse el impacto del cambio sobre los componentes involucrados.

No deberán realizarse modificaciones innecesarias sobre componentes que no formen parte del cambio.

---

# Objetivos

La metodología busca preservar:

* estabilidad del sistema;
* evolución incremental;
* arquitectura coherente;
* separación de responsabilidades;
* bajo acoplamiento;
* reutilización de componentes existentes;
* documentación sincronizada;
* trazabilidad de los cambios.

---

# Flujo de desarrollo

Los cambios deberán seguir un proceso controlado:

```text
Problema o necesidad
        │
        ▼
Análisis del comportamiento actual
        │
        ▼
Identificación del componente afectado
        │
        ▼
Definición del cambio
        │
        ▼
Implementación
        │
        ▼
Verificación
        │
        ▼
Actualización documental
        │
        ▼
Commit
```

Cada etapa debe completarse antes de considerar terminado el cambio.

---

# Desarrollo incremental

ARE evoluciona mediante cambios pequeños y verificables.

Antes de iniciar un cambio debe verificarse el comportamiento existente y determinar qué componentes están realmente involucrados.

No deberán modificarse archivos o componentes que no sean necesarios para resolver el problema o implementar el cambio correspondiente.

Cuando una modificación produzca un comportamiento incorrecto, el problema deberá resolverse y verificarse antes de continuar con otros cambios dependientes.

---

# Clasificación de cambios

Los cambios pueden clasificarse según su naturaleza.

## BUG

Corrección de un comportamiento incorrecto existente.

La corrección debe preservar las funcionalidades que no forman parte del problema.

---

## TASK

Trabajo técnico de mantenimiento, reorganización o documentación.

Debe mantenerse claramente definido el alcance del cambio.

---

## FEATURE

Incorporación de una nueva funcionalidad.

La funcionalidad debe integrarse respetando las responsabilidades de los componentes existentes.

---

## RFC

Propuesta de modificación arquitectónica.

Los cambios que alteren responsabilidades, interfaces o relaciones fundamentales entre componentes deben analizarse antes de su implementación.

---

## IDEA

Propuesta que todavía no forma parte de una implementación definida.

Una idea no representa por sí misma una funcionalidad implementada.

---

# Principios de implementación

## Responsabilidad única

Cada componente debe mantener una responsabilidad claramente definida.

Una modificación no debe trasladar responsabilidades entre componentes sin una razón arquitectónica verificable.

---

## Reutilización

Cuando exista una función o componente que ya resuelva una necesidad, deberá evaluarse su reutilización antes de crear una implementación duplicada.

No deberá duplicarse lógica innecesariamente.

---

## Modularidad

Las funcionalidades deben permanecer separadas según su responsabilidad.

La incorporación de una funcionalidad no debe introducir dependencias innecesarias sobre componentes no relacionados.

---

## Simplicidad

Se deben priorizar soluciones simples y verificables.

No debe introducirse complejidad que no sea necesaria para resolver el problema concreto.

---

## Conservación del comportamiento

Las modificaciones deben preservar el comportamiento existente cuando éste no forme parte del cambio solicitado.

No se deben realizar cambios adicionales únicamente por conveniencia, limpieza o reorganización si no son necesarios para el objetivo del cambio.

---

# Arquitectura

El desarrollo debe respetar la separación existente entre:

* Sensor Framework;
* Reputation Engine;
* State Engine;
* Policy Engine;
* Ban Lifecycle Engine;
* Firewall Backend;
* Installer Engine.

Cada componente debe utilizar las funciones y mecanismos correspondientes a su responsabilidad.

Las modificaciones que afecten las relaciones entre estos componentes deben verificarse sobre el comportamiento real del sistema.

---

# Documentación

La documentación forma parte del código fuente del proyecto.

Cuando un cambio modifica el comportamiento documentado de ARE, los documentos correspondientes deben actualizarse para reflejar el estado real del código.

Según el alcance del cambio pueden verse afectados:

* README.md;
* PROJECT.md;
* ARCHITECTURE.md;
* DESIGN.md;
* INSTALL.md;
* CHANGELOG.md;
* ROADMAP.md;
* CONTRIBUTING.md;
* GOVERNANCE.md;
* SECURITY.md;
* USER_GUIDE.md.

La documentación no debe describir funcionalidades que no estén implementadas.

Tampoco debe presentar como comportamiento actual una capacidad que corresponda únicamente a una planificación futura.

---

# Verificación

Toda modificación debe verificarse antes de considerarse terminada.

La verificación debe comprobar, según corresponda:

* funcionamiento del cambio;
* ausencia de errores introducidos;
* conservación del comportamiento no afectado;
* coherencia con los componentes involucrados;
* conservación de los datos persistentes cuando corresponda.

La verificación debe basarse en resultados observables del sistema y no en suposiciones.

---

# Installer Engine

Los cambios relacionados con el Installer Engine deben verificarse de acuerdo con la operación afectada.

Las operaciones administradas por el Installer Engine son:

* install;
* upgrade;
* repair;
* verify;
* uninstall.

La validación debe limitarse a las operaciones realmente modificadas por el cambio y a sus dependencias directas.

---

# Commits

Cada commit debe representar un cambio identificable y coherente.

Los mensajes deben ser:

* claros;
* específicos;
* trazables;
* representativos del contenido real del commit.

Ejemplos:

```text
BUG-008  Fix reputation calculation

TASK-012  Refactor installer manifest

FEAT-005  Add Sensor Framework

DOC-006  Rewrite installation guide
```

Un commit no debe utilizarse para ocultar cambios no relacionados con su objetivo.

---

# Calidad

Antes de cerrar un cambio debe verificarse:

* código correspondiente al objetivo definido;
* funcionamiento comprobado;
* ausencia de modificaciones innecesarias;
* documentación actualizada cuando corresponda;
* coherencia con la arquitectura;
* estado del repositorio revisado.

---

# Principios finales

El desarrollo de ARE debe mantener los siguientes principios:

1. Comprender antes de implementar.
2. Modificar únicamente lo necesario.
3. Una responsabilidad por componente.
4. Verificar antes de concluir.
5. Resolver completamente los problemas encontrados antes de continuar.
6. Preservar el comportamiento no afectado.
7. Reutilizar componentes existentes antes de duplicar lógica.
8. Mantener la documentación sincronizada con el código.
9. Basar las conclusiones en comportamiento verificable.
10. Mantener cada cambio trazable y coherente.
