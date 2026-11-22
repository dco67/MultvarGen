# ===========================================================================
# _common.R — réglages et objets partagés par les chapitres du manuel.
# Chaque chapitre le charge au début : source("_common.R").
# Les données sont simulées EXACTEMENT comme dans MultvarGen : _moteur.R est une
# copie de global.R. Avec la même graine et les mêmes réglages, les nombres
# cités dans le texte sont ceux que l'application affiche.
# ===========================================================================
suppressPackageStartupMessages({
  library(shiny); library(bslib); library(DT); library(ggplot2)
  source("_moteur.R")
})

knitr::opts_chunk$set(
  echo = FALSE, message = FALSE, warning = FALSE,
  fig.align = "center", out.width = "88%", fig.width = 6.4, fig.height = 3.8,
  dev = "ragg_png", dpi = if (knitr::is_latex_output()) 300 else 150
)

# --- Nombres à la française (texte et figures) -------------------------------
fr <- function(x, d = 2) {
  x <- as.numeric(x); x[!is.na(x) & abs(x) < 0.5 * 10^(-d)] <- 0
  sub("^-", "−", formatC(x, format = "f", digits = d, decimal.mark = ",", big.mark = " "))
}
pc  <- function(x, d = 1) paste0(fr(100 * x, d), "\u00a0%")
# Nombre à insérer dans une formule LaTeX ($...$) : virgule protégée
frm <- function(x, d = 3) gsub(",", "{,}", sub("−", "-", fr(x, d), fixed = TRUE), fixed = TRUE)
ent <- function(x) formatC(x, format = "d", big.mark = " ")
axe_fr <- function(x) sub("^-", "−", format(x, decimal.mark = ",", big.mark = " ",
                                            trim = TRUE, scientific = FALSE, drop0trailing = TRUE))

# Tableau knitr à la française (virgule décimale)
tab_fr <- function(df, d = 3, ...) {
  num <- vapply(df, is.double, logical(1))
  df[num] <- lapply(df[num], fr, d = d)
  knitr::kable(df, align = ifelse(num | vapply(df, is.numeric, logical(1)), "r", "l"), ...)
}

# --- Couleurs et thème -------------------------------------------------------
pal <- list(bleu = "#2c7fb8", orange = "#d95f0e", vert = "#1b9e77", rouge = "#c0392b",
            gris = "grey45", violet = "#7570b3", rose = "#d63384")
theme_set(theme_minimal(base_size = 12) +
            theme(panel.grid.minor = element_blank(), legend.position = "bottom",
                  strip.text = element_text(face = "bold"),
                  plot.title = element_text(face = "bold", size = 12)))

# --- Générer comme le bouton « Générer les données » ---------------------------
# Les réglages par défaut reproduisent ceux d'une carte de configuration
# « neutre »; seuls les arguments donnés changent. La graine est appliquée
# exactement comme dans l'application (set.seed juste avant la génération).
reglages_base <- list(
  nfact = 3, vpf = 5L, fc = 0.30, pl = "H", cl = "None",
  low_vpf = 5, up_vpf = 15, distribution = "normal", skew_strength = 0.5,
  cross_loading_prop = 0, group_sizes = 500L, group_mean_diff = "none",
  group_cov_diff = "equal", response_format = "continuous",
  likert_profile = "balanced", likert_pattern_mode = "common", likert_categories = 5L,
  measurement_invariance = "invariant", response_style = "none", response_style_prop = 0,
  missingness_mechanism = "none", missingness_rate = 0.10, structure = "correlated",
  gl = "M", reverse_prop = 0
)

generer <- function(graine = 2024, ...) {
  p <- modifyList(reglages_base, list(...))
  p$N <- sum(p$group_sizes)
  set.seed(graine)
  do.call(generate_factor_data, p)
}

# Écarts entre corrélations observées et populationnelles
ecarts <- function(d, source = c("base", "final")) {
  source <- match.arg(source)
  S <- pooled_population_correlation(d)
  R <- if (source == "base") cor(d$response_continuous_base) else
    cor(d$response, use = "pairwise.complete.obs")
  k <- lower.tri(S)
  data.frame(rho = S[k], r = R[k], ecart = R[k] - S[k])
}

# Heatmap d'une matrice (corrélations ou charges)
heat <- function(M, titre = NULL, lim = c(-1, 1), texte = FALSE, d = 2) {
  df <- expand.grid(ligne = factor(rownames(M), levels = rev(rownames(M))),
                    colonne = factor(colnames(M), levels = colnames(M)))
  df$v <- as.vector(M)
  g <- ggplot(df, aes(colonne, ligne, fill = v)) + geom_tile(colour = "white") +
    scale_fill_gradient2(low = pal$orange, mid = "white", high = pal$bleu,
                         limits = lim, labels = axe_fr, name = NULL) +
    labs(x = NULL, y = NULL, title = titre) + coord_fixed() +
    theme(panel.grid = element_blank(), legend.position = "right",
          axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))
  if (texte) g <- g + geom_text(aes(label = fr(v, d)), size = 2.6)
  g
}

# --- La population fil rouge -------------------------------------------------
# 3 facteurs corrélés à 0,30, 5 items par facteur, charges principales
# élevées (0,65-0,80), aucune charge secondaire, N = 500, graine 2024.
fil <- generer(2024)
fil_S <- pooled_population_correlation(fil)
fil_R <- cor(fil$response)
fil_e <- ecarts(fil)
