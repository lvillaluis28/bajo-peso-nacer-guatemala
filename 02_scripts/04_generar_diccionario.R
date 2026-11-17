# =============================================================================
# 04_generar_diccionario.R
# =============================================================================
#
# OBJETIVO:
#   Crear un diccionario de variables legible en Excel.
#
# SALIDA:
#   04_documentacion/diccionario_variables.xlsx
# =============================================================================

library(tibble)
library(openxlsx)

dir.create(
  "04_documentacion",
  showWarnings = FALSE,
  recursive = TRUE
)

diccionario_variables <- tribble(
  ~variable, ~descripcion, ~tipo_variable, ~unidad_medida, ~valores_esperados, ~permite_na,
  
  "record_id",
  "Identificador ficticio único del registro.",
  "Identificador",
  "No aplica",
  "GTBPN000001-GTBPN100000; único por registro",
  "No",
  
  "birth_date",
  "Fecha de nacimiento.",
  "Fecha",
  "AAAA-MM-DD",
  "Fechas entre 2009-01-01 y 2024-12-31",
  "No",
  
  "birth_year",
  "Año de nacimiento.",
  "Cuantitativa discreta",
  "Año",
  "2009-2024",
  "No",
  
  "birth_month",
  "Mes de nacimiento.",
  "Cuantitativa discreta",
  "Mes",
  "1-12",
  "No",
  
  "sex",
  "Sexo registrado del recién nacido.",
  "Categórica nominal binaria",
  "No aplica",
  "Male; Female",
  "No",
  
  "birth_weight_g",
  "Peso al nacer.",
  "Cuantitativa continua",
  "g",
  "500-5000 en la base analítica",
  "No",
  
  "low_birth_weight",
  "Indicador de bajo peso al nacer.",
  "Categórica nominal binaria",
  "No aplica",
  "0 = >=2500 g; 1 = <2500 g",
  "No",
  
  "weight_review_status",
  "Clasificación del peso al nacer según los criterios de revisión.",
  "Categórica nominal",
  "No aplica",
  "Within screening range",
  "No",
  
  "maternal_age",
  "Edad materna al momento del nacimiento.",
  "Cuantitativa discreta",
  "Años",
  "12-49",
  "Sí",
  
  "maternal_age_group",
  "Grupo de edad materna.",
  "Categórica ordinal",
  "No aplica",
  "<15; 15-19; 20-24; 25-29; 30-34; 35-39; >=40",
  "Sí",
  
  "maternal_education",
  "Nivel educacional materno agrupado.",
  "Categórica ordinal",
  "No aplica",
  "None; Primary; Secondary; Higher education",
  "Sí",
  
  "maternal_indigenous_status",
  "Pertenencia indígena materna agrupada.",
  "Categórica nominal binaria",
  "No aplica",
  "Indigenous; Non-Indigenous",
  "Sí",
  
  "maternal_marital_status",
  "Estado marital materno.",
  "Categórica nominal",
  "No aplica",
  "Single; Married; Consensual union",
  "Sí",
  
  "birth_attendance",
  "Categoría de la persona que atendió el parto.",
  "Categórica nominal",
  "No aplica",
  "Medical; Paramedical; Comadrona; Empirical; None",
  "No",
  
  "birth_place_group",
  "Lugar del parto agrupado.",
  "Categórica nominal",
  "No aplica",
  "Health facility; Home; Other",
  "No",
  
  "delivery_mode",
  "Vía del parto.",
  "Categórica nominal binaria",
  "No aplica",
  "Vaginal; Cesarean",
  "No",
  
  "maternal_department_code",
  "Código del departamento de residencia materna.",
  "Categórica nominal",
  "No aplica",
  "01-22",
  "No",
  
  "maternal_department_name",
  "Nombre del departamento de residencia materna.",
  "Categórica nominal",
  "No aplica",
  "22 departamentos de Guatemala",
  "No",
  
  "maternal_municipality_code",
  "Código del municipio de residencia materna.",
  "Categórica nominal",
  "No aplica",
  "Código municipal de cuatro dígitos; 340 municipios",
  "No",
  
  "maternal_municipality_name",
  "Nombre del municipio de residencia materna.",
  "Categórica nominal",
  "No aplica",
  "340 municipios de Guatemala",
  "No",
  
  "quality_issue",
  "Problema crítico de calidad identificado durante la generación de la base.",
  "Categórica nominal",
  "No aplica",
  "None (sin problema crítico de calidad)",
  "No",
  
  "eligible_national_lbw",
  "Indica si el registro cumple los criterios para análisis nacional de bajo peso al nacer.",
  "Categórica nominal binaria",
  "No aplica",
  "TRUE; FALSE",
  "No",
  
  "eligible_spatial_lbw",
  "Indica si el registro cumple los criterios para análisis territorial de bajo peso al nacer.",
  "Categórica nominal binaria",
  "No aplica",
  "TRUE; FALSE",
  "No"
)

wb <- createWorkbook()

addWorksheet(
  wb,
  "Diccionario",
  gridLines = FALSE
)

writeData(
  wb,
  "Diccionario",
  x = "Diccionario de variables",
  startRow = 1,
  startCol = 1
)

mergeCells(
  wb,
  "Diccionario",
  cols = 1:6,
  rows = 1
)

writeData(
  wb,
  "Diccionario",
  diccionario_variables,
  startRow = 3,
  startCol = 1,
  colNames = TRUE
)

estilo_titulo <- createStyle(
  fontSize = 16,
  textDecoration = "bold",
  halign = "left",
  valign = "center"
)

estilo_encabezado <- createStyle(
  textDecoration = "bold",
  fgFill = "#D9EAF7",
  border = "Bottom",
  borderColour = "#7F8C8D",
  halign = "left",
  valign = "center",
  wrapText = TRUE
)

estilo_cuerpo <- createStyle(
  valign = "top",
  wrapText = TRUE
)

addStyle(
  wb,
  "Diccionario",
  estilo_titulo,
  rows = 1,
  cols = 1:6,
  gridExpand = TRUE
)

addStyle(
  wb,
  "Diccionario",
  estilo_encabezado,
  rows = 3,
  cols = 1:6,
  gridExpand = TRUE
)

addStyle(
  wb,
  "Diccionario",
  estilo_cuerpo,
  rows = 4:(nrow(diccionario_variables) + 3),
  cols = 1:6,
  gridExpand = TRUE
)

setColWidths(
  wb,
  "Diccionario",
  cols = 1:6,
  widths = c(28, 48, 28, 18, 48, 14)
)

setRowHeights(
  wb,
  "Diccionario",
  rows = 1,
  heights = 26
)

setRowHeights(
  wb,
  "Diccionario",
  rows = 3,
  heights = 30
)

freezePane(
  wb,
  "Diccionario",
  firstActiveRow = 4
)

addFilter(
  wb,
  "Diccionario",
  rows = 3,
  cols = 1:6
)

saveWorkbook(
  wb,
  "04_documentacion/diccionario_variables.xlsx",
  overwrite = TRUE
)

cat(
  "\nDiccionario generado en:\n",
  "04_documentacion/diccionario_variables.xlsx\n"
)
