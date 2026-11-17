# =============================================================================
# 02_preparar_base_analitica.R
# =============================================================================
#
# OBJETIVO:
#   Aplicar criterios de elegibilidad de forma secuencial, crear la base
#   analítica y generar un flujo de exclusiones.
#
# ENTRADA:
#   01_datos/nacimientos_guatemala.rds
#
# SALIDAS:
#   01_datos/nacimientos_analisis.rds
#   03_resultados/01_flujo_exclusiones.png
# =============================================================================

library(dplyr)
library(ggplot2)
library(tibble)

dir.create("03_resultados", showWarnings = FALSE, recursive = TRUE)

base <- readRDS("01_datos/nacimientos_guatemala.rds")

# -----------------------------------------------------------------------------
# 1. Asignar una causa única y secuencial de exclusión
# -----------------------------------------------------------------------------

base <- base |>
  mutate(
    exclusion_reason = case_when(
      is.na(birth_weight_g) ~ "Peso desconocido",
      birth_weight_g < 500 | birth_weight_g > 5000 ~
        "Peso extremo (<500 o >5000 g)",
      is.na(birth_date) ~ "Fecha de nacimiento desconocida",
      is.na(maternal_municipality_code) ~
        "Residencia materna desconocida",
      TRUE ~ "Incluido"
    )
  )

# -----------------------------------------------------------------------------
# 2. Contar exclusiones
# -----------------------------------------------------------------------------

n_inicial <- nrow(base)

n_peso_desconocido <- sum(
  base$exclusion_reason == "Peso desconocido"
)

n_peso_extremo <- sum(
  base$exclusion_reason == "Peso extremo (<500 o >5000 g)"
)

n_fecha_desconocida <- sum(
  base$exclusion_reason == "Fecha de nacimiento desconocida"
)

n_residencia_desconocida <- sum(
  base$exclusion_reason == "Residencia materna desconocida"
)

n_final <- sum(
  base$exclusion_reason == "Incluido"
)

# -----------------------------------------------------------------------------
# 3. Crear base analítica
# -----------------------------------------------------------------------------

base_analitica <- base |>
  filter(exclusion_reason == "Incluido") |>
  select(-exclusion_reason)

stopifnot(
  nrow(base_analitica) == n_final,
  !anyNA(base_analitica$birth_weight_g),
  all(dplyr::between(base_analitica$birth_weight_g, 500, 5000)),
  !anyNA(base_analitica$birth_date),
  !anyNA(base_analitica$maternal_municipality_code)
)

saveRDS(
  base_analitica,
  "01_datos/nacimientos_analisis.rds"
)

# -----------------------------------------------------------------------------
# 4. Crear gráfico de flujo de exclusiones
# -----------------------------------------------------------------------------

flujo <- tibble(
  x = c(1, 1, 1, 1, 1, 1),
  y = c(6, 5, 4, 3, 2, 1),
  etiqueta = c(
    paste0(
      "Base inicial\nn = ",
      format(n_inicial, big.mark = ".")
    ),
    paste0(
      "Excluidos por peso desconocido\nn = ",
      format(n_peso_desconocido, big.mark = ".")
    ),
    paste0(
      "Excluidos por peso extremo\n(<500 o >5000 g)\nn = ",
      format(n_peso_extremo, big.mark = ".")
    ),
    paste0(
      "Excluidos por fecha desconocida\nn = ",
      format(n_fecha_desconocida, big.mark = ".")
    ),
    paste0(
      "Excluidos por residencia materna desconocida\nn = ",
      format(n_residencia_desconocida, big.mark = ".")
    ),
    paste0(
      "Base analítica final\nn = ",
      format(n_final, big.mark = ".")
    )
  ),
  tipo = c(
    "inicio",
    "exclusion",
    "exclusion",
    "exclusion",
    "exclusion",
    "final"
  )
)

grafico_flujo <- ggplot(flujo, aes(x = x, y = y)) +
  annotate(
    "segment",
    x = 1, xend = 1,
    y = 5.6, yend = 1.4,
    linewidth = 0.6
  ) +
  geom_label(
    aes(label = etiqueta, fill = tipo),
    size = 4.2,
    label.size = 0.3,
    label.padding = unit(0.35, "lines"),
    show.legend = FALSE
  ) +
  scale_fill_manual(
    values = c(
      "inicio" = "grey90",
      "exclusion" = "grey95",
      "final" = "grey85"
    )
  ) +
  xlim(0.7, 1.3) +
  ylim(0.5, 6.5) +
  labs(
    title = "Flujo de exclusiones de la base analítica"
  ) +
  theme_void() +
  theme(
    plot.title = element_text(
      hjust = 0.5,
      face = "bold"
    )
  )

ggsave(
  filename = "03_resultados/01_grafico-exclusiones.png",
  plot = grafico_flujo,
  width = 7,
  height = 9,
  dpi = 300,
  bg = "white"
)

# -----------------------------------------------------------------------------
# 5. Mostrar resumen en consola
# -----------------------------------------------------------------------------

cat("\n===========================================================\n")
cat("FLUJO DE EXCLUSIONES\n")
cat("===========================================================\n")
cat("Base inicial:                         ", format(n_inicial, big.mark = "."), "\n")
cat("Excluidos por peso desconocido:      ", format(n_peso_desconocido, big.mark = "."), "\n")
cat("Excluidos por peso extremo:          ", format(n_peso_extremo, big.mark = "."), "\n")
cat("Excluidos por fecha desconocida:     ", format(n_fecha_desconocida, big.mark = "."), "\n")
cat("Excluidos por residencia desconocida:", format(n_residencia_desconocida, big.mark = "."), "\n")
cat("Base analítica final:                ", format(n_final, big.mark = "."), "\n")
cat("===========================================================\n")
