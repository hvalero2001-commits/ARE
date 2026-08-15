# ARE Governance

## Introducción

Este documento define los principios de gobierno utilizados para la evolución de ARE (Abuse Reputation Engine).

Su objetivo es establecer criterios claros para realizar cambios sobre el proyecto, manteniendo la estabilidad del sistema, la coherencia arquitectónica y la documentación sincronizada con el código.

---

# Principios

Las decisiones sobre ARE deben respetar los siguientes principios:

* comprender el comportamiento existente antes de modificarlo;
* arquitectura antes que implementación;
* estabilidad antes que cambios innecesarios;
* una responsabilidad por componente;
* bajo acoplamiento;
* alta cohesión;
* reutilización antes que duplicación;
* documentación sincronizada con el código;
* evolución incremental;
* verificación antes de concluir un cambio.

Las decisiones deben ser coherentes con:

* `PHILOSOPHY.md`;
* `ARCHITECTURE.md`;
* `DESIGN.md`;
* `DEVELOPMENT.md`.

---

# Evolución del proyecto

Los cambios deben realizarse de forma controlada.

El proceso general es:

```text id="g6l8p4"
Problema o necesidad
        │
        ▼
Análisis del comportamiento actual
        │
        ▼
Identificación del alcance
        │
        ▼
Diseño del cambio
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

Las modificaciones que afecten la arquitectura deben analizarse antes de su implementación.

---

# Clasificación de cambios

Los cambios pueden clasificarse según su naturaleza.

## BUG

Corrección de un comportamiento incorrecto existente.

---

## TASK

Trabajo de mantenimiento, reorganización, documentación o refactorización.

---

## FEATURE

Incorporación de una nueva funcionalidad.

---

## RFC

Documento utilizado cuando sea necesario analizar formalmente una modificación arquitectónica.

Un cambio arquitectónico debe estar definido y comprendido antes de implementarse.

---

## IDEA

Propuesta que todavía no constituye una implementación definida.

Una idea no representa una funcionalidad implementada.

---

# Política de versiones

ARE utiliza versiones para identificar estados concretos del proyecto.

Las características, correcciones y cambios incluidos en una versión deben estar reflejados en la documentación correspondiente.

La documentación de una versión debe describir el estado real de esa versión y no funcionalidades futuras.

---

# Criterios para cerrar una versión

Antes de considerar una versión finalizada debe verificarse:

* código correspondiente al estado que se pretende publicar;
* funcionamiento comprobado;
* ausencia de modificaciones innecesarias;
* documentación actualizada;
* arquitectura coherente con la implementación;
* CHANGELOG actualizado cuando corresponda;
* estado del repositorio revisado.

Una versión debe representar un estado coherente y verificable del proyecto.

---

# Documentación

La documentación forma parte del proyecto.

Cuando una modificación cambia el comportamiento documentado de ARE, los documentos afectados deben actualizarse.

La documentación no debe:

* describir funcionalidades inexistentes;
* presentar planes futuros como funcionalidades actuales;
* contradecir el comportamiento implementado;
* conservar información que haya quedado invalidada por un cambio comprobado.

---

# Calidad

La evaluación de un cambio debe considerar:

* comportamiento correcto;
* alcance del cambio;
* consistencia arquitectónica;
* simplicidad;
* reutilización de componentes existentes;
* ausencia de duplicación innecesaria;
* impacto sobre componentes no involucrados;
* documentación correspondiente.

---

# Responsabilidad arquitectónica

La arquitectura del proyecto se encuentra documentada principalmente en:

* `PHILOSOPHY.md`;
* `ARCHITECTURE.md`;
* `DESIGN.md`.

La implementación debe respetar las responsabilidades definidas para los componentes existentes.

Una implementación no debe utilizarse para justificar retrospectivamente una arquitectura que no haya sido definida o verificada.

Cuando el comportamiento real difiera de la documentación, primero debe verificarse el comportamiento y posteriormente corregirse la documentación o el código según corresponda.

---

# Cambios y estabilidad

Los cambios deben limitarse al alcance necesario para resolver el objetivo definido.

No deben modificarse componentes no relacionados únicamente para reorganizar, limpiar o anticipar necesidades futuras.

Cuando aparezca un error durante un cambio, debe resolverse y verificarse antes de continuar con cambios dependientes.

---

# Filosofía

ARE debe evolucionar mediante cambios pequeños, verificables y documentados.

La estabilidad del sistema tiene prioridad sobre la incorporación innecesaria de cambios.

Cada versión debe representar un estado que pueda ser comprendido y comprobado a partir del código y de su documentación.

El gobierno de ARE tiene como objetivo preservar esa coherencia durante la evolución del proyecto.
# ARE Governance

## Introducción

Este documento define los principios de gobierno utilizados para la evolución de ARE (Abuse Reputation Engine).

Su objetivo es establecer criterios claros para realizar cambios sobre el proyecto, manteniendo la estabilidad del sistema, la coherencia arquitectónica y la documentación sincronizada con el código.

---

# Principios

Las decisiones sobre ARE deben respetar los siguientes principios:

* comprender el comportamiento existente antes de modificarlo;
* arquitectura antes que implementación;
* estabilidad antes que cambios innecesarios;
* una responsabilidad por componente;
* bajo acoplamiento;
* alta cohesión;
* reutilización antes que duplicación;
* documentación sincronizada con el código;
* evolución incremental;
* verificación antes de concluir un cambio.

Las decisiones deben ser coherentes con:

* `PHILOSOPHY.md`;
* `ARCHITECTURE.md`;
* `DESIGN.md`;
* `DEVELOPMENT.md`.

---

# Evolución del proyecto

Los cambios deben realizarse de forma controlada.

El proceso general es:

```text id="g6l8p4"
Problema o necesidad
        │
        ▼
Análisis del comportamiento actual
        │
        ▼
Identificación del alcance
        │
        ▼
Diseño del cambio
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

Las modificaciones que afecten la arquitectura deben analizarse antes de su implementación.

---

# Clasificación de cambios

Los cambios pueden clasificarse según su naturaleza.

## BUG

Corrección de un comportamiento incorrecto existente.

---

## TASK

Trabajo de mantenimiento, reorganización, documentación o refactorización.

---

## FEATURE

Incorporación de una nueva funcionalidad.

---

## RFC

Documento utilizado cuando sea necesario analizar formalmente una modificación arquitectónica.

Un cambio arquitectónico debe estar definido y comprendido antes de implementarse.

---

## IDEA

Propuesta que todavía no constituye una implementación definida.

Una idea no representa una funcionalidad implementada.

---

# Política de versiones

ARE utiliza versiones para identificar estados concretos del proyecto.

Las características, correcciones y cambios incluidos en una versión deben estar reflejados en la documentación correspondiente.

La documentación de una versión debe describir el estado real de esa versión y no funcionalidades futuras.

---

# Criterios para cerrar una versión

Antes de considerar una versión finalizada debe verificarse:

* código correspondiente al estado que se pretende publicar;
* funcionamiento comprobado;
* ausencia de modificaciones innecesarias;
* documentación actualizada;
* arquitectura coherente con la implementación;
* CHANGELOG actualizado cuando corresponda;
* estado del repositorio revisado.

Una versión debe representar un estado coherente y verificable del proyecto.

---

# Documentación

La documentación forma parte del proyecto.

Cuando una modificación cambia el comportamiento documentado de ARE, los documentos afectados deben actualizarse.

La documentación no debe:

* describir funcionalidades inexistentes;
* presentar planes futuros como funcionalidades actuales;
* contradecir el comportamiento implementado;
* conservar información que haya quedado invalidada por un cambio comprobado.

---

# Calidad

La evaluación de un cambio debe considerar:

* comportamiento correcto;
* alcance del cambio;
* consistencia arquitectónica;
* simplicidad;
* reutilización de componentes existentes;
* ausencia de duplicación innecesaria;
* impacto sobre componentes no involucrados;
* documentación correspondiente.

---

# Responsabilidad arquitectónica

La arquitectura del proyecto se encuentra documentada principalmente en:

* `PHILOSOPHY.md`;
* `ARCHITECTURE.md`;
* `DESIGN.md`.

La implementación debe respetar las responsabilidades definidas para los componentes existentes.

Una implementación no debe utilizarse para justificar retrospectivamente una arquitectura que no haya sido definida o verificada.

Cuando el comportamiento real difiera de la documentación, primero debe verificarse el comportamiento y posteriormente corregirse la documentación o el código según corresponda.

---

# Cambios y estabilidad

Los cambios deben limitarse al alcance necesario para resolver el objetivo definido.

No deben modificarse componentes no relacionados únicamente para reorganizar, limpiar o anticipar necesidades futuras.

Cuando aparezca un error durante un cambio, debe resolverse y verificarse antes de continuar con cambios dependientes.

---

# Filosofía

ARE debe evolucionar mediante cambios pequeños, verificables y documentados.

La estabilidad del sistema tiene prioridad sobre la incorporación innecesaria de cambios.

Cada versión debe representar un estado que pueda ser comprendido y comprobado a partir del código y de su documentación.

El gobierno de ARE tiene como objetivo preservar esa coherencia durante la evolución del proyecto.
# ARE Governance

## Introducción

Este documento define los principios de gobierno utilizados para la evolución de ARE (Abuse Reputation Engine).

Su objetivo es establecer criterios claros para realizar cambios sobre el proyecto, manteniendo la estabilidad del sistema, la coherencia arquitectónica y la documentación sincronizada con el código.

---

# Principios

Las decisiones sobre ARE deben respetar los siguientes principios:

* comprender el comportamiento existente antes de modificarlo;
* arquitectura antes que implementación;
* estabilidad antes que cambios innecesarios;
* una responsabilidad por componente;
* bajo acoplamiento;
* alta cohesión;
* reutilización antes que duplicación;
* documentación sincronizada con el código;
* evolución incremental;
* verificación antes de concluir un cambio.

Las decisiones deben ser coherentes con:

* `PHILOSOPHY.md`;
* `ARCHITECTURE.md`;
* `DESIGN.md`;
* `DEVELOPMENT.md`.

---

# Evolución del proyecto

Los cambios deben realizarse de forma controlada.

El proceso general es:

```text id="g6l8p4"
Problema o necesidad
        │
        ▼
Análisis del comportamiento actual
        │
        ▼
Identificación del alcance
        │
        ▼
Diseño del cambio
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

Las modificaciones que afecten la arquitectura deben analizarse antes de su implementación.

---

# Clasificación de cambios

Los cambios pueden clasificarse según su naturaleza.

## BUG

Corrección de un comportamiento incorrecto existente.

---

## TASK

Trabajo de mantenimiento, reorganización, documentación o refactorización.

---

## FEATURE

Incorporación de una nueva funcionalidad.

---

## RFC

Documento utilizado cuando sea necesario analizar formalmente una modificación arquitectónica.

Un cambio arquitectónico debe estar definido y comprendido antes de implementarse.

---

## IDEA

Propuesta que todavía no constituye una implementación definida.

Una idea no representa una funcionalidad implementada.

---

# Política de versiones

ARE utiliza versiones para identificar estados concretos del proyecto.

Las características, correcciones y cambios incluidos en una versión deben estar reflejados en la documentación correspondiente.

La documentación de una versión debe describir el estado real de esa versión y no funcionalidades futuras.

---

# Criterios para cerrar una versión

Antes de considerar una versión finalizada debe verificarse:

* código correspondiente al estado que se pretende publicar;
* funcionamiento comprobado;
* ausencia de modificaciones innecesarias;
* documentación actualizada;
* arquitectura coherente con la implementación;
* CHANGELOG actualizado cuando corresponda;
* estado del repositorio revisado.

Una versión debe representar un estado coherente y verificable del proyecto.

---

# Documentación

La documentación forma parte del proyecto.

Cuando una modificación cambia el comportamiento documentado de ARE, los documentos afectados deben actualizarse.

La documentación no debe:

* describir funcionalidades inexistentes;
* presentar planes futuros como funcionalidades actuales;
* contradecir el comportamiento implementado;
* conservar información que haya quedado invalidada por un cambio comprobado.

---

# Calidad

La evaluación de un cambio debe considerar:

* comportamiento correcto;
* alcance del cambio;
* consistencia arquitectónica;
* simplicidad;
* reutilización de componentes existentes;
* ausencia de duplicación innecesaria;
* impacto sobre componentes no involucrados;
* documentación correspondiente.

---

# Responsabilidad arquitectónica

La arquitectura del proyecto se encuentra documentada principalmente en:

* `PHILOSOPHY.md`;
* `ARCHITECTURE.md`;
* `DESIGN.md`.

La implementación debe respetar las responsabilidades definidas para los componentes existentes.

Una implementación no debe utilizarse para justificar retrospectivamente una arquitectura que no haya sido definida o verificada.

Cuando el comportamiento real difiera de la documentación, primero debe verificarse el comportamiento y posteriormente corregirse la documentación o el código según corresponda.

---

# Cambios y estabilidad

Los cambios deben limitarse al alcance necesario para resolver el objetivo definido.

No deben modificarse componentes no relacionados únicamente para reorganizar, limpiar o anticipar necesidades futuras.

Cuando aparezca un error durante un cambio, debe resolverse y verificarse antes de continuar con cambios dependientes.

---

# Filosofía

ARE debe evolucionar mediante cambios pequeños, verificables y documentados.

La estabilidad del sistema tiene prioridad sobre la incorporación innecesaria de cambios.

Cada versión debe representar un estado que pueda ser comprendido y comprobado a partir del código y de su documentación.

El gobierno de ARE tiene como objetivo preservar esa coherencia durante la evolución del proyecto.
# ARE Governance

## Introducción

Este documento define los principios de gobierno utilizados para la evolución de ARE (Abuse Reputation Engine).

Su objetivo es establecer criterios claros para realizar cambios sobre el proyecto, manteniendo la estabilidad del sistema, la coherencia arquitectónica y la documentación sincronizada con el código.

---

# Principios

Las decisiones sobre ARE deben respetar los siguientes principios:

* comprender el comportamiento existente antes de modificarlo;
* arquitectura antes que implementación;
* estabilidad antes que cambios innecesarios;
* una responsabilidad por componente;
* bajo acoplamiento;
* alta cohesión;
* reutilización antes que duplicación;
* documentación sincronizada con el código;
* evolución incremental;
* verificación antes de concluir un cambio.

Las decisiones deben ser coherentes con:

* `PHILOSOPHY.md`;
* `ARCHITECTURE.md`;
* `DESIGN.md`;
* `DEVELOPMENT.md`.

---

# Evolución del proyecto

Los cambios deben realizarse de forma controlada.

El proceso general es:

```text id="g6l8p4"
Problema o necesidad
        │
        ▼
Análisis del comportamiento actual
        │
        ▼
Identificación del alcance
        │
        ▼
Diseño del cambio
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

Las modificaciones que afecten la arquitectura deben analizarse antes de su implementación.

---

# Clasificación de cambios

Los cambios pueden clasificarse según su naturaleza.

## BUG

Corrección de un comportamiento incorrecto existente.

---

## TASK

Trabajo de mantenimiento, reorganización, documentación o refactorización.

---

## FEATURE

Incorporación de una nueva funcionalidad.

---

## RFC

Documento utilizado cuando sea necesario analizar formalmente una modificación arquitectónica.

Un cambio arquitectónico debe estar definido y comprendido antes de implementarse.

---

## IDEA

Propuesta que todavía no constituye una implementación definida.

Una idea no representa una funcionalidad implementada.

---

# Política de versiones

ARE utiliza versiones para identificar estados concretos del proyecto.

Las características, correcciones y cambios incluidos en una versión deben estar reflejados en la documentación correspondiente.

La documentación de una versión debe describir el estado real de esa versión y no funcionalidades futuras.

---

# Criterios para cerrar una versión

Antes de considerar una versión finalizada debe verificarse:

* código correspondiente al estado que se pretende publicar;
* funcionamiento comprobado;
* ausencia de modificaciones innecesarias;
* documentación actualizada;
* arquitectura coherente con la implementación;
* CHANGELOG actualizado cuando corresponda;
* estado del repositorio revisado.

Una versión debe representar un estado coherente y verificable del proyecto.

---

# Documentación

La documentación forma parte del proyecto.

Cuando una modificación cambia el comportamiento documentado de ARE, los documentos afectados deben actualizarse.

La documentación no debe:

* describir funcionalidades inexistentes;
* presentar planes futuros como funcionalidades actuales;
* contradecir el comportamiento implementado;
* conservar información que haya quedado invalidada por un cambio comprobado.

---

# Calidad

La evaluación de un cambio debe considerar:

* comportamiento correcto;
* alcance del cambio;
* consistencia arquitectónica;
* simplicidad;
* reutilización de componentes existentes;
* ausencia de duplicación innecesaria;
* impacto sobre componentes no involucrados;
* documentación correspondiente.

---

# Responsabilidad arquitectónica

La arquitectura del proyecto se encuentra documentada principalmente en:

* `PHILOSOPHY.md`;
* `ARCHITECTURE.md`;
* `DESIGN.md`.

La implementación debe respetar las responsabilidades definidas para los componentes existentes.

Una implementación no debe utilizarse para justificar retrospectivamente una arquitectura que no haya sido definida o verificada.

Cuando el comportamiento real difiera de la documentación, primero debe verificarse el comportamiento y posteriormente corregirse la documentación o el código según corresponda.

---

# Cambios y estabilidad

Los cambios deben limitarse al alcance necesario para resolver el objetivo definido.

No deben modificarse componentes no relacionados únicamente para reorganizar, limpiar o anticipar necesidades futuras.

Cuando aparezca un error durante un cambio, debe resolverse y verificarse antes de continuar con cambios dependientes.

---

# Filosofía

ARE debe evolucionar mediante cambios pequeños, verificables y documentados.

La estabilidad del sistema tiene prioridad sobre la incorporación innecesaria de cambios.

Cada versión debe representar un estado que pueda ser comprendido y comprobado a partir del código y de su documentación.

El gobierno de ARE tiene como objetivo preservar esa coherencia durante la evolución del proyecto.
# ARE Governance

## Introducción

Este documento define los principios de gobierno utilizados para la evolución de ARE (Abuse Reputation Engine).

Su objetivo es establecer criterios claros para realizar cambios sobre el proyecto, manteniendo la estabilidad del sistema, la coherencia arquitectónica y la documentación sincronizada con el código.

---

# Principios

Las decisiones sobre ARE deben respetar los siguientes principios:

* comprender el comportamiento existente antes de modificarlo;
* arquitectura antes que implementación;
* estabilidad antes que cambios innecesarios;
* una responsabilidad por componente;
* bajo acoplamiento;
* alta cohesión;
* reutilización antes que duplicación;
* documentación sincronizada con el código;
* evolución incremental;
* verificación antes de concluir un cambio.

Las decisiones deben ser coherentes con:

* `PHILOSOPHY.md`;
* `ARCHITECTURE.md`;
* `DESIGN.md`;
* `DEVELOPMENT.md`.

---

# Evolución del proyecto

Los cambios deben realizarse de forma controlada.

El proceso general es:

```text id="g6l8p4"
Problema o necesidad
        │
        ▼
Análisis del comportamiento actual
        │
        ▼
Identificación del alcance
        │
        ▼
Diseño del cambio
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

Las modificaciones que afecten la arquitectura deben analizarse antes de su implementación.

---

# Clasificación de cambios

Los cambios pueden clasificarse según su naturaleza.

## BUG

Corrección de un comportamiento incorrecto existente.

---

## TASK

Trabajo de mantenimiento, reorganización, documentación o refactorización.

---

## FEATURE

Incorporación de una nueva funcionalidad.

---

## RFC

Documento utilizado cuando sea necesario analizar formalmente una modificación arquitectónica.

Un cambio arquitectónico debe estar definido y comprendido antes de implementarse.

---

## IDEA

Propuesta que todavía no constituye una implementación definida.

Una idea no representa una funcionalidad implementada.

---

# Política de versiones

ARE utiliza versiones para identificar estados concretos del proyecto.

Las características, correcciones y cambios incluidos en una versión deben estar reflejados en la documentación correspondiente.

La documentación de una versión debe describir el estado real de esa versión y no funcionalidades futuras.

---

# Criterios para cerrar una versión

Antes de considerar una versión finalizada debe verificarse:

* código correspondiente al estado que se pretende publicar;
* funcionamiento comprobado;
* ausencia de modificaciones innecesarias;
* documentación actualizada;
* arquitectura coherente con la implementación;
* CHANGELOG actualizado cuando corresponda;
* estado del repositorio revisado.

Una versión debe representar un estado coherente y verificable del proyecto.

---

# Documentación

La documentación forma parte del proyecto.

Cuando una modificación cambia el comportamiento documentado de ARE, los documentos afectados deben actualizarse.

La documentación no debe:

* describir funcionalidades inexistentes;
* presentar planes futuros como funcionalidades actuales;
* contradecir el comportamiento implementado;
* conservar información que haya quedado invalidada por un cambio comprobado.

---

# Calidad

La evaluación de un cambio debe considerar:

* comportamiento correcto;
* alcance del cambio;
* consistencia arquitectónica;
* simplicidad;
* reutilización de componentes existentes;
* ausencia de duplicación innecesaria;
* impacto sobre componentes no involucrados;
* documentación correspondiente.

---

# Responsabilidad arquitectónica

La arquitectura del proyecto se encuentra documentada principalmente en:

* `PHILOSOPHY.md`;
* `ARCHITECTURE.md`;
* `DESIGN.md`.

La implementación debe respetar las responsabilidades definidas para los componentes existentes.

Una implementación no debe utilizarse para justificar retrospectivamente una arquitectura que no haya sido definida o verificada.

Cuando el comportamiento real difiera de la documentación, primero debe verificarse el comportamiento y posteriormente corregirse la documentación o el código según corresponda.

---

# Cambios y estabilidad

Los cambios deben limitarse al alcance necesario para resolver el objetivo definido.

No deben modificarse componentes no relacionados únicamente para reorganizar, limpiar o anticipar necesidades futuras.

Cuando aparezca un error durante un cambio, debe resolverse y verificarse antes de continuar con cambios dependientes.

---

# Filosofía

ARE debe evolucionar mediante cambios pequeños, verificables y documentados.

La estabilidad del sistema tiene prioridad sobre la incorporación innecesaria de cambios.

Cada versión debe representar un estado que pueda ser comprendido y comprobado a partir del código y de su documentación.

El gobierno de ARE tiene como objetivo preservar esa coherencia durante la evolución del proyecto.
# ARE Governance

## Introducción

Este documento define los principios de gobierno utilizados para la evolución de ARE (Abuse Reputation Engine).

Su objetivo es establecer criterios claros para realizar cambios sobre el proyecto, manteniendo la estabilidad del sistema, la coherencia arquitectónica y la documentación sincronizada con el código.

---

# Principios

Las decisiones sobre ARE deben respetar los siguientes principios:

* comprender el comportamiento existente antes de modificarlo;
* arquitectura antes que implementación;
* estabilidad antes que cambios innecesarios;
* una responsabilidad por componente;
* bajo acoplamiento;
* alta cohesión;
* reutilización antes que duplicación;
* documentación sincronizada con el código;
* evolución incremental;
* verificación antes de concluir un cambio.

Las decisiones deben ser coherentes con:

* `PHILOSOPHY.md`;
* `ARCHITECTURE.md`;
* `DESIGN.md`;
* `DEVELOPMENT.md`.

---

# Evolución del proyecto

Los cambios deben realizarse de forma controlada.

El proceso general es:

```text id="g6l8p4"
Problema o necesidad
        │
        ▼
Análisis del comportamiento actual
        │
        ▼
Identificación del alcance
        │
        ▼
Diseño del cambio
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

Las modificaciones que afecten la arquitectura deben analizarse antes de su implementación.

---

# Clasificación de cambios

Los cambios pueden clasificarse según su naturaleza.

## BUG

Corrección de un comportamiento incorrecto existente.

---

## TASK

Trabajo de mantenimiento, reorganización, documentación o refactorización.

---

## FEATURE

Incorporación de una nueva funcionalidad.

---

## RFC

Documento utilizado cuando sea necesario analizar formalmente una modificación arquitectónica.

Un cambio arquitectónico debe estar definido y comprendido antes de implementarse.

---

## IDEA

Propuesta que todavía no constituye una implementación definida.

Una idea no representa una funcionalidad implementada.

---

# Política de versiones

ARE utiliza versiones para identificar estados concretos del proyecto.

Las características, correcciones y cambios incluidos en una versión deben estar reflejados en la documentación correspondiente.

La documentación de una versión debe describir el estado real de esa versión y no funcionalidades futuras.

---

# Criterios para cerrar una versión

Antes de considerar una versión finalizada debe verificarse:

* código correspondiente al estado que se pretende publicar;
* funcionamiento comprobado;
* ausencia de modificaciones innecesarias;
* documentación actualizada;
* arquitectura coherente con la implementación;
* CHANGELOG actualizado cuando corresponda;
* estado del repositorio revisado.

Una versión debe representar un estado coherente y verificable del proyecto.

---

# Documentación

La documentación forma parte del proyecto.

Cuando una modificación cambia el comportamiento documentado de ARE, los documentos afectados deben actualizarse.

La documentación no debe:

* describir funcionalidades inexistentes;
* presentar planes futuros como funcionalidades actuales;
* contradecir el comportamiento implementado;
* conservar información que haya quedado invalidada por un cambio comprobado.

---

# Calidad

La evaluación de un cambio debe considerar:

* comportamiento correcto;
* alcance del cambio;
* consistencia arquitectónica;
* simplicidad;
* reutilización de componentes existentes;
* ausencia de duplicación innecesaria;
* impacto sobre componentes no involucrados;
* documentación correspondiente.

---

# Responsabilidad arquitectónica

La arquitectura del proyecto se encuentra documentada principalmente en:

* `PHILOSOPHY.md`;
* `ARCHITECTURE.md`;
* `DESIGN.md`.

La implementación debe respetar las responsabilidades definidas para los componentes existentes.

Una implementación no debe utilizarse para justificar retrospectivamente una arquitectura que no haya sido definida o verificada.

Cuando el comportamiento real difiera de la documentación, primero debe verificarse el comportamiento y posteriormente corregirse la documentación o el código según corresponda.

---

# Cambios y estabilidad

Los cambios deben limitarse al alcance necesario para resolver el objetivo definido.

No deben modificarse componentes no relacionados únicamente para reorganizar, limpiar o anticipar necesidades futuras.

Cuando aparezca un error durante un cambio, debe resolverse y verificarse antes de continuar con cambios dependientes.

---

# Filosofía

ARE debe evolucionar mediante cambios pequeños, verificables y documentados.

La estabilidad del sistema tiene prioridad sobre la incorporación innecesaria de cambios.

Cada versión debe representar un estado que pueda ser comprendido y comprobado a partir del código y de su documentación.

El gobierno de ARE tiene como objetivo preservar esa coherencia durante la evolución del proyecto.
