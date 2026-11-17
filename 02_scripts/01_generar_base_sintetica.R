# =============================================================================
# 01_generar_base_nacimientos.R
# =============================================================================
#
# PROYECTO:
#   Bajo peso al nacer en Guatemala: análisis descriptivo reproducible
#
# PROPÓSITO:
#   Generar una base de datos con 100 000 nacimientos ficticios para
#   ejercicios reproducibles de limpieza, validación y análisis descriptivo.
#
# IMPORTANTE:
#   - Ninguna fila corresponde a una persona real.
#   - Los patrones agregados se parametrizan para ser plausibles y aproximarse
#     a características observadas en registros de nacimientos de Guatemala,
#     pero los datos individuales son generados completamente por simulación.
#   - Los nombres y códigos territoriales provienen de una fuente pública.
#
# REPRODUCIBILIDAD:
#   - Se utiliza una semilla fija.
#   - Todos los parámetros relevantes se encuentran al inicio del script.
#   - Se utilizan rutas relativas al proyecto.
#   - El script contiene controles automáticos que detienen la ejecución si
#     la base generada no cumple las reglas definidas.
#
# EJECUCIÓN:
#   Abrir el proyecto de R/RStudio desde su carpeta raíz y ejecutar:
#
#     source("02_scripts/01_generar_base_nacimientos.R")
#
# PRODUCTOS:
#   01_datos/nacimientos_guatemala.rds
#   01_datos/datos_referencia/catalogo_municipios_segeplan_2026.xlsx
#
# =============================================================================


local({

# =============================================================================
# 1. PAQUETES Y CONFIGURACIÓN GENERAL
# =============================================================================

paquetes_necesarios <- c(
  "dplyr",
  "tidyr",
  "tibble",
  "readxl"
)

paquetes_faltantes <- setdiff(
  paquetes_necesarios,
  rownames(installed.packages())
)

if (length(paquetes_faltantes) > 0L) {
  stop(
    paste0(
      "Faltan paquetes necesarios: ",
      paste(paquetes_faltantes, collapse = ", "),
      ".\nInstálalos antes de ejecutar el script."
    )
  )
}

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readxl)
})

# Semilla fija: ejecutar el script varias veces produce la misma base.
SEMILLA <- 20261116L

set.seed(SEMILLA)

# Número total de registros.
N_TOTAL <- 100000L

# Periodo de estudio.
ANIOS <- 2009:2024

# Carpetas necesarias para los productos de este script.
dir.create(
  file.path("01_datos", "datos_referencia"),
  showWarnings = FALSE,
  recursive = TRUE
)

# Rutas de los archivos utilizados por este script.
RUTA_CATALOGO <- file.path(
  "01_datos",
  "datos_referencia",
  "catalogo_municipios_segeplan_2026.xlsx"
)

RUTA_RDS <- file.path(
  "01_datos",
  "nacimientos_guatemala.rds"
)


# =============================================================================
# 2. FUNCIONES AUXILIARES
# =============================================================================

# -----------------------------------------------------------------------------
# 2.1. Repartir un total entero según pesos
# -----------------------------------------------------------------------------
#
# Evita que el redondeo haga que la suma final sea distinta del total deseado.
# Se utiliza, por ejemplo, para repartir exactamente 100 000 registros entre
# los años 2009-2024.

repartir_enteros <- function(pesos, total) {

  stopifnot(
    length(pesos) > 0L,
    all(is.finite(pesos)),
    all(pesos >= 0),
    sum(pesos) > 0,
    total >= 0
  )

  esperado <- pesos / sum(pesos) * total
  resultado <- floor(esperado)

  faltantes <- total - sum(resultado)

  if (faltantes > 0L) {

    residuos <- esperado - resultado

    posiciones <- order(
      residuos,
      decreasing = TRUE
    )[seq_len(faltantes)]

    resultado[posiciones] <-
      resultado[posiciones] + 1L
  }

  as.integer(resultado)
}


# -----------------------------------------------------------------------------
# 2.2. Interpolación lineal entre dos distribuciones
# -----------------------------------------------------------------------------

interpolar_probabilidades <- function(
    anio,
    inicio,
    fin,
    anio_inicio = 2009,
    anio_fin = 2024
) {

  progreso <- (anio - anio_inicio) /
    (anio_fin - anio_inicio)

  p <- inicio + progreso * (fin - inicio)

  p[p < 0] <- 0

  p / sum(p)
}


# -----------------------------------------------------------------------------
# 2.3. Normalizar nombres de columnas
# -----------------------------------------------------------------------------

normalizar_nombre <- function(x) {

  x <- iconv(
    x,
    from = "",
    to = "ASCII//TRANSLIT"
  )

  x <- tolower(x)

  x <- gsub(
    "[^a-z0-9]+",
    "_",
    x
  )

  x <- gsub(
    "^_+|_+$",
    "",
    x
  )

  x
}


# -----------------------------------------------------------------------------
# 2.4. Encontrar una columna usando varios patrones posibles
# -----------------------------------------------------------------------------

encontrar_columna <- function(nombres, patrones, descripcion) {

  for (patron in patrones) {

    coincidencia <- grep(
      patron,
      nombres,
      value = TRUE
    )

    if (length(coincidencia) > 0L) {
      return(coincidencia[1])
    }
  }

  stop(
    paste0(
      "No se pudo identificar la columna de ",
      descripcion,
      " en el catálogo territorial."
    )
  )
}


# -----------------------------------------------------------------------------
# 2.5. Normal truncada sin paquetes adicionales
# -----------------------------------------------------------------------------
#
# Se utiliza para generar pesos dentro de intervalos definidos sin crear
# acumulaciones artificiales exactamente en los límites.

rnorm_truncada <- function(
    n,
    media,
    de,
    minimo,
    maximo
) {

  if (n == 0L) {
    return(numeric(0))
  }

  limite_inferior <- pnorm(
    (minimo - media) / de
  )

  limite_superior <- pnorm(
    (maximo - media) / de
  )

  u <- runif(
    n,
    min = limite_inferior,
    max = limite_superior
  )

  media + de * qnorm(u)
}


# -----------------------------------------------------------------------------
# 2.6. Función logística
# -----------------------------------------------------------------------------

logit <- function(p) {
  log(p / (1 - p))
}


# =============================================================================
# 3. CATÁLOGO PÚBLICO DE MUNICIPIOS DE GUATEMALA
# =============================================================================
#
# El script utiliza un catálogo territorial público de SEGEPLAN.
#
# La fuente pública contiene 340 municipalidades y población municipal 2025.
# La población se utiliza solo como aproximación pública del peso relativo de
# cada municipio dentro de su departamento. La distribución departamental de
# los nacimientos se parametriza por separado.
# =============================================================================

departamentos <- tibble(
  maternal_department_code = sprintf("%02d", 1:22),
  maternal_department_name = c(
    "Guatemala",
    "El Progreso",
    "Sacatepéquez",
    "Chimaltenango",
    "Escuintla",
    "Santa Rosa",
    "Sololá",
    "Totonicapán",
    "Quetzaltenango",
    "Suchitepéquez",
    "Retalhuleu",
    "San Marcos",
    "Huehuetenango",
    "Quiché",
    "Baja Verapaz",
    "Alta Verapaz",
    "Petén",
    "Izabal",
    "Zacapa",
    "Chiquimula",
    "Jalapa",
    "Jutiapa"
  )
)


if (!file.exists(RUTA_CATALOGO)) {
  stop(
    paste0(
      "No se encontró el catálogo municipal de SEGEPLAN en: ",
      RUTA_CATALOGO
    )
  )
}

catalogo_original <- readxl::read_excel(
  path = RUTA_CATALOGO,
  sheet = "CALCULO 2026"
)

columnas_necesarias <- c(
  "Código de municipio",
  "Municipios b/",
  "Población total 2025c/"
)

if (!all(columnas_necesarias %in% names(catalogo_original))) {
  stop(
    paste0(
      "El archivo de SEGEPLAN no contiene las columnas esperadas: ",
      paste(columnas_necesarias, collapse = ", ")
    )
  )
}

catalogo_municipios <- catalogo_original |>
  transmute(
    maternal_municipality_code =
      sprintf(
        "%04d",
        as.integer(`Código de municipio`)
      ),
    maternal_municipality_name =
      trimws(
        as.character(`Municipios b/`)
      ),
    population_2025 =
      as.numeric(`Población total 2025c/`),
    maternal_department_code =
      substr(
        maternal_municipality_code,
        1,
        2
      )
  ) |>
  filter(
    !is.na(maternal_municipality_code),
    !is.na(maternal_municipality_name),
    !is.na(population_2025)
  ) |>
  left_join(
    departamentos,
    by = "maternal_department_code"
  ) |>
  distinct(
    maternal_municipality_code,
    .keep_all = TRUE
  ) |>
  mutate(
    first_year_available =
      case_when(
        maternal_municipality_code == "1713" ~ 2011L,
        maternal_municipality_code == "1714" ~ 2014L,
        maternal_municipality_code == "1230" ~ 2014L,
        maternal_municipality_code == "1021" ~ 2014L,
        maternal_municipality_code == "1911" ~ 2014L,
        maternal_municipality_code == "0514" ~ 2015L,
        maternal_municipality_code == "1333" ~ 2015L,
        TRUE ~ 2009L
      )
  ) |>
  select(
    maternal_department_code,
    maternal_department_name,
    maternal_municipality_code,
    maternal_municipality_name,
    population_2025,
    first_year_available
  )

stopifnot(
  nrow(catalogo_municipios) == 340L,
  n_distinct(catalogo_municipios$maternal_municipality_code) == 340L,
  n_distinct(catalogo_municipios$maternal_department_code) == 22L,
  all(
    catalogo_municipios$maternal_department_code %in%
      departamentos$maternal_department_code
  ),
  all(catalogo_municipios$population_2025 > 0)
)


# =============================================================================
# 4. PARÁMETROS TEMPORALES DE LA SIMULACIÓN
# =============================================================================
#
# Los conteos que siguen se utilizan como PESOS RELATIVOS para
# distribuir los 100 000 registros sintéticos entre los años.
#
# =============================================================================

parametros_anuales <- tibble(

  birth_year = ANIOS,

  births_reference = c(
    346603,
    356999,
    368595,
    383496,
    382206,
    381116,
    386177,
    385183,
    376132,
    377751,
    361394,
    336588,
    340096,
    340700,
    326709,
    277497
  ),

  # Prevalencia anual objetivo aproximada de bajo peso al nacer.
  target_lbw_pct = c(
     9.66,
     9.52,
    10.30,
    10.70,
    11.10,
    11.70,
    11.90,
    11.90,
    12.30,
    12.40,
    12.60,
    11.60,
    12.50,
    13.10,
    13.30,
    13.76
  ),

  # Media aproximada deseada del peso al nacer.
  # Se utiliza como parámetro de simulación.
  target_mean_weight_g = c(
    3143,
    3130,
    3115,
    3100,
    3085,
    3070,
    3058,
    3050,
    3042,
    3035,
    3025,
    3050,
    3035,
    3018,
    3008,
    2998
  )
)


# Repartir exactamente los 100 000 registros según el peso de cada año.

parametros_anuales <- parametros_anuales |>
  mutate(
    synthetic_births =
      repartir_enteros(
        births_reference,
        N_TOTAL
      )
  )

stopifnot(
  sum(parametros_anuales$synthetic_births) ==
    N_TOTAL
)


# =============================================================================
# 5. PARÁMETROS TERRITORIALES
# =============================================================================
#
# La distribución departamental se basa en pesos relativos plausibles.
# Dentro de cada departamento, el catálogo público usa población 2025 como
# aproximación del peso relativo de los municipios.
#
# Las prevalencias departamentales se usan solo para construir diferencias de
# riesgo sintéticas. 
# =============================================================================

parametros_departamentales <- tibble(

  maternal_department_code =
    sprintf("%02d", 1:22),

  births_reference = c(
    943066,  # Guatemala
     59806,  # El Progreso
    102679,  # Sacatepéquez
    236710,  # Chimaltenango
    241129,  # Escuintla
    130501,  # Santa Rosa
    152841,  # Sololá
    190134,  # Totonicapán
    302091,  # Quetzaltenango
    205104,  # Suchitepéquez
    119982,  # Retalhuleu
    444132,  # San Marcos
    563176,  # Huehuetenango
    449647,  # Quiché
    119237,  # Baja Verapaz
    529567,  # Alta Verapaz
    225934,  # Petén
    150611,  # Izabal
     88715,  # Zacapa
    165427,  # Chiquimula
    139052,  # Jalapa
    167701   # Jutiapa
  ),

  department_lbw_pct = c(
    12.50,
    10.90,
    14.90,
    14.00,
     9.65,
    11.10,
    12.20,
    16.50,
    17.60,
     7.82,
     7.96,
    12.00,
     9.36,
    11.60,
    12.80,
    10.30,
     7.94,
     8.52,
    13.70,
    13.70,
    15.10,
    10.60
  )
) |>
  left_join(
    departamentos,
    by = "maternal_department_code"
  ) |>
  mutate(

    department_probability =
      births_reference /
      sum(births_reference),

    # Efecto territorial moderado sobre el riesgo de LBW.
    # Se reduce la magnitud del contraste departamental para evitar que la
    # simulación reproduzca exactamente las prevalencias agregadas de origen.
    department_risk_effect =
      0.65 * (
        logit(department_lbw_pct / 100) -
          weighted.mean(
            logit(department_lbw_pct / 100),
            births_reference
          )
      )
  )


# =============================================================================
# 6. CREAR EL ESQUELETO DE 100 000 NACIMIENTOS
# =============================================================================

base_sintetica <- parametros_anuales |>
  select(
    birth_year,
    synthetic_births
  ) |>
  tidyr::uncount(
    weights = synthetic_births
  ) |>
  mutate(
    simulation_row = row_number()
  )


stopifnot(
  nrow(base_sintetica) == N_TOTAL
)


# =============================================================================
# 7. FECHA DE NACIMIENTO
# =============================================================================
#
# Primero se genera una fecha válida para todos los registros.
# Más adelante se introducirá de manera deliberada una pequeña proporción de
# fechas faltantes para practicar controles de calidad.
# =============================================================================

generar_fecha_anual <- function(anio, n) {

  inicio <- as.Date(
    paste0(anio, "-01-01")
  )

  fin <- as.Date(
    paste0(anio, "-12-31")
  )

  dias <- as.integer(
    fin - inicio
  ) + 1L

  inicio +
    sample(
      0:(dias - 1L),
      size = n,
      replace = TRUE
    )
}


base_sintetica <- base_sintetica |>
  group_by(birth_year) |>
  mutate(
    birth_date =
      generar_fecha_anual(
        first(birth_year),
        n()
      )
  ) |>
  ungroup() |>
  mutate(
    birth_month =
      as.integer(
        format(
          birth_date,
          "%m"
        )
      )
  )


# =============================================================================
# 8. SEXO DEL RECIÉN NACIDO
# =============================================================================

base_sintetica <- base_sintetica |>
  mutate(
    sex = sample(
      c("Male", "Female"),
      size = n(),
      replace = TRUE,
      prob = c(0.512, 0.488)
    )
  )


# =============================================================================
# 9. DEPARTAMENTO DE RESIDENCIA MATERNA
# =============================================================================

base_sintetica$maternal_department_code <-
  sample(
    parametros_departamentales$maternal_department_code,
    size = nrow(base_sintetica),
    replace = TRUE,
    prob =
      parametros_departamentales$department_probability
  )

base_sintetica <- base_sintetica |>
  left_join(
    parametros_departamentales |>
      select(
        maternal_department_code,
        maternal_department_name,
        department_risk_effect
      ),
    by = "maternal_department_code"
  )


# =============================================================================
# 10. MUNICIPIO DE RESIDENCIA MATERNA
# =============================================================================
#
# Para cada combinación año-departamento:
#
#   - se excluyen municipios que todavía no están disponibles en ese año;
#   - los municipios se muestrean según su peso poblacional relativo dentro
#     del departamento;
#   - la población funciona solo como proxy público del tamaño municipal.
# =============================================================================

base_sintetica$maternal_municipality_code <-
  NA_character_

combinaciones_territoriales <- base_sintetica |>
  distinct(
    birth_year,
    maternal_department_code
  )


for (i in seq_len(nrow(combinaciones_territoriales))) {

  anio_actual <-
    combinaciones_territoriales$birth_year[i]

  departamento_actual <-
    combinaciones_territoriales$maternal_department_code[i]

  filas <- which(
    base_sintetica$birth_year == anio_actual &
      base_sintetica$maternal_department_code ==
        departamento_actual
  )

  municipios_disponibles <- catalogo_municipios |>
    filter(
      maternal_department_code ==
        departamento_actual,
      first_year_available <=
        anio_actual
    )

  stopifnot(
    nrow(municipios_disponibles) > 0L
  )

  base_sintetica$maternal_municipality_code[filas] <-
    sample(
      municipios_disponibles$maternal_municipality_code,
      size = length(filas),
      replace = TRUE,
      prob =
        municipios_disponibles$population_2025
    )
}


# Asociar nombre municipal.

base_sintetica <- base_sintetica |>
  left_join(
    catalogo_municipios |>
      select(
        maternal_municipality_code,
        maternal_municipality_name
      ),
    by = "maternal_municipality_code"
  )


# -----------------------------------------------------------------------------
# 10.1. Garantizar representación de los 340 municipios en el periodo completo
# -----------------------------------------------------------------------------
#
# Con 100 000 registros es muy probable que todos aparezcan espontáneamente,
# pero esta pequeña corrección evita que un municipio muy pequeño desaparezca
# únicamente por azar.
#
# Para no alterar las reglas históricas, cualquier municipio ausente se asigna
# a una fila de 2024 de su mismo departamento.

municipios_ausentes <- setdiff(
  catalogo_municipios$maternal_municipality_code,
  unique(
    base_sintetica$maternal_municipality_code
  )
)

if (length(municipios_ausentes) > 0L) {

  for (codigo_ausente in municipios_ausentes) {

    departamento_ausente <-
      catalogo_municipios |>
      filter(
        maternal_municipality_code ==
          codigo_ausente
      ) |>
      pull(
        maternal_department_code
      )

    nombre_ausente <-
      catalogo_municipios |>
      filter(
        maternal_municipality_code ==
          codigo_ausente
      ) |>
      pull(
        maternal_municipality_name
      )

    candidatos <- which(
      base_sintetica$birth_year == 2024 &
        base_sintetica$maternal_department_code ==
          departamento_ausente
    )

    fila_reemplazo <- sample(
      candidatos,
      size = 1L
    )

    base_sintetica$maternal_municipality_code[
      fila_reemplazo
    ] <- codigo_ausente

    base_sintetica$maternal_municipality_name[
      fila_reemplazo
    ] <- nombre_ausente
  }
}


stopifnot(
  n_distinct(
    base_sintetica$maternal_municipality_code
  ) == 340L
)


# =============================================================================
# 11. EFECTO MUNICIPAL SINTÉTICO
# =============================================================================
#
# Se genera un efecto aleatorio FIJO por municipio.
#
# No proviene de ningún municipio real concreto: su objetivo es crear
# heterogeneidad dentro de los departamentos para que los análisis
# territoriales sean informativos.
# =============================================================================

set.seed(
  SEMILLA + 100L
)

efectos_municipales <- catalogo_municipios |>
  transmute(
    maternal_municipality_code,
    municipality_risk_effect =
      rnorm(
        n(),
        mean = 0,
        sd = 0.22
      )
  )

base_sintetica <- base_sintetica |>
  left_join(
    efectos_municipales,
    by = "maternal_municipality_code"
  )


# =============================================================================
# 12. EDAD MATERNA
# =============================================================================
#
# La distribución cambia progresivamente entre 2009 y 2024:
#
#   - disminuyen los nacimientos de madres adolescentes;
#   - aumenta el peso relativo de los grupos de 25-39 años.
#
# La edad faltante se introduce después y nunca supera el 5%.
# =============================================================================

grupos_edad <- c(
  "<15",
  "15-19",
  "20-24",
  "25-29",
  "30-34",
  "35-39",
  ">=40"
)

prob_edad_2009 <- c(
  0.0072,
  0.1806,
  0.2947,
  0.2373,
  0.1579,
  0.0868,
  0.0355
)

prob_edad_2024 <- c(
  0.0009,
  0.1188,
  0.3016,
  0.2633,
  0.1831,
  0.0998,
  0.0325
)

base_sintetica$maternal_age_group <-
  NA_character_

for (anio in ANIOS) {

  filas <- which(
    base_sintetica$birth_year == anio
  )

  probabilidades <-
    interpolar_probabilidades(
      anio,
      prob_edad_2009,
      prob_edad_2024
    )

  base_sintetica$maternal_age_group[filas] <-
    sample(
      grupos_edad,
      size = length(filas),
      replace = TRUE,
      prob = probabilidades
    )
}


# Generar edad exacta dentro de cada grupo.

base_sintetica <- base_sintetica |>
  mutate(

    maternal_age =
      case_when(

        maternal_age_group == "<15" ~
          sample(
            12:14,
            n(),
            replace = TRUE,
            prob = c(0.10, 0.30, 0.60)
          ),

        maternal_age_group == "15-19" ~
          sample(
            15:19,
            n(),
            replace = TRUE,
            prob = c(0.08, 0.13, 0.20, 0.27, 0.32)
          ),

        maternal_age_group == "20-24" ~
          sample(
            20:24,
            n(),
            replace = TRUE
          ),

        maternal_age_group == "25-29" ~
          sample(
            25:29,
            n(),
            replace = TRUE
          ),

        maternal_age_group == "30-34" ~
          sample(
            30:34,
            n(),
            replace = TRUE
          ),

        maternal_age_group == "35-39" ~
          sample(
            35:39,
            n(),
            replace = TRUE
          ),

        maternal_age_group == ">=40" ~
          pmin(
            round(
              rnorm(
                n(),
                mean = 42.2,
                sd = 2.3
              )
            ),
            49
          ),

        TRUE ~
          NA_real_
      )

  )


# Missing de edad:
# aproximadamente 3.2% en 2009 y menos de 1% en años posteriores.

prob_missing_edad <- tibble(
  birth_year = ANIOS,
  p_missing_age = c(
    0.032,
    0.012,
    0.008,
    0.006,
    0.005,
    0.004,
    0.004,
    0.004,
    0.004,
    0.004,
    0.004,
    0.004,
    0.004,
    0.004,
    0.004,
    0.004
  )
)

base_sintetica <- base_sintetica |>
  left_join(
    prob_missing_edad,
    by = "birth_year"
  ) |>
  mutate(

    missing_age =
      runif(n()) <
      p_missing_age,

    maternal_age =
      if_else(
        missing_age,
        NA_real_,
        maternal_age
      ),

    maternal_age_group =
      if_else(
        missing_age,
        NA_character_,
        maternal_age_group
      )

  ) |>
  select(
    -p_missing_age,
    -missing_age
  )


# =============================================================================
# 13. EDUCACIÓN MATERNA
# =============================================================================
#
# Se simula una disminución de "None" y aumento de "Secondary".
# El missing es deliberado pero se mantiene claramente por debajo del 5%.
# =============================================================================

niveles_educacion <- c(
  "None",
  "Primary",
  "Secondary",
  "Higher education"
)

prob_educacion_2009 <- c(
  0.417,
  0.373,
  0.196,
  0.014
)

prob_educacion_2024 <- c(
  0.173,
  0.419,
  0.377,
  0.031
)

base_sintetica$maternal_education <-
  NA_character_

for (anio in ANIOS) {

  filas <- which(
    base_sintetica$birth_year == anio
  )

  probabilidades <-
    interpolar_probabilidades(
      anio,
      prob_educacion_2009,
      prob_educacion_2024
    )

  base_sintetica$maternal_education[filas] <-
    sample(
      niveles_educacion,
      size = length(filas),
      replace = TRUE,
      prob = probabilidades
    )
}


# Missing de educación: aumenta levemente al final del periodo, sin superar 5%.

base_sintetica <- base_sintetica |>
  mutate(

    p_missing_education =
      case_when(
        birth_year <= 2012 ~ 0.020,
        birth_year <= 2019 ~ 0.015,
        birth_year <= 2022 ~ 0.020,
        birth_year == 2023 ~ 0.030,
        birth_year == 2024 ~ 0.040
      ),

    maternal_education =
      if_else(
        runif(n()) <
          p_missing_education,
        NA_character_,
        maternal_education
      )

  ) |>
  select(
    -p_missing_education
  )


# =============================================================================
# 14. PERTENENCIA INDÍGENA MATERNA
# =============================================================================
#
# Las probabilidades departamentales son parámetros de simulación.
# Sirven para producir heterogeneidad territorial plausible y NO deben citarse
# como estimaciones poblacionales oficiales.
# =============================================================================

prob_indigena_departamento <- tibble(

  maternal_department_code =
    sprintf("%02d", 1:22),

  p_indigenous = c(
    0.12, # Guatemala
    0.08, # El Progreso
    0.55, # Sacatepéquez
    0.65, # Chimaltenango
    0.15, # Escuintla
    0.08, # Santa Rosa
    0.90, # Sololá
    0.95, # Totonicapán
    0.50, # Quetzaltenango
    0.45, # Suchitepéquez
    0.30, # Retalhuleu
    0.35, # San Marcos
    0.60, # Huehuetenango
    0.80, # Quiché
    0.60, # Baja Verapaz
    0.80, # Alta Verapaz
    0.35, # Petén
    0.30, # Izabal
    0.05, # Zacapa
    0.25, # Chiquimula
    0.25, # Jalapa
    0.10  # Jutiapa
  )
)

base_sintetica <- base_sintetica |>
  left_join(
    prob_indigena_departamento,
    by = "maternal_department_code"
  ) |>
  mutate(

    maternal_indigenous_status =
      if_else(
        runif(n()) <
          p_indigenous,
        "Indigenous",
        "Non-Indigenous"
      ),

    # Missing permitido: 2.5%.
    maternal_indigenous_status =
      if_else(
        runif(n()) < 0.025,
        NA_character_,
        maternal_indigenous_status
      )

  ) |>
  select(
    -p_indigenous
  )


# =============================================================================
# 15. ESTADO MARITAL MATERNO
# =============================================================================

categorias_maritales <- c(
  "Single",
  "Married",
  "Consensual union"
)

prob_marital_2009 <- c(
  0.453,
  0.539,
  0.008
)

prob_marital_2024 <- c(
  0.600,
  0.399,
  0.001
)

base_sintetica$maternal_marital_status <-
  NA_character_

for (anio in ANIOS) {

  filas <- which(
    base_sintetica$birth_year == anio
  )

  probabilidades <-
    interpolar_probabilidades(
      anio,
      prob_marital_2009,
      prob_marital_2024
    )

  base_sintetica$maternal_marital_status[filas] <-
    sample(
      categorias_maritales,
      size = length(filas),
      replace = TRUE,
      prob = probabilidades
    )
}


# Missing permitido: 1.5%.

base_sintetica <- base_sintetica |>
  mutate(

    maternal_marital_status =
      if_else(
        runif(n()) < 0.015,
        NA_character_,
        maternal_marital_status
      )

  )


# =============================================================================
# 16. LUGAR Y ATENCIÓN DEL PARTO
# =============================================================================
#
# El parto en establecimiento de salud aumenta progresivamente durante el
# periodo, mientras el parto domiciliario disminuye.
# =============================================================================

base_sintetica <- base_sintetica |>
  mutate(

    progreso =
      (birth_year - 2009) /
      (2024 - 2009),

    p_health_facility =
      0.485 +
      progreso * (0.781 - 0.485),

    p_home =
      0.505 +
      progreso * (0.206 - 0.505),

    p_other =
      pmax(
        0,
        1 -
          p_health_facility -
          p_home
      )

  )


base_sintetica$birth_place_group <-
  vapply(
    seq_len(nrow(base_sintetica)),
    function(i) {

      sample(
        c(
          "Health facility",
          "Home",
          "Other"
        ),
        size = 1L,
        prob = c(
          base_sintetica$p_health_facility[i],
          base_sintetica$p_home[i],
          base_sintetica$p_other[i]
        )
      )
    },
    character(1)
  )


# Atención del parto condicionada por lugar.

base_sintetica$birth_attendance <-
  NA_character_

es_establecimiento <-
  base_sintetica$birth_place_group ==
  "Health facility"

es_domicilio <-
  base_sintetica$birth_place_group ==
  "Home"

es_otro <-
  base_sintetica$birth_place_group ==
  "Other"


# Establecimientos de salud.

base_sintetica$birth_attendance[
  es_establecimiento
] <- sample(
  c(
    "Medical",
    "Paramedical",
    "Comadrona",
    "Empirical",
    "None"
  ),
  size = sum(es_establecimiento),
  replace = TRUE,
  prob = c(
    0.960,
    0.025,
    0.007,
    0.004,
    0.004
  )
)


# Domicilio:
# aumenta ligeramente la probabilidad de atención médica con los años.

filas_domicilio <- which(
  es_domicilio
)

for (fila in filas_domicilio) {

  progreso_fila <-
    base_sintetica$progreso[fila]

  p_medical <-
    0.05 +
    progreso_fila *
      (0.20 - 0.05)

  resto <- 1 - p_medical

  base_sintetica$birth_attendance[fila] <-
    sample(
      c(
        "Medical",
        "Comadrona",
        "Empirical",
        "None"
      ),
      size = 1L,
      prob = c(
        p_medical,
        resto * 0.86,
        resto * 0.07,
        resto * 0.07
      )
    )
}


# Otros lugares.

base_sintetica$birth_attendance[
  es_otro
] <- sample(
  c(
    "Medical",
    "Comadrona",
    "Empirical",
    "None"
  ),
  size = sum(es_otro),
  replace = TRUE,
  prob = c(
    0.55,
    0.20,
    0.10,
    0.15
  )
)


base_sintetica <- base_sintetica |>
  select(
    -p_health_facility,
    -p_home,
    -p_other
  )


# =============================================================================
# 17. CONSTRUIR EL RIESGO RELATIVO DE BAJO PESO AL NACER
# =============================================================================
#
# IMPORTANTE:
#   Este modelo se utiliza únicamente para generar una base donde el LBW presente:
#
#   - aumento temporal;
#   - mayor frecuencia en edades maternas extremas;
#   - diferencias territoriales;
#   - estacionalidad entre mayo y agosto;
#   - pequeñas diferencias por sexo y educación.
#
# El número de casos de LBW se fija por año según target_lbw_pct.
# Dentro de cada año, las probabilidades relativas determinan qué registros
# tienen mayor probabilidad de ser seleccionados como LBW.
# =============================================================================

efecto_edad <- c(
  "<15" = log(1.65),
  "15-19" = log(1.25),
  "20-24" = log(1.08),
  "25-29" = log(1.00),
  "30-34" = log(1.04),
  "35-39" = log(1.22),
  ">=40" = log(1.50)
)

efecto_mes <- c(
  "1"  = log(0.95),
  "2"  = log(0.99),
  "3"  = log(0.98),
  "4"  = log(0.98),
  "5"  = log(1.07),
  "6"  = log(1.11),
  "7"  = log(1.12),
  "8"  = log(1.10),
  "9"  = log(1.00),
  "10" = log(1.00),
  "11" = log(0.99),
  "12" = log(0.98)
)

efecto_educacion <- c(
  "None" = log(0.96),
  "Primary" = log(1.00),
  "Secondary" = log(1.04),
  "Higher education" = log(1.12)
)


base_sintetica <- base_sintetica |>
  mutate(

    risk_age =
      if_else(
        is.na(maternal_age_group),
        0,
        unname(
          efecto_edad[
            maternal_age_group
          ]
        )
      ),

    risk_month =
      unname(
        efecto_mes[
          as.character(
            birth_month
          )
        ]
      ),

    risk_education =
      if_else(
        is.na(maternal_education),
        0,
        unname(
          efecto_educacion[
            maternal_education
          ]
        )
      ),

    risk_sex =
      if_else(
        sex == "Female",
        log(1.12),
        0
      ),

    risk_indigenous =
      case_when(
        maternal_indigenous_status ==
          "Indigenous" ~
          log(1.03),

        TRUE ~ 0
      ),

    lbw_risk_score =
      department_risk_effect +
      municipality_risk_effect +
      risk_age +
      risk_month +
      risk_education +
      risk_sex +
      risk_indigenous

  )


# =============================================================================
# 18. ASIGNAR BAJO PESO AL NACER POR AÑO
# =============================================================================
#
# El número anual de casos se fija de forma determinista y luego se seleccionan
# los casos dentro del año mediante muestreo ponderado por lbw_risk_score.
#
# Esto hace que:
#   - la tendencia anual sea estable;
#   - las asociaciones descriptivas no sean idénticas en cada ejecución;
#   - con la semilla fija, el resultado final sea completamente reproducible.
# =============================================================================

base_sintetica$low_birth_weight_true <-
  0L


for (anio in ANIOS) {

  filas <- which(
    base_sintetica$birth_year ==
      anio
  )

  prevalencia_objetivo <-
    parametros_anuales |>
    filter(
      birth_year ==
        anio
    ) |>
    pull(
      target_lbw_pct
    ) / 100

  n_lbw <- round(
    length(filas) *
      prevalencia_objetivo
  )

  puntuacion <-
    base_sintetica$lbw_risk_score[
      filas
    ]

  pesos <-
    exp(
      puntuacion -
        max(puntuacion)
    )

  casos <- sample(
    filas,
    size = n_lbw,
    replace = FALSE,
    prob = pesos
  )

  base_sintetica$low_birth_weight_true[
    casos
  ] <- 1L
}


# =============================================================================
# 19. GENERAR PESO AL NACER
# =============================================================================
#
# El peso se genera condicionado por el estado sintético de LBW.
#
# Para imitar la estructura de una fuente originalmente registrada en
# libras/onzas, los pesos se aproximan a incrementos de una onza.
#
# Los valores extremos deliberados se introducirán DESPUÉS.
# =============================================================================

GRAMOS_ONZA <- 28.349523125

base_sintetica <- base_sintetica |>
  left_join(
    parametros_anuales |>
      select(
        birth_year,
        target_lbw_pct,
        target_mean_weight_g
      ),
    by = "birth_year"
  )


base_sintetica$birth_weight_g <-
  NA_real_


for (anio in ANIOS) {

  filas_anio <- which(
    base_sintetica$birth_year ==
      anio
  )

  p_lbw <-
    parametros_anuales |>
    filter(
      birth_year ==
        anio
    ) |>
    pull(
      target_lbw_pct
    ) / 100

  media_total <-
    parametros_anuales |>
    filter(
      birth_year ==
        anio
    ) |>
    pull(
      target_mean_weight_g
    )

  # Peso medio esperado entre los registros LBW.
  media_lbw <-
    2150 -
    2 * (anio - 2009)

  # Resolver la media necesaria del grupo no-LBW para aproximar
  # la media total del año.
  media_no_lbw <-
    (
      media_total -
        p_lbw * media_lbw
    ) /
    (1 - p_lbw)

  filas_lbw <- filas_anio[
    base_sintetica$low_birth_weight_true[
      filas_anio
    ] == 1L
  ]

  filas_no_lbw <- filas_anio[
    base_sintetica$low_birth_weight_true[
      filas_anio
    ] == 0L
  ]

  pesos_lbw <- rnorm_truncada(
    length(filas_lbw),
    media = media_lbw,
    de = 260,
    minimo = 500,
    maximo = 2494
  )

  pesos_no_lbw <- rnorm_truncada(
    length(filas_no_lbw),
    media = media_no_lbw,
    de = 410,
    minimo = 2524,
    maximo = 5000
  )

  # Aproximar a onzas enteras.
  pesos_lbw <-
    round(
      pesos_lbw /
        GRAMOS_ONZA
    ) *
    GRAMOS_ONZA

  pesos_no_lbw <-
    round(
      pesos_no_lbw /
        GRAMOS_ONZA
    ) *
    GRAMOS_ONZA

  # Asegurar que el redondeo no cruce el umbral de 2500 g.
  pesos_lbw <-
    pmin(
      pesos_lbw,
      88 * GRAMOS_ONZA
    )

  pesos_no_lbw <-
    pmax(
      pesos_no_lbw,
      89 * GRAMOS_ONZA
    )

  base_sintetica$birth_weight_g[
    filas_lbw
  ] <- pesos_lbw

  base_sintetica$birth_weight_g[
    filas_no_lbw
  ] <- pesos_no_lbw
}


# Redondear únicamente para presentación/almacenamiento.
base_sintetica$birth_weight_g <-
  round(
    base_sintetica$birth_weight_g,
    1
  )


# =============================================================================
# 20. VÍA DEL PARTO
# =============================================================================
#
# La probabilidad de cesárea aumenta con el tiempo y es mayor en los registros
# con LBW. Los partos domiciliarios tienen una probabilidad muy baja de cesárea.
# =============================================================================

base_sintetica <- base_sintetica |>
  mutate(

    p_cesarean_base =
      0.20 +
      progreso *
      (0.45 - 0.20),

    p_cesarean =
      case_when(

        birth_place_group == "Home" ~
          0.003,

        birth_place_group == "Other" ~
          pmin(
            0.15,
            p_cesarean_base * 0.40
          ),

        TRUE ~
          pmin(
            0.70,
            p_cesarean_base +
              0.09 *
              low_birth_weight_true
          )
      ),

    delivery_mode =
      if_else(
        runif(n()) <
          p_cesarean,
        "Cesarean",
        "Vaginal"
      )

  ) |>
  select(
    -p_cesarean_base,
    -p_cesarean
  )


# =============================================================================
# 21. INTRODUCIR PROBLEMAS DE CALIDAD DELIBERADOS
# =============================================================================
#
# Los problemas críticos se asignan SIN SOLAPAMIENTO.
#
# Esto permite controlar exactamente el máximo de registros potencialmente
# excluibles de un análisis que exija todas las variables críticas.
#
# Distribución:
#
#   0.6%  peso desconocido
#   0.4%  peso extremo (<500 g o >5000 g)
#   0.4%  fecha de nacimiento faltante
#   0.9%  residencia materna faltante
#   ------------------------------------------------
#   2.3%  con al menos un problema crítico
#
# =============================================================================

PCT_WEIGHT_MISSING <- 0.006
PCT_WEIGHT_EXTREME <- 0.004
PCT_DATE_MISSING <- 0.004
PCT_RESIDENCE_MISSING <- 0.009

n_weight_missing <-
  round(
    N_TOTAL *
      PCT_WEIGHT_MISSING
  )

n_weight_extreme <-
  round(
    N_TOTAL *
      PCT_WEIGHT_EXTREME
  )

n_date_missing <-
  round(
    N_TOTAL *
      PCT_DATE_MISSING
  )

n_residence_missing <-
  round(
    N_TOTAL *
      PCT_RESIDENCE_MISSING
  )

n_critical_total <-
  n_weight_missing +
  n_weight_extreme +
  n_date_missing +
  n_residence_missing


set.seed(
  SEMILLA + 200L
)

filas_criticas <- sample(
  seq_len(N_TOTAL),
  size = n_critical_total,
  replace = FALSE
)


cursor <- 0L

filas_weight_missing <-
  filas_criticas[
    seq_len(
      n_weight_missing
    )
  ]

cursor <- cursor +
  n_weight_missing

filas_weight_extreme <-
  filas_criticas[
    cursor +
      seq_len(
        n_weight_extreme
      )
  ]

cursor <- cursor +
  n_weight_extreme

filas_date_missing <-
  filas_criticas[
    cursor +
      seq_len(
        n_date_missing
      )
  ]

cursor <- cursor +
  n_date_missing

filas_residence_missing <-
  filas_criticas[
    cursor +
      seq_len(
        n_residence_missing
      )
  ]


# -----------------------------------------------------------------------------
# 21.1. Peso desconocido
# -----------------------------------------------------------------------------

base_sintetica$birth_weight_g[
  filas_weight_missing
] <- NA_real_


# -----------------------------------------------------------------------------
# 21.2. Pesos extremos deliberados
# -----------------------------------------------------------------------------

n_extremos_bajos <-
  floor(
    n_weight_extreme / 2
  )

filas_extremos_bajos <-
  filas_weight_extreme[
    seq_len(
      n_extremos_bajos
    )
  ]

filas_extremos_altos <-
  setdiff(
    filas_weight_extreme,
    filas_extremos_bajos
  )

base_sintetica$birth_weight_g[
  filas_extremos_bajos
] <- round(
  runif(
    length(filas_extremos_bajos),
    min = 280,
    max = 499
  ),
  1
)

base_sintetica$birth_weight_g[
  filas_extremos_altos
] <- round(
  runif(
    length(filas_extremos_altos),
    min = 5001,
    max = 5800
  ),
  1
)


# -----------------------------------------------------------------------------
# 21.3. Fecha faltante
# -----------------------------------------------------------------------------
#
# El año se conserva. Esto permite discutir que una fecha completa faltante no
# necesariamente impide un análisis anual nacional.

base_sintetica$birth_date[
  filas_date_missing
] <- as.Date(NA)

base_sintetica$birth_month[
  filas_date_missing
] <- NA_integer_


# -----------------------------------------------------------------------------
# 21.4. Residencia materna faltante
# -----------------------------------------------------------------------------
#
# Si se desconoce el municipio, también se elimina el departamento. Esto evita
# crear información territorial contradictoria.

base_sintetica$maternal_department_code[
  filas_residence_missing
] <- NA_character_

base_sintetica$maternal_department_name[
  filas_residence_missing
] <- NA_character_

base_sintetica$maternal_municipality_code[
  filas_residence_missing
] <- NA_character_

base_sintetica$maternal_municipality_name[
  filas_residence_missing
] <- NA_character_


# =============================================================================
# 22. DERIVAR VARIABLES DE CALIDAD Y BAJO PESO OBSERVADO
# =============================================================================

base_sintetica <- base_sintetica |>
  mutate(

    weight_review_status =
      case_when(

        is.na(birth_weight_g) ~
          "Unknown",

        birth_weight_g < 500 ~
          "Below 500 g",

        birth_weight_g > 5000 ~
          "Above 5000 g",

        TRUE ~
          "Within screening range"
      ),

    low_birth_weight =
      case_when(

        is.na(birth_weight_g) ~
          NA_integer_,

        birth_weight_g < 2500 ~
          1L,

        TRUE ~
          0L
      ),

    quality_issue =
      case_when(

        simulation_row %in%
          filas_weight_missing ~
          "Missing birth weight",

        simulation_row %in%
          filas_weight_extreme ~
          "Extreme birth weight",

        simulation_row %in%
          filas_date_missing ~
          "Missing birth date",

        simulation_row %in%
          filas_residence_missing ~
          "Missing maternal residence",

        TRUE ~
          "None"
      ),

    # Para tendencias nacionales de LBW:
    # no se exige geografía, solo un peso plausible.
    eligible_national_lbw =
      !is.na(birth_weight_g) &
      birth_weight_g >= 500 &
      birth_weight_g <= 5000,

    # Para un análisis espacial/ambiental:
    # además se exige fecha completa y municipio conocido.
    eligible_spatial_lbw =
      eligible_national_lbw &
      !is.na(birth_date) &
      !is.na(maternal_municipality_code)

  )


# =============================================================================
# 23. LIMPIEZA DE COLUMNAS AUXILIARES
# =============================================================================

base_sintetica <- base_sintetica |>
  select(
    -department_risk_effect,
    -municipality_risk_effect,
    -risk_age,
    -risk_month,
    -risk_education,
    -risk_sex,
    -risk_indigenous,
    -lbw_risk_score,
    -low_birth_weight_true,
    -target_lbw_pct,
    -target_mean_weight_g,
    -progreso
  )


# =============================================================================
# 24. ORDENAR REGISTROS Y CREAR IDENTIFICADOR
# =============================================================================
#
# Se mezcla el orden final para evitar que el archivo quede organizado por año.
# El identificador no tiene relación con ninguna persona real.

set.seed(
  SEMILLA + 300L
)

base_sintetica <- base_sintetica |>
  slice_sample(
    prop = 1
  ) |>
  mutate(

    record_id =
      sprintf(
        "GTBPN%06d",
        row_number()
      )

  ) |>
  select(

    record_id,

    birth_date,
    birth_year,
    birth_month,

    sex,

    birth_weight_g,
    low_birth_weight,
    weight_review_status,

    maternal_age,
    maternal_age_group,
    maternal_education,
    maternal_indigenous_status,
    maternal_marital_status,

    birth_attendance,
    birth_place_group,
    delivery_mode,

    maternal_department_code,
    maternal_department_name,
    maternal_municipality_code,
    maternal_municipality_name,

    quality_issue,
    eligible_national_lbw,
    eligible_spatial_lbw
  )


# =============================================================================
# 25. VALIDACIONES AUTOMÁTICAS
# =============================================================================

# -----------------------------------------------------------------------------
# 25.1. Tamaño y periodo
# -----------------------------------------------------------------------------

stopifnot(
  nrow(base_sintetica) == N_TOTAL,
  all(
    base_sintetica$birth_year %in%
      ANIOS
  ),
  n_distinct(
    base_sintetica$birth_year
  ) == 16L
)


# -----------------------------------------------------------------------------
# 25.2. Códigos territoriales
# -----------------------------------------------------------------------------

stopifnot(

  n_distinct(
    base_sintetica$maternal_department_code,
    na.rm = TRUE
  ) == 22L,

  n_distinct(
    base_sintetica$maternal_municipality_code,
    na.rm = TRUE
  ) == 340L,

  all(
    is.na(
      base_sintetica$maternal_municipality_code
    ) |
      grepl(
        "^[0-9]{4}$",
        base_sintetica$maternal_municipality_code
      )
  )
)


# -----------------------------------------------------------------------------
# 25.3. Coherencia departamento-municipio
# -----------------------------------------------------------------------------

filas_geografia_completa <- which(
  !is.na(
    base_sintetica$maternal_municipality_code
  )
)

stopifnot(
  all(
    substr(
      base_sintetica$maternal_municipality_code[
        filas_geografia_completa
      ],
      1,
      2
    ) ==
      base_sintetica$maternal_department_code[
        filas_geografia_completa
      ]
  )
)


# -----------------------------------------------------------------------------
# 25.4. Porcentaje máximo con problemas críticos
# -----------------------------------------------------------------------------

pct_critical_issue <-
  100 *
  mean(
    base_sintetica$quality_issue !=
      "None"
  )

stopifnot(
  pct_critical_issue <= 3
)


# -----------------------------------------------------------------------------
# 25.5. Ninguna variable con missing permitido supera 5%
# -----------------------------------------------------------------------------

variables_missing_controlado <- c(
  "maternal_age",
  "maternal_age_group",
  "maternal_education",
  "maternal_indigenous_status",
  "maternal_marital_status"
)

missing_summary <- tibble(

  variable =
    variables_missing_controlado,

  missing_pct =
    vapply(
      base_sintetica[
        variables_missing_controlado
      ],
      function(x) {
        100 * mean(is.na(x))
      },
      numeric(1)
    )
)

stopifnot(
  all(
    missing_summary$missing_pct <= 5
  )
)


# -----------------------------------------------------------------------------
# 25.6. Control específico de pesos
# -----------------------------------------------------------------------------

stopifnot(

  sum(
    is.na(
      base_sintetica$birth_weight_g
    )
  ) ==
    n_weight_missing,

  sum(
    base_sintetica$birth_weight_g < 500,
    na.rm = TRUE
  ) ==
    length(
      filas_extremos_bajos
    ),

  sum(
    base_sintetica$birth_weight_g > 5000,
    na.rm = TRUE
  ) ==
    length(
      filas_extremos_altos
    )
)


# -----------------------------------------------------------------------------
# 25.7. Elegibilidad según objetivo
# -----------------------------------------------------------------------------

pct_excluded_national <-
  100 *
  mean(
    !base_sintetica$eligible_national_lbw
  )

pct_excluded_spatial <-
  100 *
  mean(
    !base_sintetica$eligible_spatial_lbw
  )

stopifnot(
  pct_excluded_national <= 3,
  pct_excluded_spatial <= 3
)


# =============================================================================
# 26. RESÚMENES DE CONTROL
# =============================================================================

control_anual <- base_sintetica |>
  filter(
    eligible_national_lbw
  ) |>
  group_by(
    birth_year
  ) |>
  summarise(

    births =
      n(),

    lbw_pct =
      100 *
      mean(
        low_birth_weight == 1
      ),

    mean_birth_weight_g =
      mean(
        birth_weight_g
      ),

    .groups = "drop"
  )


control_mensual <- base_sintetica |>
  filter(
    eligible_national_lbw,
    !is.na(birth_month)
  ) |>
  group_by(
    birth_month
  ) |>
  summarise(

    births =
      n(),

    lbw_pct =
      100 *
      mean(
        low_birth_weight == 1
      ),

    .groups = "drop"
  )


control_calidad <- base_sintetica |>
  count(
    quality_issue,
    name = "records"
  ) |>
  mutate(
    percent =
      100 *
      records /
      sum(records)
  )


cat(
  "\n============================================================\n",
  "BASE GENERADA Y VALIDADA\n",
  "============================================================\n",
  "Registros: ",
  format(
    nrow(base_sintetica),
    big.mark = "."
  ),
  "\nProblema crítico: ",
  round(
    pct_critical_issue,
    2
  ),
  "%\nExcluidos del análisis nacional de LBW: ",
  round(
    pct_excluded_national,
    2
  ),
  "%\nExcluidos del análisis espacial de LBW: ",
  round(
    pct_excluded_spatial,
    2
  ),
  "%\n============================================================\n"
)


cat(
  "\nMissing permitido por variable:\n"
)

print(
  missing_summary
)


cat(
  "\nProblemas de calidad deliberados:\n"
)

print(
  control_calidad
)


cat(
  "\nTendencia anual de LBW:\n"
)

print(
  control_anual,
  n = Inf
)


cat(
  "\nPatrón mensual de LBW:\n"
)

print(
  control_mensual,
  n = Inf
)


# =============================================================================
# 27. EXPORTAR LA BASE FINAL
# =============================================================================
#
# Se guarda un único archivo de datos derivado del proceso:
#
#   01_datos/nacimientos_guatemala.rds
#
# RDS conserva clases y tipos de variables de R y evita mantener dos copias
# equivalentes de la misma base en formatos distintos.
# =============================================================================

saveRDS(
  base_sintetica,
  RUTA_RDS,
  compress = "xz"
)


# =============================================================================
# 28. CONTROL DE REPRODUCIBILIDAD FINAL
# =============================================================================

cat(
  "\n============================================================\n",
  "EJECUCIÓN COMPLETADA\n",
  "============================================================\n",
  "Semilla: ",
  SEMILLA,
  "\n",
  "Base final: ",
  RUTA_RDS,
  "\n",
  "Catálogo territorial público: ",
  RUTA_CATALOGO,
  "\n",
  "No se guardaron bases intermedias ni entorno de trabajo.\n",
  "============================================================\n"
)

}) # Fin del entorno local: los objetos auxiliares se descartan.

# Fin del script.
