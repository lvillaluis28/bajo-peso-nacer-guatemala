# Bajo peso al nacer en Guatemala

**Autor:** Luis Villaseñor\
**Período de estudio:** 2009–2024\
**Lenguaje:** R\
**Estado:** en desarrollo

> **Importante:** los registros individuales contenidos en este repositorio son datos generados artificialmente con fines docentes y de reproducibilidad. Ninguna fila corresponde a una persona real. La simulación reproduce de manera aproximada patrones demográficos, temporales y epidemiológicos plausibles de los nacimientos en Guatemala, pero no debe utilizarse para producir estimaciones oficiales.

## Resumen del proyecto

El bajo peso al nacer es un importante indicador de salud maternoinfantil y se asocia con mayor riesgo de morbimortalidad neonatal, alteraciones del crecimiento y consecuencias posteriores para la salud.

Este proyecto desarrolla un flujo reproducible en R para explorar la evolución del peso al nacer y del bajo peso al nacer en Guatemala entre 2009 y 2024. Para permitir que todo el análisis pueda publicarse y ejecutarse sin utilizar información individual confidencial, se generó una base de **100.000 nacimientos ficticios** mediante simulación reproducible.

La base incluye información sobre fecha y peso al nacer, sexo, edad y características maternas, lugar y atención del parto, vía del parto y departamento y municipio de residencia materna.

La simulación incorpora de forma deliberada patrones temporales y territoriales plausibles, entre ellos disminución del número de nacimientos, aumento progresivo del bajo peso al nacer, estacionalidad, cambios en la distribución de la edad materna, diferencias territoriales, cambios en la atención y lugar del parto y una pequeña proporción de registros con problemas de calidad o datos ausentes.

El objetivo es disponer de una base suficientemente realista para desarrollar un flujo completo y reproducible de **generación, validación, limpieza, análisis exploratorio y visualización de datos**.

## Preguntas exploratorias

1.  ¿Cómo cambia la frecuencia de bajo peso al nacer entre 2009 y 2024?

2.  ¿Cómo evoluciona la distribución del peso al nacer durante el período de estudio?

3.  ¿Existe un patrón estacional del bajo peso al nacer según el mes de nacimiento?

4.  ¿Qué diferencias se observan entre departamentos de residencia materna?

5.  ¿Cómo varía el bajo peso al nacer según la edad materna?

6.  ¿Qué efecto tienen los criterios de calidad y los datos ausentes sobre la muestra disponible para el análisis?

## Datos

### Base simulada

La base inicial contiene **100 000 registros generados artificialmente** correspondientes al período 2009–2024.

Se crea mediante:

```         
02_scripts/01_generar_base_sintetica.R
```

y se guarda como:

```         
01_datos/nacimientos_guatemala.rds
```

La generación utiliza una semilla fija:

```         
set.seed(20261116)
```

Por lo tanto, ejecutar nuevamente el script con las mismas dependencias y archivos de referencia produce la misma base.

La simulación no selecciona, modifica ni anonimiza registros individuales de una base real. Cada observación se genera mediante distribuciones probabilísticas definidas explícitamente en el código.

### Información territorial

Los nombres y códigos municipales provienen de un archivo público de la **Secretaría de Planificación y Programación de la Presidencia de Guatemala (SEGEPLAN)**:

```         
01_datos/datos_referencia/catalogo_municipios_segeplan_2026.xlsx
```

El catálogo contiene los **340 municipios de Guatemala** y se utiliza para asignar nombres y códigos territoriales y para aproximar el peso relativo de los municipios mediante información poblacional.

Los siete municipios incorporados después de 2009 solo pueden recibir registros a partir del año correspondiente definido en el script.

## Definición de bajo peso al nacer

Se define bajo peso al nacer como:

**peso al nacer \<2500 gramos**

La variable `low_birth_weight` toma los valores:

- `1`: peso \<2500 g;

- `0`: peso ≥2500 g;

- `NA`: peso desconocido.

Para el análisis se consideran plausibles los pesos comprendidos entre **500 y 5000 g**.

Los valores inferiores a 500 g o superiores a 5000 g se introducen deliberadamente en una pequeña proporción de registros para permitir ejercicios de validación y limpieza, pero no se consideran elegibles para la muestra analítica.

## Problemas de calidad y datos ausentes

La base inicial contiene problemas de calidad introducidos deliberadamente para reproducir situaciones frecuentes en bases administrativas.

| **Problema**                    | **Proporción** |
|---------------------------------|----------------|
| Peso al nacer desconocido       | 0,6 %          |
| Peso extremo (\<500 o \>5000 g) | 0,4 %          |
| Fecha de nacimiento faltante    | 0,4 %          |
| Residencia materna faltante     | 0,9 %          |
| **Algún problema crítico**      | **2,3 %**      |

También se permiten valores ausentes en variables maternas como edad, educación, pertenencia indígena y estado marital. Estos registros no se eliminan automáticamente, ya que la presencia de `NA` en estas variables no impide necesariamente los análisis principales.

## Preparación de la muestra analítica

El script:

```         
02_scripts/02_preparar_base_analitica.R
```

aplica los criterios de exclusión de forma secuencial y registra una única causa principal para cada registro excluido.

La muestra resultante se guarda como:

```         
01_datos/nacimientos_analisis.rds
```

El flujo de exclusiones también se representa gráficamente en:

```         
03_resultados/01_grafico-exclusiones.png
```

Para este proyecto exploratorio se utiliza una **muestra analítica única**, que exige peso plausible, fecha de nacimiento conocida y municipio de residencia materna identificado.

Las variables `eligible_national_lbw` y `eligible_spatial_lbw` permanecen en la base original para mostrar que los criterios de elegibilidad pueden variar según la pregunta de investigación. Por ejemplo, un análisis exclusivamente nacional puede utilizar registros con peso válido aunque el municipio sea desconocido.

## Análisis exploratorio

El análisis exploratorio se realiza mediante:

```         
02_scripts/03_analisis_exploratorio.R
```

El script describe la muestra analítica y genera visualizaciones reproducibles para examinar seis aspectos principales:

1.  distribución del peso al nacer;

2.  tendencia anual de la prevalencia de bajo peso al nacer;

3.  patrón estacional según mes de nacimiento;

4.  diferencias de prevalencia entre departamentos;

5.  prevalencia según grupo de edad materna;

6.  porcentaje de datos ausentes en variables maternas.

Las prevalencias por año, mes, departamento y grupo de edad se acompañan de **intervalos de confianza del 95 %**. Para las proporciones se utilizan intervalos de Wilson.

Las visualizaciones utilizan líneas cuando el eje representa una secuencia temporal y gráficos basados en posición para comparar categorías, evitando representaciones innecesariamente complejas o potencialmente engañosas.

## Diccionario de variables

El diccionario se genera mediante:

```         
02_scripts/04_generar_diccionario.R
```

y se guarda como:

```         
04_documentacion/diccionario_variables.xlsx
```

El archivo documenta para cada variable:

- nombre;

- descripción;

- tipo de variable;

- unidad de medida;

- valores esperados;

- posibilidad de valores ausentes.

Los tipos de variable se definen según su naturaleza estadística, por ejemplo, cuantitativa continua, cuantitativa discreta, categórica nominal, categórica nominal binaria y categórica ordina.

## Variables principales

| **Variable** | **Descripción** |
|----|----|
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
| `quality_issue` | Problema crítico de calidad identificado |
| `eligible_national_lbw` | Elegibilidad para análisis nacional |
| `eligible_spatial_lbw` | Elegibilidad para análisis territorial |

La descripción completa y los valores esperados se encuentran en el diccionario de variables.

## Patrones incorporados en la simulación

La generación de los datos no supone independencia absoluta entre las variables.

El riesgo de bajo peso al nacer depende probabilísticamente de distintas características para permitir que el análisis exploratorio identifique patrones epidemiológicos plausibles, entre ellos:

- mayor frecuencia en edades maternas extremas;

- diferencias territoriales;

- diferencias según sexo;

- variación según educación materna;

- aumento de la frecuencia de bajo peso al nacer entre 2009 y 2024;

- mayor frecuencia aproximadamente entre mayo y agosto.

Estas relaciones son **parámetros de simulación** y no deben interpretarse como estimaciones causales ni como resultados epidemiológicos obtenidos de la población guatemalteca.

## Organización del proyecto

``` text
bajo-peso-nacer-guatemala/
├── 01_datos/
│   ├── nacimientos_guatemala.rds
│   ├── nacimientos_analisis.rds
│   └── datos_referencia/
│       └── catalogo_municipios_segeplan_2026.xlsx
│
├── 02_scripts/
│   ├── 01_generar_base_sintetica.R
│   ├── 02_preparar_base_analitica.R
│   ├── 03_analisis_exploratorio.R
│   └── 04_generar_diccionario.R
│
├── 03_resultados/
│   ├── 01_grafico-exclusiones.png
│   ├── 02_grafico-distribucion-peso.png
│   ├── 03_grafico-tendencia-lbw.png
│   ├── 04_grafico-estacionalidad-lbw.png
│   ├── 05_grafico-lbw-departamento.png
│   ├── 06_grafico-lbw-edad-materna.png
│   └── 07_grafico-datos-ausentes.png
│
├── 04_documentacion/
│   └── diccionario_variables.xlsx
│
├── bajo-peso-nacer-guatemala.Rproj
├── .gitignore
└── README.md
```

### `01_datos/`

Contiene la base simulada, la muestra analítica y los archivos públicos de referencia necesarios para reproducir el proceso.

### `02_scripts/`

Contiene los scripts de R numerados según su orden de ejecución.

### `03_resultados/`

Contiene productos derivados del análisis, principalmente figuras reproducibles.

### `04_documentacion/`

Contiene documentación complementaria del proyecto, actualmente el diccionario de variables.

## Cómo reproducir el proyecto

1.  Clonar o descargar este repositorio.

2.  Abrir `bajo-peso-nacer-guatemala.Rproj` en RStudio.

3.  Verificar que el catálogo territorial esté disponible en:

```         

01_datos/datos_referencia/catalogo_municipios_segeplan_2026.xlsx
```

4.  Instalar los paquetes requeridos por los scripts si aún no están disponibles.

5.  Ejecutar los scripts desde la raíz del proyecto y en el siguiente orden:

``` r
source("02_scripts/01_generar_base_sintetica.R")
source("02_scripts/02_preparar_base_analitica.R")
source("02_scripts/03_analisis_exploratorio.R")
source("02_scripts/04_generar_diccionario.R")
```

La secuencia completa es:

``` text
catálogo territorial
        ↓
generación de 100 000 registros
        ↓
validación de la base simulada
        ↓
aplicación de criterios de exclusión
        ↓
muestra analítica
        ↓
análisis exploratorio y visualizaciones
        ↓
documentación de variables
```

Los productos derivados pueden eliminarse y regenerarse ejecutando nuevamente los scripts correspondientes.

## Validaciones automáticas

Durante la generación y preparación de los datos se realizan controles sobre:

- número total de registros;

- período de estudio;

- número de departamentos y municipios;

- formato y coherencia de códigos territoriales;

- porcentaje de problemas críticos;

- porcentaje de datos ausentes;

- presencia de pesos desconocidos o extremos;

- criterios de elegibilidad;

- tamaño final de la muestra analítica.

Si alguna de las condiciones definidas no se cumple, la ejecución se detiene.

## Reproducibilidad

El proyecto sigue principios básicos de investigación reproducible:

- los datos utilizados en los análisis pueden regenerarse mediante código;

- se utiliza una semilla fija para controlar la generación aleatoria;

- las rutas se definen de forma relativa a la raíz del proyecto;

- los parámetros de simulación están documentados en el código;

- las reglas de validación se ejecutan automáticamente;

- las fuentes de referencia se mantienen separadas de los datos derivados;

- la preparación de la muestra analítica se realiza mediante código;

- los resultados se almacenan separadamente de los datos;

- los archivos generados utilizan nombres estables y descriptivos;

- Git y GitHub mantienen el historial de modificaciones.

## Herramientas utilizadas

- **R:** generación, validación, limpieza y análisis de los datos.

- **RStudio:** desarrollo y organización del proyecto.

- **ggplot2:** elaboración de visualizaciones.

- **openxlsx:** generación del diccionario de variables en formato Excel.

- **Quarto:** elaboración del informe reproducible.

- **Git y GitHub:** control de versiones y publicación del proyecto.

- **SEGEPLAN:** fuente pública de información territorial utilizada en la simulación.

## Limitaciones

Los datos disponibles en este repositorio son artificiales y fueron diseñados con fines docentes.

Por lo tanto:

- las prevalencias obtenidas no constituyen estimaciones oficiales;

- las asociaciones observadas reflejan parcialmente las reglas utilizadas para generar los datos;

- no pueden realizarse inferencias causales a partir de estos registros;

- las diferencias territoriales no deben utilizarse para realizar comparaciones oficiales entre municipios o departamentos;

- la ausencia de edad gestacional impide diferenciar bajo peso asociado a prematuridad de bajo peso asociado a restricción del crecimiento fetal;

- los resultados deben interpretarse como demostraciones de métodos de manejo, validación, análisis y visualización de datos.

## Estado actual

Actualmente se encuentran implementados:

- generación reproducible de 100 000 registros ficticios;

- validación automática de la base generada;

- preparación de una muestra analítica de 97 700 registros;

- documentación gráfica del flujo de exclusiones;

- análisis exploratorio de peso al nacer y bajo peso al nacer;

- análisis temporal, estacional, territorial y por edad materna;

- evaluación gráfica de datos ausentes;

- generación reproducible del diccionario de variables.

La siguiente etapa consiste en integrar estos elementos en un **informe reproducible mediante Quarto**, combinando texto, código, resultados y visualizaciones.

## Uso de inteligencia artificial

Se utilizó **ChatGPT (OpenAI)** como herramienta de apoyo para revisar la estructura del proyecto, apoyar la redacción de documentación y desarrollar y depurar código en R

La definición de las preguntas de investigación, las decisiones metodológicas, la revisión del código y la interpretación de los resultados permanecen bajo responsabilidad del autor.
