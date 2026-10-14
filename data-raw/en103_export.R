## Read the EN-103 (heating and hot water) export and save it as package data.
##
## Source: data-raw/excel-export-2026-09-30_anon.xlsx (anonymised export,
## one row per building and EN-103 sub-proof).
##
## Requires readxl and usethis (not package dependencies).

path <- "data-raw/excel-export-2026-09-30_anon.xlsx"

raw <- readxl::read_excel(path, sheet = 1, guess_max = 10000)

## Header cells look like "Projekt\n———\nProjekt-ID": a group and a field name.
## Turn them into snake_case names such as "projekt_projekt_id" or
## "gebaeude_gebaeude_nr_egid".
clean_names <- function(x) {
  x <- sub("\n[^\n]*\n", "_", x)
  x <- gsub("ä", "ae", x)
  x <- gsub("ö", "oe", x)
  x <- gsub("ü", "ue", x)
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  gsub("^_|_$", "", x)
}
names(raw) <- clean_names(names(raw))
stopifnot(!anyDuplicated(names(raw)))

en103_export <- raw

## Timestamps are stored as text ("2026-01-12 15:42:53").
datetime_cols <- c(
  "projekt_letzte_statusaenderung",
  "projekt_initiale_einreichung",
  "projekt_letzte_einreichung",
  "projekt_abgeschlossen_am",
  "teilnachweis_letzte_statusaenderung",
  "teilnachweis_zuerst_eingereicht_am",
  "teilnachweis_zuletzt_eingereicht_am",
  "teilnachweis_abgeschlossen_am"
)
en103_export[datetime_cols] <- lapply(
  en103_export[datetime_cols],
  function(x) as.POSIXct(as.character(x), format = "%Y-%m-%d %H:%M:%S", tz = "Europe/Zurich")
)

## Identifiers stay character so they are never treated as numbers.
id_cols <- c(
  "projekt_eproid",
  "projekt_baugesuchsnummer_dossier_id",
  "gebaeude_gebaeude_nr_egid",
  "gebaeude_parzellennummern"
)
en103_export[id_cols] <- lapply(en103_export[id_cols], as.character)

## Whole-number measures.
int_cols <- c(
  "en_103_installierte_waermeleistung",
  "en_103_ebf_neu",
  "en_103_ebf",
  "en_103_en120_standardloesung",
  "teilnachweis_version"
)
en103_export[int_cols] <- lapply(en103_export[int_cols], as.integer)

## Yes/no flags.
lgl_cols <- c(
  "en_103_heizung_ersetzt",
  "en_103_neue_heizung_fuer_mehrere_gebaeude",
  "en_103_neue_heizung_2_fuer_mehrere_gebaeude",
  "teilnachweis_private_kontrolle",
  "teilnachweis_wird_nachgereicht",
  "gebaeude_vorhaben_mit_minergie_zertifizierung"
)
en103_export[lgl_cols] <- lapply(en103_export[lgl_cols], as.logical)

stopifnot(
  all(c(datetime_cols, id_cols, int_cols, lgl_cols) %in% names(en103_export)),
  nrow(en103_export) == 676
)

usethis::use_data(en103_export, overwrite = TRUE)
