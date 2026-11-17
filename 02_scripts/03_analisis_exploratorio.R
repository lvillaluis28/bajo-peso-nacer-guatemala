# =============================================================================
# 03_analisis_exploratorio.R
# =============================================================================
#
# OBJETIVO:
#   Describir la base analítica y generar las principales visualizaciones
#   exploratorias del bajo peso al nacer en Guatemala, 2009-2024.
#
# ENTRADA:
#   01_datos/nacimientos_analisis.rds
#
# SALIDAS:
#   03_resultados/02_grafico-distribucion-peso.png
#   03_resultados/03_grafico-tendencia-lbw.png
#   03_resultados/04_grafico-estacionalidad-lbw.png
#   03_resultados/05_grafico-lbw-departamento.png
#   03_resultados/06_grafico-lbw-edad-materna.png
#   03_resultados/07_grafico-datos-ausentes.png
# =============================================================================

library(dplyr)
library(ggplot2)

dir.create("03_resultados", showWarnings = FALSE, recursive = TRUE)

base <- readRDS("01_datos/nacimientos_analisis.rds")

# -----------------------------------------------------------------------------
# 1. Funciones y estilo común
# -----------------------------------------------------------------------------

resumir_lbw <- function(datos, variable) {

  datos |>
    group_by({{ variable }}) |>
    summarise(
      n = n(),
      casos = sum(low_birth_weight == 1),
      prevalencia = casos / n,
      .groups = "drop"
    ) |>
    mutate(
      z = 1.96,
      centro = (
        prevalencia + z^2 / (2 * n)
      ) / (
        1 + z^2 / n
      ),
      margen = (
        z /
          (1 + z^2 / n)
      ) *
        sqrt(
          prevalencia * (1 - prevalencia) / n +
            z^2 / (4 * n^2)
        ),
      li95 = pmax(0, centro - margen),
      ls95 = pmin(1, centro + margen),
      across(
        c(prevalencia, li95, ls95),
        ~ .x * 100
      )
    ) |>
    select(
      -z,
      -centro,
      -margen
    )
}

tema_grafico <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(colour = "grey30"),
    panel.grid.minor = element_blank(),
    plot.background = element_rect(
      fill = "white",
      colour = NA
    ),
    panel.background = element_rect(
      fill = "white",
      colour = NA
    )
  )

guardar_grafico <- function(nombre, grafico, ancho = 8, alto = 5) {

  ggsave(
    filename = file.path("03_resultados", nombre),
    plot = grafico,
    width = ancho,
    height = alto,
    dpi = 300,
    bg = "white"
  )
}

# -----------------------------------------------------------------------------
# 2. Resumen general
# -----------------------------------------------------------------------------

cat("\n===========================================================\n")
cat("RESUMEN GENERAL\n")
cat("===========================================================\n")
cat("Registros:", format(nrow(base), big.mark = "."), "\n")
cat(
  "Prevalencia de BPN:",
  round(100 * mean(base$low_birth_weight), 2),
  "%\n"
)
cat(
  "Peso medio:",
  round(mean(base$birth_weight_g), 1),
  "g\n"
)
cat(
  "Peso mediano:",
  round(median(base$birth_weight_g), 1),
  "g\n"
)
cat("===========================================================\n")

# -----------------------------------------------------------------------------
# 3. Distribución del peso al nacer
# -----------------------------------------------------------------------------

grafico_peso <- ggplot(
  base,
  aes(x = birth_weight_g)
) +
  geom_histogram(
    binwidth = 100,
    boundary = 0,
    fill = "grey65",
    colour = "white",
    linewidth = 0.2
  ) +
  geom_vline(
    xintercept = 2500,
    linetype = "dashed",
    linewidth = 0.7
  ) +
  labs(
    x = "Peso al nacer (g)",
    y = "Número de nacimientos",
    title = "Distribución del peso al nacer",
    subtitle = "La línea discontinua indica el umbral de 2500 g"
  ) +
  tema_grafico

guardar_grafico(
  "02_grafico-distribucion-peso.png",
  grafico_peso
)

# -----------------------------------------------------------------------------
# 4. Tendencia anual del bajo peso al nacer
# -----------------------------------------------------------------------------

resumen_anual <- resumir_lbw(
  base,
  birth_year
)

grafico_anual <- ggplot(
  resumen_anual,
  aes(x = birth_year, y = prevalencia)
) +
  geom_errorbar(
    aes(ymin = li95, ymax = ls95),
    width = 0.12,
    linewidth = 0.45
  ) +
  geom_line(linewidth = 0.75) +
  geom_point(size = 2.1) +
  scale_x_continuous(
    breaks = seq(2009, 2024, by = 2)
  ) +
  labs(
    x = "Año",
    y = "Bajo peso al nacer (%)",
    title = "Prevalencia anual de bajo peso al nacer, 2009–2024",
    subtitle = "Prevalencia anual e intervalo de confianza del 95%"
  ) +
  tema_grafico

guardar_grafico(
  "03_grafico-tendencia-lbw.png",
  grafico_anual
)

# -----------------------------------------------------------------------------
# 5. Estacionalidad
# -----------------------------------------------------------------------------

resumen_mensual <- resumir_lbw(
  base,
  birth_month
)

meses <- c(
  "Ene", "Feb", "Mar", "Abr", "May", "Jun",
  "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"
)

grafico_mensual <- ggplot(
  resumen_mensual,
  aes(x = birth_month, y = prevalencia)
) +
  geom_errorbar(
    aes(ymin = li95, ymax = ls95),
    width = 0.10,
    linewidth = 0.45
  ) +
  geom_line(linewidth = 0.75) +
  geom_point(size = 2.1) +
  scale_x_continuous(
    breaks = 1:12,
    labels = meses
  ) +
  labs(
    x = "Mes de nacimiento",
    y = "Bajo peso al nacer (%)",
    title = "Patrón estacional del bajo peso al nacer",
    subtitle = "Prevalencia mensual e intervalo de confianza del 95%"
  ) +
  tema_grafico

guardar_grafico(
  "04_grafico-estacionalidad-lbw.png",
  grafico_mensual
)

# -----------------------------------------------------------------------------
# 6. Diferencias entre departamentos
# -----------------------------------------------------------------------------

resumen_departamental <- resumir_lbw(
  base,
  maternal_department_name
) |>
  arrange(prevalencia) |>
  mutate(
    maternal_department_name = factor(
      maternal_department_name,
      levels = maternal_department_name
    )
  )

grafico_departamento <- ggplot(
  resumen_departamental,
  aes(
    y = maternal_department_name,
    x = prevalencia
  )
) +
  geom_segment(
    aes(
      x = li95,
      xend = ls95,
      yend = maternal_department_name
    ),
    linewidth = 0.55
  ) +
  geom_point(size = 2.3) +
  labs(
    x = "Bajo peso al nacer (%)",
    y = NULL,
    title = "Variación del bajo peso al nacer entre departamentos",
    subtitle = "Prevalencia e intervalo de confianza del 95%"
  ) +
  tema_grafico

guardar_grafico(
  "05_grafico-lbw-departamento.png",
  grafico_departamento,
  ancho = 8,
  alto = 7
)

# -----------------------------------------------------------------------------
# 7. Bajo peso al nacer según edad materna
# -----------------------------------------------------------------------------

orden_edad <- c(
  "<15", "15-19", "20-24", "25-29",
  "30-34", "35-39", ">=40"
)

resumen_edad <- base |>
  filter(!is.na(maternal_age_group)) |>
  mutate(
    maternal_age_group = factor(
      maternal_age_group,
      levels = orden_edad
    )
  ) |>
  resumir_lbw(
    maternal_age_group
  )

grafico_edad <- ggplot(
  resumen_edad,
  aes(
    x = maternal_age_group,
    y = prevalencia
  )
) +
  geom_errorbar(
    aes(ymin = li95, ymax = ls95),
    width = 0.12,
    linewidth = 0.5
  ) +
  geom_point(size = 2.5) +
  labs(
    x = "Edad materna (años)",
    y = "Bajo peso al nacer (%)",
    title = "Bajo peso al nacer según edad materna",
    subtitle = "Prevalencia e intervalo de confianza del 95%"
  ) +
  tema_grafico

guardar_grafico(
  "06_grafico-lbw-edad-materna.png",
  grafico_edad
)

# -----------------------------------------------------------------------------
# 8. Datos ausentes en variables maternas
# -----------------------------------------------------------------------------

variables_na <- c(
  "Edad materna" = "maternal_age",
  "Educación materna" = "maternal_education",
  "Pertenencia indígena" = "maternal_indigenous_status",
  "Estado marital" = "maternal_marital_status"
)

resumen_na <- data.frame(
  variable = names(variables_na),
  porcentaje = vapply(
    variables_na,
    function(x) {
      100 * mean(is.na(base[[x]]))
    },
    numeric(1)
  )
) |>
  arrange(porcentaje) |>
  mutate(
    variable = factor(
      variable,
      levels = variable
    )
  )

grafico_na <- ggplot(
  resumen_na,
  aes(
    x = porcentaje,
    y = variable
  )
) +
  geom_segment(
    aes(
      x = 0,
      xend = porcentaje,
      yend = variable
    ),
    linewidth = 0.6,
    colour = "grey65"
  ) +
  geom_point(size = 2.7) +
  labs(
    x = "Datos ausentes (%)",
    y = NULL,
    title = "Datos ausentes en variables maternas"
  ) +
  tema_grafico

guardar_grafico(
  "07_grafico-datos-ausentes.png",
  grafico_na,
  ancho = 7,
  alto = 4
)

cat("\nAnálisis exploratorio completado.\n")
