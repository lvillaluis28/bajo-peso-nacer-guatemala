# Bajo peso al nacer en Guatemala

**Autor:** Luis Villaseñor\
**Período de estudio:** 2009–2024\
**Lenguaje:** R\
**Estado:** en desarrollo

> **Importante:** los registros individuales contenidos en este repositorio son datos generados artificialmente con fines docentes y de reproducibilidad. Ninguna fila corresponde a una persona real. La simulación reproduce de manera aproximada patrones demográficos, temporales y epidemiológicos plausibles de los nacimientos en Guatemala, pero no debe utilizarse para producir estimaciones oficiales.

## Resumen del proyecto

El bajo peso al nacer es un importante indicador de salud maternoinfantil y se asocia con mayor riesgo de morbimortalidad neonatal, alteraciones del crecimiento y consecuencias posteriores para la salud.

Este proyecto desarrolla un flujo reproducible en R para explorar la evolución del peso al nacer y del bajo peso al nacer en Guatemala entre 2009 y 2024. Para permitir que todo el análisis pueda publicarse y ejecutarse sin utilizar información individual confidencial, se generó una base de **100 000 nacimientos ficticios** mediante simulación reproducible.

La base conserva características relevantes para un análisis epidemiológico descriptivo, incluyendo fecha y peso al nacer, edad y características maternas, lugar y vía del parto, y departamento y municipio de residencia materna.

La simulación incorpora de forma deliberada patrones temporales y territoriales plausibles, entre ellos:

- disminución del número de nacimientos a lo largo del período;
- aumento progresivo de la frecuencia de bajo peso al nacer;
- variación estacional del bajo peso al nacer;
- cambios en la distribución de la edad materna;
- aumento de los partos atendidos en establecimientos de salud;
- aumento de la frecuencia de cesáreas;
- diferencias entre departamentos y municipios;
- valores ausentes y registros problemáticos para practicar validación y limpieza de datos.

El objetivo disponer de una base suficientemente realista para desarrollar un análisis completamente reproducible.

## Preguntas exploratorias

1.  ¿Cómo cambia la frecuencia de bajo peso al nacer entre 2009 y 2024?
2.  ¿Cómo evoluciona el peso medio al nacer durante el período de estudio?
3.  ¿Existe un patrón estacional del bajo peso al nacer según el mes de nacimiento?
4.  ¿Qué diferencias se observan entre departamentos y municipios de residencia materna?
5.  ¿Cómo varía el bajo peso al nacer según la edad y otras características maternas?
6.  ¿Qué efecto tienen los criterios de calidad y los datos ausentes sobre el tamaño de la muestra disponible para distintos análisis?

## Datos

### Base de nacimientos

La base utilizada en este repositorio contiene **100 000 registros generados artificialmente** para el período 2009–2024.

Se crea mediante:

`02_scripts/01_generar_base_sintetica.R`

y se guarda como:

`01_datos/nacimientos_guatemala.rds`

La generación utiliza una semilla fija:

``` r
set.seed(20261116)
```

Por lo tanto, ejecutar nuevamente el script con las mismas dependencias y archivos de referencia produce la misma base.

La simulación no selecciona, modifica ni anonimiza registros individuales de una base real. Cada observación se genera mediante distribuciones probabilísticas definidas en el código.

### Información territorial

Los nombres y códigos de los municipios provienen de un archivo público de la **Secretaría de Planificación y Programación de la Presidencia de Guatemala (SEGEPLAN)**:

`01_datos/datos_referencia/catalogo_municipios_segeplan_2026.xlsx`

El catálogo contiene los **340 municipios de Guatemala** y se utiliza para asignar nombres y códigos territoriales y para aproximar el peso relativo de los municipios mediante información poblacional.

Los siete municipios incorporados después de 2009 solo pueden recibir registros a partir del año correspondiente definido en el script.

## Bajo peso al nacer

Se define bajo peso al nacer como:

**Peso al nacer \< 2500 gramos**

La variable `low_birth_weight` toma los valores:

- `1`: peso \<2500 g;
- `0`: peso ≥2500 g;
- `NA`: peso desconocido.

Para el análisis principal se consideran plausibles los pesos comprendidos entre **500 y 5000 gramos**.

Los valores inferiores a 500 g o superiores a 5000 g se incluyen deliberadamente en una pequeña proporción de registros para permitir ejercicios de validación, pero son identificados como valores extremos y no se consideran elegibles para el análisis principal.

## Problemas de calidad introducidos deliberadamente

La base incluye una pequeña proporción de registros problemáticos para reproducir situaciones habituales en bases administrativas.

Los problemas críticos se generan sin solapamiento:

| **Problema**                             | **Proporción aproximada** |
|------------------------------------------|--------------------------:|
| Peso al nacer desconocido                |                     0,6 % |
| Peso extremo (\<500 g o \>5000 g)        |                     0,4 % |
| Fecha de nacimiento faltante             |                     0,4 % |
| Residencia materna faltante              |                     0,9 % |
| **Registros con algún problema crítico** |                 **2,3 %** |

También se incorporan valores ausentes en variables en las que se considera razonable permitirlos, como:

- edad materna;
- educación materna;
- pertenencia indígena;
- estado marital materno.

## Criterios de elegibilidad

Los criterios de inclusión dependen de la pregunta de investigación.

### Análisis nacional de bajo peso al nacer

Para estudiar tendencias nacionales se requiere:

- peso al nacer conocido;
- peso entre 500 y 5000 g.

No es necesario conocer el municipio de residencia materna.

La variable:

`eligible_national_lbw`

identifica los registros que cumplen estos criterios.

### Análisis territorial

Para análisis departamentales, municipales o que requieran asignación espacial se exige además:

- fecha de nacimiento conocida;
- municipio de residencia materna conocido.

La variable:

`eligible_spatial_lbw`

identifica estos registros.

Esta distinción permite evitar la aplicación de un único criterio de exclusión a preguntas de investigación con requisitos diferentes.

## Variables principales

| **Variable** | **Descripción** |
|------------------------------------|------------------------------------|
| `record_id` | Identificador ficticio único |
| `birth_date` | Fecha de nacimiento |
| `birth_year` | Año de nacimiento |
| `birth_month` | Mes de nacimiento |
| `sex` | Sexo registrado del recién nacido |
| `birth_weight_g` | Peso al nacer en gramos |
| `low_birth_weight` | Indicador de peso al nacer \<2500 g |
| `weight_review_status` | Clasificación del peso según criterios de revisión |
| `maternal_age` | Edad materna en años |
| `maternal_age_group` | Grupo de edad materna |
| `maternal_education` | Nivel educacional materno agrupado |
| `maternal_indigenous_status` | Pertenencia indígena materna agrupada |
| `maternal_marital_status` | Estado marital materno |
| `birth_attendance` | Categoría de persona que atendió el parto |
| `birth_place_group` | Lugar del parto agrupado |
| `delivery_mode` | Vía del parto |
| `maternal_department_code` | Código del departamento de residencia materna |
| `maternal_department_name` | Departamento de residencia materna |
| `maternal_municipality_code` | Código del municipio de residencia materna |
| `maternal_municipality_name` | Municipio de residencia materna |
| `quality_issue` | Problema crítico de calidad introducido deliberadamente |
| `eligible_national_lbw` | Elegibilidad para análisis nacional |
| `eligible_spatial_lbw` | Elegibilidad para análisis territorial |

## Patrones incorporados en la simulación

La generación de los datos no supone independencia absoluta entre las variables.

El riesgo de bajo peso al nacer depende probabilísticamente de distintas características, de modo que la base permita encontrar patrones epidemiológicos durante el análisis exploratorio.

Entre ellos se incluyen:

- mayor frecuencia de bajo peso al nacer en edades maternas extremas;
- diferencias territoriales;
- diferencias según sexo;
- variación según educación materna;
- aumento de la frecuencia de bajo peso al nacer entre 2009 y 2024;
- mayor frecuencia de bajo peso al nacer aproximadamente entre mayo y agosto.

Estas relaciones son **parámetros de simulación** y no deben interpretarse como estimaciones causales ni como resultados epidemiológicos obtenidos de la población guatemalteca.

## Organización del proyecto

``` text
bajo-peso-nacer-guatemala/
├── 01_datos/
│   ├── nacimientos_guatemala.rds
│   └── datos_referencia/
│       └── catalogo_municipios_segeplan_2026.xlsx
│
├── 02_scripts/
│   └── 01_generar_base_sintetica.R
│
├── 03_resultados/
│
├── bajo-peso-nacer-guatemala.Rproj
├── .gitignore
└── README.md
```

### `01_datos/`

Contiene la base utilizada para los análisis y los archivos públicos necesarios para reproducir su generación.

La base `nacimientos_guatemala.rds` puede eliminarse y volver a generarse ejecutando el script correspondiente.

### `01_datos/datos_referencia/`

Contiene fuentes públicas externas necesarias para ejecutar los scripts, actualmente el catálogo territorial de SEGEPLAN.

### `02_scripts/`

Contiene el código utilizado para generar, validar y posteriormente analizar los datos.

Los scripts se numeran según su orden de ejecución.

### `03_resultados/`

Se utilizará para almacenar las figuras, tablas y otros productos derivados del análisis.

Los resultados deben poder regenerarse mediante los scripts y documentos Quarto correspondientes.

## Cómo reproducir la base

1.  Clonar o descargar este repositorio.
2.  Abrir `bajo-peso-nacer-guatemala.Rproj` en RStudio.
3.  Verificar que el archivo territorial de SEGEPLAN esté disponible en:

``` text
01_datos/datos_referencia/catalogo_municipios_segeplan_2026.xlsx
```

4.  Instalar los paquetes de R requeridos por el script si aún no están disponibles.
5.  Ejecutar desde la raíz del proyecto:

``` r
source("02_scripts/01_generar_base_sintetica.R")
```

6.  El script generará:

``` text
01_datos/nacimientos_guatemala.rds
```

Durante la ejecución se realizan controles automáticos sobre:

- número total de registros;
- años incluidos;
- número de departamentos y municipios;
- coherencia entre códigos departamentales y municipales;
- porcentaje de problemas críticos;
- porcentaje de datos ausentes;
- pesos desconocidos y extremos;
- elegibilidad para los análisis nacional y territorial.

Si alguno de los criterios definidos no se cumple, la ejecución se detiene.

## Reproducibilidad

El proyecto sigue varios principios básicos de investigación reproducible:

- los datos utilizados en los análisis pueden regenerarse mediante código;
- se utiliza una semilla fija para controlar la generación aleatoria;
- las rutas son relativas a la raíz del proyecto;
- los parámetros de simulación están definidos explícitamente en el script;
- las reglas de validación se ejecutan automáticamente;
- los datos originales de referencia no se modifican durante el análisis;
- los resultados derivados se almacenan separadamente de los datos;
- Git y GitHub se utilizan para mantener el historial de cambios.

La generación de la base se realiza dentro de un entorno local de R.

## Herramientas utilizadas

- **R:** generación, validación y análisis de los datos.
- **RStudio:** desarrollo y organización del proyecto.
- **Quarto:** elaboración del informe reproducible.
- **Git y GitHub:** control de versiones y publicación del proyecto.
- **SEGEPLAN:** fuente pública del catálogo territorial utilizado en la simulación.

## Limitaciones

Los datos disponibles en este repositorio son artificiales y fueron diseñados para fines docentes.

Por lo tanto:

- las prevalencias obtenidas no constituyen estimaciones oficiales;
- las asociaciones entre variables reflejan parcialmente las reglas utilizadas para simularlas;
- no pueden realizarse inferencias causales a partir de estos datos;
- los valores territoriales no deben utilizarse para comparar oficialmente municipios o departamentos;
- la ausencia de edad gestacional impide diferenciar bajo peso asociado a prematuridad de bajo peso asociado a restricción del crecimiento fetal;
- los resultados deben interpretarse como demostraciones de métodos de análisis y visualización.

## Estado actual

Actualmente se encuentra disponible:

- el script reproducible para generar 100 000 registros;
- la base generada para 2009–2024;
- el catálogo territorial de referencia;
- los controles automáticos de calidad y elegibilidad.

Las siguientes etapas del proyecto contemplan:

1.  desarrollar el análisis exploratorio;
2.  construir el diccionario y las funciones de validación;
3.  elaborar las visualizaciones principales;
4.  documentar las decisiones de limpieza;
5.  integrar el análisis en un informe reproducible mediante Quarto.

## Uso de inteligencia artificial

Se utilizó **ChatGPT (OpenAI)** como herramienta de apoyo para revisar la estructura del proyecto, desarrollar y depurar código en R y apoyar la redacción de documentación.

La definición de las preguntas de investigación, las decisiones metodológicas, la revisión del código y la interpretación de los resultados permanecen bajo responsabilidad del autor.
