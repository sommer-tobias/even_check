#' Count heating replacements by old and new system
#'
#' Classifies the existing and new heating of each replaced heating system with
#' [heizsystem_codes] and counts the flows used by [plot_heizungsersatz()]:
#' total -> existing system -> new system -> heat pump type.
#'
#' Only rows with `en_103_heizung_ersetzt == TRUE` are counted. Each row is one
#' building, so a heating that serves several buildings is counted once per
#' building. Second heating systems (`*_2` columns) are ignored. Codes that are
#' missing or not in `codes` are counted as "Unbekannt".
#'
#' @param data A data frame shaped like [en103_export].
#' @param codes Lookup table shaped like [heizsystem_codes].
#' @param gebaeudekategorien Main building categories to keep
#'   (`gebaeude_hauptsaechliche_gebaeudekategorie`). Defaults to residential
#'   buildings; `NULL` keeps all.
#' @param von,bis Optional start and end date (`Date` or `"YYYY-MM-DD"`),
#'   both inclusive, applied to `datum_spalte`.
#' @param datum_spalte Name of the date-time column used for `von` and `bis`.
#' @param status_ausschliessen Project statuses (`projekt_status`) to drop.
#'
#' @return A data frame with one row per flow and columns `stufe` (1 = total
#'   to existing, 2 = existing to new, 3 = heat pump to heat pump type),
#'   `von`, `nach` and `n`. The number of replacements is stored in
#'   `attr(x, "n_total")`.
#' @export
#'
#' @examples
#' toy <- data.frame(
#'   en_103_heizung_ersetzt = TRUE,
#'   en_103_bestehende_heizung = c("1034-04", "1034-04", "1039-01"),
#'   en_103_neue_heizung = c("1031-03", "1032-01", "1031-01"),
#'   gebaeude_hauptsaechliche_gebaeudekategorie = "II Wohnen EFH",
#'   projekt_status = "Freigegeben",
#'   teilnachweis_zuerst_eingereicht_am = as.POSIXct("2026-03-01")
#' )
#' heizungsersatz_flows(toy)
heizungsersatz_flows <- function(data,
                                 codes = evencheck::heizsystem_codes,
                                 gebaeudekategorien = c("I Wohnen MFH", "II Wohnen EFH"),
                                 von = NULL,
                                 bis = NULL,
                                 datum_spalte = "teilnachweis_zuerst_eingereicht_am",
                                 status_ausschliessen = "Storniert") {
  keep <- data$en_103_heizung_ersetzt %in% TRUE &
    !data$projekt_status %in% status_ausschliessen
  if (!is.null(gebaeudekategorien)) {
    keep <- keep & data$gebaeude_hauptsaechliche_gebaeudekategorie %in% gebaeudekategorien
  }
  if (!is.null(von) || !is.null(bis)) {
    datum <- as.Date(data[[datum_spalte]], tz = "Europe/Zurich")
    if (!is.null(von)) keep <- keep & !is.na(datum) & datum >= as.Date(von)
    if (!is.null(bis)) keep <- keep & !is.na(datum) & datum <= as.Date(bis)
  }
  d <- data[keep, , drop = FALSE]

  kategorie <- function(code) {
    x <- codes$kategorie[match(code, codes$code)]
    x[is.na(x)] <- "Unbekannt"
    x
  }
  alt <- kategorie(d$en_103_bestehende_heizung)
  neu <- kategorie(d$en_103_neue_heizung)
  wp_typ <- codes$wp_typ[match(d$en_103_neue_heizung, codes$code)]
  wp_typ[neu == "W\u00E4rmepumpe" & is.na(wp_typ)] <- "Unbekannt"

  zaehle <- function(stufe, von, nach) {
    if (length(von) == 0) {
      return(data.frame(stufe = integer(), von = character(), nach = character(), n = integer()))
    }
    t <- as.data.frame(table(von = von, nach = nach), stringsAsFactors = FALSE)
    t <- t[t$Freq > 0, , drop = FALSE]
    data.frame(stufe = rep(stufe, nrow(t)), von = t$von, nach = t$nach, n = t$Freq)
  }
  ist_wp <- neu == "W\u00E4rmepumpe"
  flows <- rbind(
    zaehle(1L, rep("Anzahl Heizungsersatz", nrow(d)), alt),
    zaehle(2L, alt, neu),
    zaehle(3L, neu[ist_wp], wp_typ[ist_wp])
  )
  rownames(flows) <- NULL
  attr(flows, "n_total") <- nrow(d)
  flows
}

#' Sankey diagram of heating replacements
#'
#' Draws the flows from [heizungsersatz_flows()] as a Sankey diagram: all
#' replacements, the existing system, the new system and, for heat pumps,
#' the heat pump type. Shares on the right are relative to all replacements.
#'
#' @inheritParams heizungsersatz_flows
#' @param titel Plot title. By default built from the building categories
#'   and the period.
#' @param quelle Caption shown bottom right.
#'
#' @return A ggplot object. Save it with e.g.
#'   `ggplot2::ggsave("sankey.png", p, width = 13.3, height = 7.5, dpi = 150)`.
#' @export
#'
#' @examples
#' \dontrun{
#' plot_heizungsersatz(en103_export, von = "2026-01-01", bis = "2026-06-30")
#' }
plot_heizungsersatz <- function(data,
                                codes = evencheck::heizsystem_codes,
                                gebaeudekategorien = c("I Wohnen MFH", "II Wohnen EFH"),
                                von = NULL,
                                bis = NULL,
                                datum_spalte = "teilnachweis_zuerst_eingereicht_am",
                                status_ausschliessen = "Storniert",
                                titel = NULL,
                                quelle = "Quelle: EVEN, Darstellung: evencheck") {
  flows <- heizungsersatz_flows(
    data, codes, gebaeudekategorien, von, bis, datum_spalte, status_ausschliessen
  )
  n_total <- attr(flows, "n_total")
  if (n_total == 0) {
    stop("No heating replacements match the filters.", call. = FALSE)
  }
  if (is.null(titel)) {
    titel <- sankey_titel(data, gebaeudekategorien, von, bis, datum_spalte)
  }

  layout <- sankey_layout(flows, n_total)
  nodes <- layout$nodes
  ribbons <- layout$ribbons

  # Shares for the end points: new systems other than heat pumps, and the
  # heat pump types.
  ende <- nodes[(nodes$spalte == 3 & nodes$name != "W\u00E4rmepumpe") | nodes$spalte == 4, ]
  ende$anteil <- format_anteil(ende$n / n_total)
  ende$text_farbe <- sankey_textfarbe(ende$name)
  # Columns 3 and 4 share the share column, so space those labels jointly.
  ende <- ende[order(ende$label_y), ]
  ende$anteil_y <- spreize(ende$label_y, layout$min_abstand)

  bar_breite <- 0.06
  ggplot2::ggplot() +
    ggplot2::geom_polygon(
      data = ribbons,
      ggplot2::aes(x = .data$x, y = .data$y, group = .data$id, fill = .data$farbe),
      alpha = 0.6, colour = NA
    ) +
    ggplot2::geom_rect(
      data = nodes,
      ggplot2::aes(
        xmin = .data$x - bar_breite / 2, xmax = .data$x + bar_breite / 2,
        ymin = .data$y0, ymax = .data$y1, fill = .data$farbe
      ),
      colour = NA
    ) +
    ggplot2::geom_label(
      data = nodes,
      ggplot2::aes(x = .data$x + bar_breite, y = .data$label_y, label = .data$label),
      hjust = 0, vjust = 0.5, size = 3.6, fontface = "bold", lineheight = 0.95,
      fill = grDevices::adjustcolor("white", alpha.f = 0.75),
      label.size = 0, label.padding = grid::unit(0.2, "lines"), colour = "black"
    ) +
    ggplot2::geom_text(
      data = ende,
      ggplot2::aes(x = 4.85, y = .data$anteil_y, label = .data$anteil),
      hjust = 0, size = 5, fontface = "bold", colour = ende$text_farbe
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::scale_y_reverse() +
    ggplot2::scale_x_continuous(limits = c(0.9, 5.3)) +
    ggplot2::labs(title = titel, caption = quelle) +
    ggplot2::theme_void(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        colour = "#C00000", face = "bold", size = 26, margin = ggplot2::margin(b = 12)
      ),
      plot.caption = ggplot2::element_text(face = "italic", size = 10, hjust = 1),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA),
      plot.margin = ggplot2::margin(20, 20, 15, 20)
    )
}

# Node and flow colours, following the EnDK slide style.
sankey_farben <- c(
  "Anzahl Heizungsersatz" = "#404040",
  "\u00D6lheizung" = "#8C8C8C",
  "Gasheizung" = "#A6A6A6",
  "Elektroheizung" = "#FFF200",
  "Holzfeuerung" = "#8B4A0F",
  "W\u00E4rmepumpe" = "#5AAAF5",
  "Fernw\u00E4rme" = "#5C3A1A",
  "Abw\u00E4rme" = "#B5651D",
  "Solarthermie" = "#F2A900",
  "W\u00E4rmekraftkopplung" = "#7B6FA0",
  "Andere" = "#C8C8C8",
  "Kein W\u00E4rmeerzeuger" = "#DADADA",
  "Unbekannt" = "#DADADA",
  "Luft-Wasser" = "#5AA0EE",
  "Sole-Wasser" = "#0B4EA2",
  "Wasser-Wasser" = "#1F8FA6"
)

# Order of nodes within a column, top to bottom.
sankey_reihenfolge <- c(
  "Anzahl Heizungsersatz", "\u00D6lheizung", "Gasheizung", "Elektroheizung",
  "W\u00E4rmepumpe", "Luft-Wasser", "Sole-Wasser", "Wasser-Wasser", "Holzfeuerung",
  "Fernw\u00E4rme", "Abw\u00E4rme", "Solarthermie", "W\u00E4rmekraftkopplung", "Andere",
  "Kein W\u00E4rmeerzeuger", "Unbekannt"
)

sankey_farbe <- function(name) {
  x <- unname(sankey_farben[name])
  x[is.na(x)] <- "#DADADA"
  x
}

# Share text needs to stay readable on white, so light fills get a darker ink.
sankey_textfarbe <- function(name) {
  x <- sankey_farbe(name)
  x[name %in% c("\u00D6lheizung", "Gasheizung")] <- "#595959"
  x[name == "Elektroheizung"] <- "#A69B00"
  x[name %in% c("Andere", "Kein W\u00E4rmeerzeuger", "Unbekannt")] <- "#7F7F7F"
  x
}

# Move sorted label positions apart until neighbours are at least `abstand`
# apart, pushing each overlapping pair in both directions.
spreize <- function(y, abstand, runden = 100) {
  for (r in seq_len(runden)) {
    ueberlapp <- abstand - diff(y)
    if (all(ueberlapp <= 1e-9)) break
    for (k in which(ueberlapp > 1e-9)) {
      y[k] <- y[k] - ueberlapp[k] / 2
      y[k + 1] <- y[k + 1] + ueberlapp[k] / 2
    }
  }
  y
}

format_anteil <- function(p) {
  ifelse(p < 0.1, sprintf("%.1f %%", 100 * p), sprintf("%.0f %%", 100 * p))
}

sankey_titel <- function(data, gebaeudekategorien, von, bis, datum_spalte) {
  wohnen <- c("I Wohnen MFH", "II Wohnen EFH")
  gebaeude <- if (is.null(gebaeudekategorien)) {
    "Alle Geb\u00E4ude"
  } else if (setequal(gebaeudekategorien, wohnen)) {
    "Wohnbauten"
  } else {
    paste(gebaeudekategorien, collapse = ", ")
  }
  datum <- as.Date(data[[datum_spalte]], tz = "Europe/Zurich")
  start <- if (is.null(von)) min(datum, na.rm = TRUE) else as.Date(von)
  ende <- if (is.null(bis)) max(datum, na.rm = TRUE) else as.Date(bis)
  periode <- paste(format(start, "%d.%m.%Y"), format(ende, "%d.%m.%Y"), sep = "\u2013")
  paste("Heizungsersatz", gebaeude, periode, sep = " | ")
}

# Compute node rectangles and flow ribbons. y grows downwards (the plot uses
# scale_y_reverse()); one unit of y is one replacement.
sankey_layout <- function(flows, n_total) {
  luecke <- 0.06 * n_total
  spalte_x <- c(1, 2, 3, 4)

  # Node size = sum of incoming flows.
  ziele <- function(stufe) {
    f <- flows[flows$stufe == stufe, ]
    if (nrow(f) == 0) return(NULL)
    n <- tapply(f$n, f$nach, sum)
    data.frame(spalte = stufe + 1L, name = names(n), n = as.vector(n))
  }
  node_n <- rbind(
    data.frame(spalte = 1L, name = "Anzahl Heizungsersatz", n = n_total),
    ziele(1L), ziele(2L), ziele(3L)
  )
  node_n <- node_n[order(node_n$spalte, match(node_n$name, sankey_reihenfolge)), ]

  # Stack nodes per column and centre each column on the tallest one.
  hoehe <- tapply(node_n$n, node_n$spalte, sum) + luecke * (tapply(node_n$n, node_n$spalte, length) - 1)
  node_n$y0 <- NA_real_
  for (s in unique(node_n$spalte)) {
    i <- which(node_n$spalte == s)
    start <- (max(hoehe[as.character(1:3)]) - hoehe[as.character(s)]) / 2
    if (s == 4) {
      # Centre the heat pump types on the heat pump node.
      wp <- node_n[node_n$spalte == 3 & node_n$name == "W\u00E4rmepumpe", ]
      start <- wp$y0 + wp$n / 2 - hoehe[as.character(s)] / 2
    }
    node_n$y0[i] <- start + c(0, cumsum(node_n$n[i] + luecke))[seq_along(i)]
  }
  node_n$y1 <- node_n$y0 + node_n$n
  node_n$x <- spalte_x[node_n$spalte]
  node_n$farbe <- sankey_farbe(node_n$name)
  anzeige <- ifelse(node_n$spalte == 4, paste("WP", node_n$name), node_n$name)
  node_n$label <- paste0(anzeige, "\n", format(node_n$n, big.mark = "'", trim = TRUE))

  # Keep labels of small neighbouring nodes from overlapping.
  min_abstand <- 0.085 * max(hoehe)
  node_n$label_y <- (node_n$y0 + node_n$y1) / 2
  for (s in unique(node_n$spalte)) {
    i <- which(node_n$spalte == s)
    for (k in seq_along(i)[-1]) {
      node_n$label_y[i[k]] <- max(node_n$label_y[i[k]], node_n$label_y[i[k - 1]] + min_abstand)
    }
  }

  # Flow ribbons: outgoing flows are stacked in target order, incoming flows
  # in source order.
  bar <- 0.03
  ribbons <- list()
  for (st in sort(unique(flows$stufe))) {
    f <- flows[flows$stufe == st, ]
    quelle <- node_n[node_n$spalte == st, ]
    ziel <- node_n[node_n$spalte == st + 1, ]
    f$q_rang <- match(f$von, sankey_reihenfolge)
    f$z_rang <- match(f$nach, sankey_reihenfolge)

    f <- f[order(f$q_rang, f$z_rang), ]
    f$q_y0 <- quelle$y0[match(f$von, quelle$name)] +
      stats::ave(f$n, f$von, FUN = function(v) cumsum(v) - v)

    f <- f[order(f$z_rang, f$q_rang), ]
    f$z_y0 <- ziel$y0[match(f$nach, ziel$name)] +
      stats::ave(f$n, f$nach, FUN = function(v) cumsum(v) - v)

    farbe <- if (st == 1) {
      rep("#D9D9D9", nrow(f))
    } else if (st == 2) {
      sankey_farbe(f$von)
    } else {
      sankey_farbe(f$nach)
    }
    for (j in seq_len(nrow(f))) {
      ribbons[[length(ribbons) + 1]] <- sankey_ribbon(
        x0 = spalte_x[st] + bar, x1 = spalte_x[st + 1] - bar,
        y0 = f$q_y0[j], y1 = f$z_y0[j], n = f$n[j],
        id = paste(st, f$von[j], f$nach[j]), farbe = farbe[j]
      )
    }
  }
  ribbons <- do.call(rbind, ribbons)

  list(nodes = node_n, ribbons = ribbons, min_abstand = min_abstand)
}

# One flow as a polygon with smooth (cosine) top and bottom edges.
sankey_ribbon <- function(x0, x1, y0, y1, n, id, farbe, schritte = 60) {
  t <- seq(0, 1, length.out = schritte)
  s <- (1 - cos(pi * t)) / 2
  x <- x0 + (x1 - x0) * t
  oben <- y0 + (y1 - y0) * s
  data.frame(
    x = c(x, rev(x)),
    y = c(oben, rev(oben + n)),
    id = id,
    farbe = farbe
  )
}
