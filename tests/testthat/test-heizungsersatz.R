toy <- data.frame(
  en_103_heizung_ersetzt = c(TRUE, TRUE, TRUE, TRUE, FALSE, TRUE, TRUE),
  en_103_bestehende_heizung = c("1034-04", "1034-04", "1039-01", NA, "1034-04", "1034-02", "1034-02"),
  en_103_neue_heizung = c("1031-03", "1032-01", "1031-01", "1035-01", "1031-01", "1032-05", "1031-01"),
  gebaeude_hauptsaechliche_gebaeudekategorie = c(rep("II Wohnen EFH", 5), "I Wohnen MFH", "IX Industrie"),
  projekt_status = c(rep("Freigegeben", 5), "Storniert", "Freigegeben"),
  teilnachweis_zuerst_eingereicht_am = as.POSIXct(
    c("2026-01-10", "2026-02-10", "2026-03-10", "2026-04-10", "2026-05-10", "2026-06-10", "2026-07-10"),
    tz = "Europe/Zurich"
  )
)

test_that("heizungsersatz_flows counts flows through all stages", {
  f <- heizungsersatz_flows(toy)
  expect_equal(attr(f, "n_total"), 4)
  expect_equal(sum(f$n[f$stufe == 1]), 4)
  expect_equal(sum(f$n[f$stufe == 2]), 4)
  expect_equal(f$n[f$stufe == 2 & f$von == "\u00D6lheizung" & f$nach == "W\u00E4rmepumpe"], 2)
  expect_equal(f$n[f$stufe == 2 & f$von == "Unbekannt" & f$nach == "Holzfeuerung"], 1)
  wp <- f[f$stufe == 3, ]
  expect_equal(setNames(wp$n, wp$nach), c("Luft-Wasser" = 2, "Sole-Wasser" = 1))
})

test_that("heizungsersatz_flows applies filters", {
  expect_equal(attr(heizungsersatz_flows(toy, gebaeudekategorien = NULL), "n_total"), 5)
  expect_equal(
    attr(heizungsersatz_flows(toy, gebaeudekategorien = NULL, status_ausschliessen = NULL), "n_total"),
    6
  )
  expect_equal(attr(heizungsersatz_flows(toy, von = "2026-02-01", bis = "2026-03-31"), "n_total"), 2)
})

test_that("plot_heizungsersatz builds a plot whose flows fit the nodes", {
  p <- plot_heizungsersatz(toy)
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))

  layout <- sankey_layout(heizungsersatz_flows(toy), 4)
  nodes <- layout$nodes
  expect_equal(nodes$n[nodes$spalte == 1], 4)
  expect_equal(sum(nodes$n[nodes$spalte == 2]), 4)
  expect_equal(sum(nodes$n[nodes$spalte == 4]), nodes$n[nodes$name == "W\u00E4rmepumpe" & nodes$spalte == 3])
})

test_that("plot_heizungsersatz fails clearly when nothing matches", {
  expect_error(plot_heizungsersatz(toy, von = "2030-01-01"), "No heating replacements")
})

test_that("spreize keeps labels apart", {
  y <- spreize(c(0, 1, 2, 10), abstand = 3)
  expect_true(all(diff(y) >= 3 - 1e-6))
})
