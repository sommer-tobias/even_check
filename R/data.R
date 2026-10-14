#' EN-103 heating and hot water export
#'
#' Anonymised export of EN-103 energy proofs (heating and hot water systems,
#' including EN-120), with one row per building and sub-proof.
#'
#' Column names combine the export's header group (`projekt`, `teilnachweis`,
#' `en_103`, `gebaeude`) with the field name. The original German header is
#' given in parentheses.
#'
#' @format A data frame with 676 rows and 46 variables:
#' \describe{
#'   \item{`projekt_projekt_id`}{character. Project ID. (Projekt / Projekt-ID)}
#'   \item{`teilnachweis_en_nr`}{character. Sub-proof form number (EN-103). (Teilnachweis / EN-Nr.)}
#'   \item{`teilnachweis_formatteddisplayname`}{character. Display name of the sub-proof. (Teilnachweis / formattedDisplayName)}
#'   \item{`projekt_status`}{character. Project status. (Projekt / Status)}
#'   \item{`projekt_letzte_statusaenderung`}{POSIXct. Last project status change. (Projekt / Letzte Statusänderung)}
#'   \item{`projekt_eproid`}{character. eBAU project ID (EPROID). (Projekt / EPROID)}
#'   \item{`projekt_vollzugsgemeinde`}{character. Responsible municipality. (Projekt / Vollzugsgemeinde)}
#'   \item{`projekt_baugesuchsnummer_dossier_id`}{character. Building application number or dossier ID. (Projekt / Baugesuchsnummer / Dossier-ID)}
#'   \item{`projekt_initiale_einreichung`}{POSIXct. First submission of the project. (Projekt / Initiale Einreichung)}
#'   \item{`projekt_letzte_einreichung`}{POSIXct. Latest submission of the project. (Projekt / Letzte Einreichung)}
#'   \item{`projekt_abgeschlossen_am`}{POSIXct. Project completion date. (Projekt / Abgeschlossen am)}
#'   \item{`en_103_neue_heizung`}{character. Code of the new heating system. (EN-103 / NEUE_HEIZUNG)}
#'   \item{`en_103_heizung_ersetzt`}{logical. Whether an existing heating system is replaced. (EN-103 / HEIZUNG_ERSETZT)}
#'   \item{`en_103_bestehende_heizung`}{character. Code of the existing heating system. (EN-103 / BESTEHENDE_HEIZUNG)}
#'   \item{`en_103_bestehender_wassererwaermer`}{character. Code of the existing water heater. (EN-103 / BESTEHENDER_WASSERERWAERMER)}
#'   \item{`en_103_neuer_wassererwaermer`}{character. Code of the new water heater. (EN-103 / NEUER_WASSERERWAERMER)}
#'   \item{`en_103_installierte_waermeleistung`}{integer. Installed heating output. (EN-103 / INSTALLIERTE_WAERMELEISTUNG)}
#'   \item{`en_103_ebf_neu`}{integer. New energy reference area (EBF). (EN-103 / EBF_NEU)}
#'   \item{`en_103_ebf`}{integer. Energy reference area (EBF). (EN-103 / EBF)}
#'   \item{`en_103_bestehende_heizung_2`}{character. Code of a second existing heating system. (EN-103 / BESTEHENDE_HEIZUNG_2)}
#'   \item{`en_103_en120_standardloesung`}{integer. EN-120 standard solution. (EN-103 / EN120_STANDARDLOESUNG)}
#'   \item{`en_103_bestehender_wassererwaermer_2`}{character. Code of a second existing water heater. (EN-103 / BESTEHENDER_WASSERERWAERMER_2)}
#'   \item{`en_103_neue_heizung_2`}{character. Code of a second new heating system. (EN-103 / NEUE_HEIZUNG_2)}
#'   \item{`en_103_neuer_wassererwaermer_2`}{character. Code of a second new water heater. (EN-103 / NEUER_WASSERERWAERMER_2)}
#'   \item{`en_103_neue_heizung_fuer_mehrere_gebaeude`}{logical. Whether the new heating system serves several buildings. (EN-103 / NEUE_HEIZUNG_FUER_MEHRERE_GEBAEUDE)}
#'   \item{`en_103_neue_heizung_2_fuer_mehrere_gebaeude`}{logical. Whether the second new heating system serves several buildings. (EN-103 / NEUE_HEIZUNG_2_FUER_MEHRERE_GEBAEUDE)}
#'   \item{`teilnachweis_name`}{character. Name of the sub-proof. (Teilnachweis / Name)}
#'   \item{`teilnachweis_status`}{character. Sub-proof status. (Teilnachweis / Status)}
#'   \item{`teilnachweis_letzte_statusaenderung`}{POSIXct. Last sub-proof status change. (Teilnachweis / Letzte Statusänderung)}
#'   \item{`teilnachweis_typ`}{character. Sub-proof type (e.g. Nachweis, Meldeformular). (Teilnachweis / Typ)}
#'   \item{`teilnachweis_version`}{integer. Form version. (Teilnachweis / Version)}
#'   \item{`teilnachweis_gebaeudekategorien`}{character. Building categories covered. (Teilnachweis / Gebäudekategorien)}
#'   \item{`teilnachweis_private_kontrolle`}{logical. Whether a private inspection applies. (Teilnachweis / Private Kontrolle)}
#'   \item{`teilnachweis_wird_nachgereicht`}{logical. Whether the sub-proof will be submitted later. (Teilnachweis / wird nachgereicht)}
#'   \item{`teilnachweis_zuerst_eingereicht_am`}{POSIXct. First submission of the sub-proof. (Teilnachweis / Zuerst eingereicht am)}
#'   \item{`teilnachweis_zuletzt_eingereicht_am`}{POSIXct. Latest submission of the sub-proof. (Teilnachweis / Zuletzt eingereicht am)}
#'   \item{`teilnachweis_abgeschlossen_am`}{POSIXct. Sub-proof completion date. (Teilnachweis / Abgeschlossen am)}
#'   \item{`gebaeude_bezeichnung`}{character. Building name. (Gebäude / Bezeichnung)}
#'   \item{`gebaeude_gebaeude_nr_egid`}{character. Federal building identifier (EGID). (Gebäude / Gebäude-Nr. (EGID))}
#'   \item{`gebaeude_parzellennummern`}{character. Plot number(s). (Gebäude / Parzellennummern)}
#'   \item{`gebaeude_typ`}{character. Building type (e.g. Neubau, Bestehendes Gebäude). (Gebäude / Typ)}
#'   \item{`gebaeude_adresse`}{character. Building address. (Gebäude / Adresse)}
#'   \item{`gebaeude_vorhaben_mit_minergie_zertifizierung`}{logical. Whether the project seeks Minergie certification. (Gebäude / Vorhaben mit Minergie-Zertifizierung)}
#'   \item{`gebaeude_art_der_arbeiten`}{character. Type of works. (Gebäude / Art der Arbeiten)}
#'   \item{`gebaeude_hauptsaechliche_gebaeudekategorie`}{character. Main building category (SIA 380/1). (Gebäude / Hauptsächliche Gebäudekategorie)}
#'   \item{`gebaeude_zusaetzliche_gebaeudekategorie`}{character. Additional building category. (Gebäude / Zusätzliche Gebäudekategorie)}
#' }
#' @source Excel export of 30 September 2026
#'   (`excel-export-2026-09-30_anon.xlsx`), imported by
#'   `data-raw/en103_export.R`.
"en103_export"
