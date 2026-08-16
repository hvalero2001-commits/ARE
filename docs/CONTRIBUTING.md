# Contributing to ARE

## Introducción

ARE (Abuse Reputation Engine) es un proyecto desarrollado bajo principios de simplicidad, modularidad, separación de responsabilidades y evolución controlada.

Toda contribución deberá respetar la arquitectura, las decisiones de diseño y la metodología oficial de desarrollo del proyecto.

Antes de modificar el proyecto debe comprenderse el comportamiento existente y verificarse qué componentes están realmente involucrados en el cambio.

Para comprender el proyecto se recomienda consultar:

* `README.md`
* `docs/PROJECT.md`
* `docs/ARCHITECTURE.md`
* `docs/DESIGN.md`
* `docs/DEVELOPMENT.md`

---

# Principios

Toda contribución deberá seguir los siguientes principios:

* Comprender antes de implementar.
* Una responsabilidad por componente.
* Modificar únicamente lo necesario.
* Reutilizar componentes existentes antes de duplicar lógica.
* Preservar el comportamiento no afectado.
* Mantener la arquitectura desacoplada.
* Verificar los cambios antes de considerarlos terminados.
* Mantener la documentación sincronizada con el estado real del proyecto.
* Mantener cada cambio trazable.

La estabilidad del sistema tiene prioridad sobre la incorporación de cambios no necesarios.

---

# Antes de comenzar

Antes de implementar un cambio deberá verificarse:

* qué comportamiento existe actualmente;
* si la funcionalidad ya existe;
* qué componente es responsable del comportamiento;
* qué otros componentes dependen de él;
* si el cambio corresponde al alcance de la versión en desarrollo;
* si existe una tarea, bug o feature relacionado;
* si el cambio modifica una relación arquitectónica existente.

No deberán modificarse archivos o componentes que no sean necesarios para resolver el objetivo definido.

Si el cambio altera responsabilidades, interfaces o relaciones fundamentales entre componentes, deberá analizarse y documentarse como modificación arquitectónica antes de su implementación.

---

# Clasificación de cambios

Toda modificación deberá clasificarse según su naturaleza.

## BUG

Corrección de un comportamiento incorrecto existente.

La corrección debe resolver el problema sin alterar comportamientos que no formen parte del bug.

## TASK

Trabajo técnico, mantenimiento, reorganización o refactorización que no incorpora una nueva capacidad funcional.

## FEATURE

Incorporación de una nueva funcionalidad al proyecto.

## RFC

Propuesta de modificación arquitectónica o de una decisión que pueda alterar la estructura o responsabilidades fundamentales de ARE.

Una RFC no representa una funcionalidad implementada hasta que su propuesta haya sido aprobada e implementada.

## IDEA

Propuesta que todavía no forma parte de una implementación definida.

Una idea no representa una funcionalidad disponible ni comprometida.

---

# Flujo de contribución

Toda modificación deberá seguir un proceso controlado:

```text
Problema o necesidad
        ↓
Análisis del comportamiento actual
        ↓
Identificación del componente afectado
        ↓
Clasificación
(BUG / TASK / FEATURE / RFC / IDEA)
        ↓
Definición del cambio
        ↓
Diseño, cuando corresponda
        ↓
Implementación
        ↓
Verificación
        ↓
Actualización de documentación
        ↓
Revisión del repositorio
        ↓
Commit
```

Cada etapa deberá completarse antes de considerar terminado el cambio.

Cuando durante la verificación aparezca un problema relacionado con el cambio, éste deberá resolverse y verificarse antes de continuar con cambios dependientes.

---

# Un cambio, una responsabilidad

Cada contribución deberá mantener un objetivo identificable.

Ejemplos:

* corregir un bug;
* incorporar una funcionalidad;
* modificar un componente concreto;
* reorganizar un módulo;
* actualizar documentación relacionada con un cambio real.

No deberán mezclarse cambios independientes únicamente para aprovechar una misma modificación.

---

# Arquitectura y componentes

Las contribuciones deberán respetar la separación de responsabilidades existente en ARE.

Los cambios deberán realizarse dentro del componente correspondiente a su responsabilidad.

Entre los componentes actualmente organizados en el proyecto se encuentran:

* `sensors/`
* `policy/`
* `infrastructure/`
* `manifest/`
* `dashboard/`
* `testing/`
* `systemd/`
* `templates/`

La existencia de un componente no autoriza a trasladarle responsabilidades pertenecientes a otro.

Cuando una modificación requiera cambiar la relación entre componentes, deberá verificarse el comportamiento de todos los componentes directamente afectados.

---

# Pruebas y verificación

Toda modificación deberá verificarse antes de considerarse terminada.

La verificación deberá basarse en resultados observables y deberá comprobar, según corresponda:

* que el cambio funciona;
* que el comportamiento esperado se mantiene;
* que no se introducen regresiones;
* que los componentes relacionados continúan funcionando;
* que los datos persistentes no resultan afectados indebidamente;
* que las operaciones modificadas del sistema continúan siendo coherentes.

Las pruebas existentes en `testing/` deberán reutilizarse cuando correspondan al comportamiento modificado.

No deberá considerarse suficiente una comprobación basada únicamente en que el código no produzca errores sintácticos.

---

# Documentación

La documentación forma parte del proyecto.

Cuando una modificación cambie el comportamiento real de ARE, deberán actualizarse los documentos afectados.

Según el alcance del cambio podrán verse involucrados:

* `README.md`
* `docs/PROJECT.md`
* `docs/ARCHITECTURE.md`
* `docs/DESIGN.md`
* `docs/INSTALL.md`
* `docs/CHANGELOG.md`
* `docs/ROADMAP.md`
* `docs/DEVELOPMENT.md`
* `docs/CONTRIBUTING.md`
* `docs/GOVERNANCE.md`
* `docs/SECURITY.md`
* `docs/USER_GUIDE.md`
* `docs/TODO.md`

Cada documento debe conservar su responsabilidad específica.

No deberá trasladarse a un documento información que corresponda a otro únicamente para evitar actualizar el documento correcto.

La documentación no debe describir como implementado aquello que únicamente está planificado.

---

# Installer Engine

Los cambios relacionados con el Installer Engine deberán considerar las operaciones que actualmente administra:

* `install`
* `upgrade`
* `repair`
* `verify`
* `uninstall`

Las modificaciones deberán verificarse únicamente sobre las operaciones afectadas y sus dependencias directas.

La estructura definida mediante el manifest deberá mantenerse como referencia de los componentes administrados por el ciclo de instalación y actualización.

No deberán introducirse archivos o componentes en el proceso de instalación sin determinar previamente su relación con la estructura administrada por el manifest.

---

# Commits

Cada commit deberá representar un cambio identificable y coherente.

Los mensajes deberán ser:

* claros;
* específicos;
* trazables;
* representativos del contenido real del commit.

Ejemplos:

```text
BUG-008 Fix state and policy inconsistency

TASK-014 Update installer manifest

FEAT-005 Add sensor integration

DOC-006 Update installation documentation
```

Un commit no deberá utilizarse para ocultar modificaciones no relacionadas con su objetivo.

---

# Revisión antes de cerrar un cambio

Antes de cerrar una contribución deberá verificarse:

* objetivo definido;
* componente correcto;
* implementación limitada al alcance necesario;
* pruebas realizadas;
* comportamiento verificado;
* ausencia de modificaciones innecesarias;
* documentación afectada actualizada;
* coherencia con la arquitectura;
* estado del repositorio revisado.

El cambio sólo deberá considerarse terminado cuando estos puntos hayan sido comprobados según corresponda.

---

# Filosofía

ARE evoluciona mediante cambios incrementales.

Cada modificación debe partir del comportamiento real existente, resolver un objetivo concreto y ser verificada antes de continuar con cambios posteriores.

Las nuevas capacidades deben incorporarse sin romper las responsabilidades existentes ni introducir complejidad innecesaria.

La documentación debe evolucionar junto con el software y representar el estado real del proyecto.

