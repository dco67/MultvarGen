library(shiny)
library(bslib)
library(DT)
library(ggplot2)

# ============================================================
# Palette et petits utilitaires d'affichage
# ============================================================

# Palette centralisée pour les cartes de préréglages
pal_multivgen <- c(
  personality = "#17a2b8",
  cognitive   = "#28a745",
  social      = "#fd7e14",
  academic    = "#6f42c1",
  bifactor    = "#d63384",
  survey      = "#0d6efd",
  hover       = "#e2f0fd",
  card_bg     = "#f8f9fa",
  border      = "#e0e0e0"
)

# Nombre en notation française : virgule décimale, signe moins typographique
fmt_n <- function(x, digits = 2) {
  out <- formatC(round(x, digits), format = "f", digits = digits, big.mark = " ")
  out <- gsub(".", ",", out, fixed = TRUE)
  out <- sub("^-", "−", out)
  out[is.na(x)] <- "—"
  out
}

fmt_pct <- function(x, digits = 1) {
  paste0(fmt_n(100 * x, digits), " %")
}

# Les tableaux DT ne doivent pas s'étirer dans les cartes (hauteur naturelle)
DTOutput <- function(outputId, fill = FALSE, ...) {
  res <- DT::DTOutput(outputId, fill = fill, ...)
  htmltools::bindFillRole(res, item = FALSE, container = FALSE)
}

# Tableau DT avec virgule décimale pour toutes les colonnes réelles
dt_fr <- function(df, digits = 3, options = list(), ...) {
  numeric_cols <- names(df)[vapply(df, is.double, logical(1))]

  # Arrondi d'affichage (évite aussi l'affichage « -0,000 »)
  for (col in numeric_cols) {
    df[[col]] <- round(df[[col]], if (startsWith(col, "%")) 1 else digits) + 0
  }

  base_options <- list(
    language = list(
      info = "Lignes _START_ à _END_ sur _TOTAL_",
      infoEmpty = "Aucune ligne",
      zeroRecords = "Aucune ligne",
      search = "Rechercher :",
      lengthMenu = "Afficher _MENU_ lignes",
      paginate = list(previous = "Précédent", `next` = "Suivant")
    ),
    dom = "t",
    paging = FALSE,
    ordering = FALSE,
    scrollX = TRUE,
    autoWidth = FALSE
  )
  base_options[names(options)] <- options

  dt <- datatable(
    df,
    rownames = FALSE,
    options = base_options,
    ...
  )

  pct_cols <- numeric_cols[startsWith(numeric_cols, "%")]
  other_cols <- setdiff(numeric_cols, pct_cols)

  if (length(other_cols) > 0) {
    dt <- formatRound(dt, columns = other_cols, digits = digits, dec.mark = ",", mark = " ")
  }
  if (length(pct_cols) > 0) {
    dt <- formatRound(dt, columns = pct_cols, digits = 1, dec.mark = ",", mark = " ")
  }

  dt
}

# Carte cliquable de préréglage (le bouton caché déclenche l'observateur)
preset_card <- function(id, title, subtitle, icon_name, colour) {
  div(
    class = "preset-card",
    style = sprintf(
      "border: 1px solid %s; border-radius: 8px; padding: 12px; cursor: pointer; background-color: %s; transition: all 0.2s;",
      pal_multivgen[["border"]], pal_multivgen[["card_bg"]]
    ),
    onclick = sprintf(
      "$(this).css('background-color', '%s').delay(200).queue(function(next){ $(this).css('background-color', '%s'); next(); }); $('#%s').click();",
      pal_multivgen[["hover"]], pal_multivgen[["card_bg"]], id
    ),
    div(
      style = "display: flex; align-items: center;",
      div(
        style = sprintf(
          "background-color: %s; color: white; width: 40px; height: 40px; border-radius: 50%%; display: flex; align-items: center; justify-content: center; margin-right: 10px; flex-shrink: 0;",
          colour
        ),
        icon(icon_name)
      ),
      div(
        style = "flex-grow: 1;",
        div(style = "font-weight: bold; color: #333;", title),
        div(style = "font-size: 0.8rem; color: #666;", subtitle)
      )
    ),
    actionButton(id, "", style = "display: none;")
  )
}

# ============================================================
# Codage Likert
# ============================================================

# Seuils fixes appliqués aux réponses continues sous-jacentes. Un item garde
# ses seuils dans tous les groupes : une différence de moyenne latente peut
# donc se traduire par une différence de réponses Likert observées.
# Pour 5 catégories, les probabilités cumulées historiques sont conservées;
# pour les autres nombres de catégories, une règle générale est appliquée.
likert_thresholds <- function(profile = "balanced", k = 5) {
  k <- as.integer(k)
  j <- seq_len(k - 1) / k

  probabilities <- if (k == 5) {
    switch(
      profile,
      "balanced" = c(0.20, 0.40, 0.60, 0.80),
      "centered" = pnorm(c(-1.5, -0.5, 0.5, 1.5)),
      "low" = c(0.50, 0.72, 0.87, 0.95),
      "high" = c(0.05, 0.13, 0.28, 0.50),
      c(0.20, 0.40, 0.60, 0.80)
    )
  } else {
    switch(
      profile,
      "balanced" = j,
      "centered" = if (k == 2) 0.5 else pnorm(seq(-1.5, 1.5, length.out = k - 1)),
      "low" = 1 - (1 - j)^2.2,
      "high" = j^2.2,
      j
    )
  }

  list(
    probabilities = probabilities,
    values = qnorm(probabilities)
  )
}

likert_profile_labels <- c(
  balanced = "Équilibré",
  centered = "Centré symétrique",
  low = "Surtout bas",
  high = "Surtout haut"
)

discretize_likert <- function(
  data,
  profile = "balanced",
  pattern_mode = "common",
  group_membership = NULL,
  measurement_invariance = "invariant",
  n_categories = 5,
  item_profiles = NULL,
  dif_item = NULL
) {
  n_categories <- as.integer(n_categories)

  item_profiles <- if (!is.null(item_profiles)) {
    unname(item_profiles)
  } else if (identical(pattern_mode, "mixed")) {
    sample(
      c("centered", "balanced", "low", "high"),
      size = ncol(data),
      replace = TRUE,
      prob = c(0.40, 0.25, 0.175, 0.175)
    )
  } else {
    rep(profile, ncol(data))
  }

  names(item_profiles) <- names(data)

  item_thresholds <- lapply(item_profiles, likert_thresholds, k = n_categories)

  threshold_dif <- data.frame(
    Variable = character(0),
    Groupe = character(0),
    Décalage = numeric(0),
    check.names = FALSE
  )

  affected_item <- NA_integer_
  affected_group <- NA_character_
  threshold_shift <- 0

  if (
    identical(measurement_invariance, "threshold_dif") &&
      !is.null(group_membership) &&
      length(unique(group_membership)) > 1
  ) {
    affected_item <- if (is.null(dif_item)) sample(seq_len(ncol(data)), size = 1) else as.integer(dif_item)
    affected_group <- unique(group_membership)[2]
    threshold_shift <- 0.60

    threshold_dif <- data.frame(
      Variable = names(data)[affected_item],
      Groupe = affected_group,
      Décalage = threshold_shift,
      check.names = FALSE
    )
  }

  ordinal_data <- as.data.frame(
    lapply(seq_along(data), function(j) {
      x <- data[[j]]
      thresholds <- item_thresholds[[j]]$values
      threshold_matrix <- matrix(
        thresholds,
        nrow = length(x),
        ncol = length(thresholds),
        byrow = TRUE
      )

      if (identical(j, affected_item)) {
        threshold_matrix[group_membership == affected_group, ] <-
          threshold_matrix[group_membership == affected_group, ] + threshold_shift
      }

      as.integer(1L + rowSums(x > threshold_matrix))
    }),
    check.names = FALSE
  )

  names(ordinal_data) <- names(data)

  threshold_matrix <- do.call(
    rbind,
    lapply(item_thresholds, function(x) x$values)
  )
  probability_matrix <- do.call(
    rbind,
    lapply(item_thresholds, function(x) x$probabilities)
  )

  # Une seule colonne de seuils (2 catégories) : garder une matrice
  threshold_matrix <- matrix(threshold_matrix, nrow = ncol(data))
  probability_matrix <- matrix(probability_matrix, nrow = ncol(data))

  rownames(threshold_matrix) <- names(data)
  rownames(probability_matrix) <- names(data)
  colnames(threshold_matrix) <- paste0("Seuil", seq_len(n_categories - 1))
  colnames(probability_matrix) <- paste0("P", seq_len(n_categories - 1))

  list(
    data = ordinal_data,
    profiles = item_profiles,
    thresholds = threshold_matrix,
    probabilities = probability_matrix,
    threshold_dif = threshold_dif
  )
}

# ============================================================
# Styles de réponse
# ============================================================

# Les styles de réponse sont appliqués à un sous-échantillon de personnes,
# avant l'ordinalisation. Ils représentent donc une variance de méthode
# cohérente entre les items d'un même répondant, plutôt qu'un artéfact item
# par item.
response_style_labels <- c(
  none = "Aucun",
  midpoint = "Tendance au milieu",
  extreme = "Tendance aux extrêmes",
  acquiescence = "Acquiescement"
)

apply_response_style <- function(
  data,
  group_membership,
  style = "none",
  proportion = 0.15
) {
  affected_cases <- data.frame(
    Ligne = integer(0),
    Groupe = character(0),
    Style = character(0),
    check.names = FALSE
  )

  if (identical(style, "none") || proportion <= 0) {
    return(list(data = data, cases = affected_cases))
  }

  n_affected <- min(nrow(data), max(1L, round(nrow(data) * proportion)))
  rows <- sort(sample(seq_len(nrow(data)), size = n_affected))
  styled_data <- data

  if (identical(style, "midpoint")) {
    styled_data[rows, ] <- styled_data[rows, , drop = FALSE] * 0.45
  } else if (identical(style, "extreme")) {
    styled_data[rows, ] <- styled_data[rows, , drop = FALSE] * 1.75
  } else if (identical(style, "acquiescence")) {
    styled_data[rows, ] <- styled_data[rows, , drop = FALSE] + 0.45
  }

  affected_cases <- data.frame(
    Ligne = rows,
    Groupe = as.character(group_membership[rows]),
    Style = unname(response_style_labels[style]),
    check.names = FALSE
  )

  list(data = styled_data, cases = affected_cases)
}

# ============================================================
# Données manquantes
# ============================================================

# Les données manquantes sont créées après toutes les transformations de
# réponse. Pour MAR, une variable auxiliaire demeure entièrement observée;
# pour MNAR, la probabilité d'absence augmente avec la réponse sous-jacente.
missingness_labels <- c(
  none = "Aucune",
  mcar = "MCAR — complètement au hasard",
  mar = "MAR — selon une variable observée",
  mnar = "MNAR — selon la valeur manquante elle-même"
)

apply_missingness <- function(
  data,
  driver_data,
  group_membership,
  mechanism = "none",
  rate = 0.10,
  anchor = NULL
) {
  missing_cases <- data.frame(
    Ligne = integer(0),
    Variable = character(0),
    Groupe = character(0),
    check.names = FALSE
  )

  info <- list(
    mechanism = mechanism,
    target_rate = if (identical(mechanism, "none")) 0 else rate,
    realized_rate = 0,
    mar_anchor = NA_character_,
    cases = missing_cases
  )

  if (identical(mechanism, "none") || rate <= 0) {
    return(list(data = data, info = info))
  }

  n <- nrow(data)
  p <- ncol(data)
  n_to_mask <- round(n * p * rate)

  if (n_to_mask == 0) {
    return(list(data = data, info = info))
  }

  candidate <- seq_len(n * p)
  weights <- rep(1, n * p)

  if (identical(mechanism, "mar")) {
    anchor <- if (is.null(anchor)) sample(seq_len(p), size = 1) else as.integer(anchor)
    info$mar_anchor <- names(data)[anchor]
    anchor_values <- driver_data[[anchor]]
    anchor_sd <- sd(anchor_values)
    anchor_z <- if (is.finite(anchor_sd) && anchor_sd > 0) {
      (anchor_values - mean(anchor_values)) / anchor_sd
    } else {
      rep(0, n)
    }

    # La variable auxiliaire reste observée : l'absence dépend uniquement
    # d'une information encore disponible dans le jeu de données.
    item_index <- rep(seq_len(p), each = n)
    candidate <- which(item_index != anchor)
    weights <- exp(pmax(-5, pmin(5, 0.85 * rep(anchor_z, p))))
  } else if (identical(mechanism, "mnar")) {
    driver_z <- vapply(seq_len(p), function(j) {
      x <- driver_data[[j]]
      x_sd <- sd(x)
      if (is.finite(x_sd) && x_sd > 0) {
        (x - mean(x)) / x_sd
      } else {
        rep(0, n)
      }
    }, numeric(n))
    weights <- exp(pmax(-5, pmin(5, 0.85 * as.vector(driver_z))))
  }

  # Garder une marge de cellules observées (au moins l'équivalent de deux
  # valeurs par variable) pour que les statistiques demeurent calculables.
  n_to_mask <- min(n_to_mask, length(candidate) - 2L * p)
  selected <- sort(sample(
    candidate,
    size = n_to_mask,
    replace = FALSE,
    prob = weights[candidate]
  ))
  coordinates <- arrayInd(selected, .dim = c(n, p))

  masked_data <- data
  for (j in seq_len(p)) {
    rows <- coordinates[coordinates[, 2] == j, 1]
    if (length(rows) > 0) {
      masked_data[rows, j] <- NA
    }
  }

  missing_cases <- data.frame(
    Ligne = coordinates[, 1],
    Variable = names(data)[coordinates[, 2]],
    Groupe = as.character(group_membership[coordinates[, 1]]),
    check.names = FALSE
  )

  info$realized_rate <- nrow(missing_cases) / (n * p)
  info$cases <- missing_cases

  list(data = masked_data, info = info)
}

# ============================================================
# Génération contrôlée de données factorielles
# ============================================================
generate_factor_data <- function(
  nfact,
  vpf,
  N,
  fc,
  pl,
  cl,
  low_vpf = 5,
  up_vpf = 15,
  distribution = "normal",
  skew_strength = 0.50,
  cross_loading_prop = 0.25,
  group_sizes = N,
  group_mean_diff = "none",
  group_cov_diff = "equal",
  response_format = "continuous",
  likert_profile = "balanced",
  likert_pattern_mode = "common",
  likert_categories = 5,
  measurement_invariance = "invariant",
  response_style = "none",
  response_style_prop = 0.15,
  missingness_mechanism = "none",
  missingness_rate = 0.10,
  structure = "correlated",
  gl = "M",
  reverse_prop = 0,
  sample_seed = NULL
) {
  if (!response_format %in% c("continuous", "likert")) {
    stop("Le format des réponses doit être « continuous » ou « likert ».")
  }

  if (!likert_profile %in% c("balanced", "centered", "low", "high")) {
    stop("Le profil Likert est invalide.")
  }

  if (!likert_pattern_mode %in% c("common", "mixed")) {
    stop("Le mode de profils Likert est invalide.")
  }

  likert_categories <- as.integer(likert_categories)
  if (length(likert_categories) != 1 || is.na(likert_categories) ||
    likert_categories < 2 || likert_categories > 7) {
    stop("Le nombre de catégories Likert doit être compris entre 2 et 7.")
  }

  if (!measurement_invariance %in% c(
    "invariant",
    "threshold_dif",
    "intercept_dif"
  )) {
    stop("Le scénario d'invariance de mesure est invalide.")
  }

  if (!response_style %in% c("none", "midpoint", "extreme", "acquiescence")) {
    stop("Le style de réponse est invalide.")
  }

  if (!missingness_mechanism %in% c("none", "mcar", "mar", "mnar")) {
    stop("Le mécanisme de données manquantes est invalide.")
  }

  if (!structure %in% c("correlated", "bifactor")) {
    stop("Le type de structure factorielle est invalide.")
  }

  nfact <- as.integer(nfact)
  if (length(nfact) != 1 || is.na(nfact) || nfact < 1 || nfact > 10) {
    stop("Le nombre de facteurs doit être un entier compris entre 1 et 10.")
  }

  if (identical(structure, "bifactor") && nfact < 2) {
    stop("Une structure bifactorielle exige au moins deux facteurs spécifiques.")
  }

  response_style_prop <- as.numeric(response_style_prop)
  if (
    length(response_style_prop) != 1 ||
      is.na(response_style_prop) ||
      response_style_prop < 0 ||
      response_style_prop > 1
  ) {
    stop("La proportion de style de réponse doit être comprise entre 0 et 1.")
  }

  missingness_rate <- as.numeric(missingness_rate)
  if (
    length(missingness_rate) != 1 ||
      is.na(missingness_rate) ||
      missingness_rate < 0 ||
      missingness_rate > 0.60
  ) {
    stop("Le taux de données manquantes doit être compris entre 0 et 0,60.")
  }

  reverse_prop <- as.numeric(reverse_prop)
  if (length(reverse_prop) != 1 || is.na(reverse_prop) ||
    reverse_prop < 0 || reverse_prop > 0.5) {
    stop("La proportion d'items inversés doit être comprise entre 0 et 0,50.")
  }

  # ------------------------------------------------------------
  # 0. Validation de la proportion de charges secondaires
  # ------------------------------------------------------------
  cross_loading_prop <- as.numeric(cross_loading_prop)

  if (
    length(cross_loading_prop) != 1 ||
      is.na(cross_loading_prop) ||
      cross_loading_prop < 0 ||
      cross_loading_prop > 1
  ) {
    stop(
      "La proportion de charges secondaires doit être comprise entre 0 et 1."
    )
  }

  skew_strength <- as.numeric(skew_strength)

  if (
    length(skew_strength) != 1 ||
      is.na(skew_strength) ||
      skew_strength <= 0
  ) {
    stop("Le degré d'asymétrie doit être une valeur numérique positive.")
  }

  # ------------------------------------------------------------
  # 1. Nombre d'indicateurs par facteur
  # ------------------------------------------------------------
  if (identical(vpf, "S")) {
    n_items_factor <- sample(5:10, nfact, replace = TRUE)
  } else if (identical(vpf, "M")) {
    n_items_factor <- sample(5:15, nfact, replace = TRUE)
  } else if (identical(vpf, "L")) {
    n_items_factor <- sample(5:20, nfact, replace = TRUE)
  } else if (identical(vpf, "R")) {
    low_vpf <- as.integer(low_vpf)
    up_vpf <- as.integer(up_vpf)
    if (anyNA(c(low_vpf, up_vpf)) || low_vpf < 2 || up_vpf < low_vpf) {
      stop("Les bornes du nombre de variables par facteur sont invalides.")
    }
    n_items_factor <- if (low_vpf == up_vpf) {
      rep(low_vpf, nfact)
    } else {
      sample(low_vpf:up_vpf, nfact, replace = TRUE)
    }
  } else {
    vpf_value <- suppressWarnings(as.integer(vpf))
    if (is.na(vpf_value) || vpf_value < 2 || vpf_value > 30) {
      stop("Le nombre de variables par facteur doit être compris entre 2 et 30.")
    }
    n_items_factor <- rep(vpf_value, nfact)
  }

  n_items <- sum(n_items_factor)

  # Facteur principal associé à chaque indicateur
  item_factor <- rep(
    seq_len(nfact),
    times = n_items_factor
  )

  # ------------------------------------------------------------
  # 2. Matrice des corrélations factorielles Phi
  # ------------------------------------------------------------
  if (nfact == 1 || identical(structure, "bifactor")) {
    # Modèle bifactoriel : facteurs spécifiques orthogonaux entre eux
    Phi <- diag(nfact)
  } else if (identical(fc, "R")) {
    # Générer des corrélations aléatoires jusqu'à obtenir
    # une matrice définie positive.
    repeat {
      Phi <- diag(nfact)

      random_cor <- runif(
        nfact * (nfact - 1) / 2,
        min = 0,
        max = 0.50
      )

      Phi[lower.tri(Phi)] <- random_cor
      Phi[upper.tri(Phi)] <- t(Phi)[upper.tri(Phi)]

      if (
        all(
          eigen(
            Phi,
            symmetric = TRUE
          )$values > 1e-8
        )
      ) {
        break
      }
    }
  } else {
    fc_value <- as.numeric(fc)

    Phi <- matrix(
      fc_value,
      nrow = nfact,
      ncol = nfact
    )

    diag(Phi) <- 1
  }

  rownames(Phi) <- colnames(Phi) <- paste0(
    "F",
    seq_len(nfact)
  )

  # ------------------------------------------------------------
  # 3. Matrice des charges factorielles Lambda
  # ------------------------------------------------------------
  Lambda <- matrix(
    0,
    nrow = n_items,
    ncol = nfact
  )

  get_primary_loading <- function(type) {
    if (identical(type, "L")) {
      runif(1, 0.35, 0.50)
    } else if (identical(type, "M")) {
      runif(1, 0.50, 0.65)
    } else if (identical(type, "H")) {
      runif(1, 0.65, 0.80)
    } else if (identical(type, "R")) {
      runif(1, 0.35, 0.80)
    } else {
      as.numeric(type)
    }
  }

  get_general_loading <- function(type) {
    if (identical(type, "L")) {
      runif(1, 0.30, 0.45)
    } else if (identical(type, "M")) {
      runif(1, 0.45, 0.60)
    } else if (identical(type, "H")) {
      runif(1, 0.60, 0.70)
    } else {
      as.numeric(type)
    }
  }

  get_cross_loading <- function(type) {
    if (identical(type, "None")) {
      0
    } else if (identical(type, "L")) {
      runif(1, -0.10, 0.10)
    } else if (identical(type, "H")) {
      magnitude <- runif(
        1,
        0.10,
        0.20
      )

      sign_value <- sample(
        c(-1, 1),
        1
      )

      sign_value * magnitude
    } else if (identical(type, "R")) {
      runif(
        1,
        -0.20,
        0.20
      )
    } else {
      as.numeric(type)
    }
  }

  for (i in seq_len(n_items)) {
    primary_factor <- item_factor[i]

    for (j in seq_len(nfact)) {
      if (j == primary_factor) {
        # Charge principale toujours présente
        Lambda[i, j] <- get_primary_loading(pl)
      } else if (identical(cl, "None")) {
        # Aucune charge secondaire
        Lambda[i, j] <- 0
      } else {
        # Déterminer si cette charge secondaire est présente
        has_cross_loading <- runif(1) < cross_loading_prop

        if (isTRUE(has_cross_loading)) {
          Lambda[i, j] <- get_cross_loading(cl)
        } else {
          Lambda[i, j] <- 0
        }
      }
    }
  }

  rownames(Lambda) <- paste0(
    "V",
    seq_len(n_items)
  )

  colnames(Lambda) <- paste0(
    "F",
    seq_len(nfact)
  )

  # ------------------------------------------------------------
  # 3b. Facteur général (modèle bifactoriel)
  # ------------------------------------------------------------
  # Le facteur général FG est placé en première colonne. Il est orthogonal
  # aux facteurs spécifiques F1, F2, ...
  if (identical(structure, "bifactor")) {
    general_loadings <- vapply(
      seq_len(n_items),
      function(i) get_general_loading(gl),
      numeric(1)
    )

    Lambda <- cbind(FG = general_loadings, Lambda)
    Phi <- rbind(
      cbind(1, matrix(0, 1, nfact)),
      cbind(matrix(0, nfact, 1), Phi)
    )
    rownames(Phi) <- colnames(Phi) <- colnames(Lambda)
  }

  # Paramètres arrondis à trois décimales : les valeurs affichées et
  # exportées sont exactement celles qui génèrent les données.
  Lambda <- round(Lambda, 3) + 0

  factor_names <- colnames(Lambda)
  n_latent <- ncol(Lambda)

  # ------------------------------------------------------------
  # 3c. Items à formulation inversée
  # ------------------------------------------------------------
  # Inverser un item revient à changer le signe de toute sa ligne de
  # charges : sa communalité et son unicité ne changent pas.
  reversed_items <- character(0)

  if (reverse_prop > 0) {
    for (k in seq_len(nfact)) {
      items_k <- which(item_factor == k)
      n_k <- length(items_k)
      if (n_k < 2) next

      n_rev <- floor(reverse_prop * n_k + 0.5 - 1e-9)
      n_rev <- min(n_k - 1L, max(1L, n_rev))

      chosen <- if (n_k == 1) items_k else sample(items_k, n_rev)
      Lambda[chosen, ] <- -Lambda[chosen, ]
      reversed_items <- c(reversed_items, rownames(Lambda)[chosen])
    }

    reversed_items <- rownames(Lambda)[rownames(Lambda) %in% reversed_items]
  }

  # ------------------------------------------------------------
  # 4. Variance commune et unicités
  # ------------------------------------------------------------
  common_cov <- Lambda %*%
    Phi %*%
    t(Lambda)

  communalities <- diag(common_cov)
  uniquenesses <- 1 - communalities

  # Une structure avec communalité >= 1 n'est pas admissible.
  if (any(uniquenesses <= 0)) {
    bad_items <- which(
      uniquenesses <= 0
    )

    stop(
      paste0(
        "Structure factorielle non admissible : la communalité est ",
        "supérieure ou égale à 1 pour ",
        length(bad_items),
        " variable(s). Réduisez les charges factorielles, les ",
        "charges secondaires",
        if (identical(structure, "bifactor")) ", les charges générales" else "",
        " ou les corrélations entre facteurs."
      )
    )
  }

  Theta <- diag(
    uniquenesses
  )

  rownames(Theta) <- colnames(Theta) <- rownames(Lambda)

  # ------------------------------------------------------------
  # 5. Matrice populationnelle des variables observées
  # ------------------------------------------------------------
  Sigma <- common_cov + Theta

  rownames(Sigma) <- colnames(Sigma) <- rownames(Lambda)

  # Vérification numérique
  if (
    any(
      eigen(
        Sigma,
        symmetric = TRUE
      )$values <= 1e-8
    )
  ) {
    stop(
      paste0(
        "La matrice de corrélations populationnelle obtenue ",
        "n'est pas définie positive."
      )
    )
  }

  # ------------------------------------------------------------
  # 6. Génération explicite du modèle X = Lambda F + epsilon
  # ------------------------------------------------------------

  # Fonction interne permettant de créer une distribution
  # asymétrique, puis de la recentrer et de la standardiser.
  make_skewed <- function(x, strength) {
    z <- exp(
      strength * x
    )

    z <- as.numeric(
      scale(z)
    )

    z
  }

  # ------------------------------------------------------------
  # Moyennes factorielles et génération des groupes
  # ------------------------------------------------------------

  group_sizes <- as.integer(group_sizes)
  n_groups <- length(group_sizes)
  N <- sum(group_sizes)

  # Amplitude des différences de moyennes factorielles
  mean_shift <- switch(group_mean_diff,
    "none" = 0,
    "low" = 0.25,
    "moderate" = 0.50,
    "high" = 0.80,
    0
  )

  # Groupe 1 = population de référence
  factor_means <- matrix(
    0,
    nrow = n_groups,
    ncol = n_latent
  )

  # Les autres groupes reçoivent des profils latents distincts
  if (n_groups > 1 && mean_shift > 0) {
    for (g in 2:n_groups) {
      primary_factor <- ((g - 2) %% n_latent) + 1

      factor_means[g, primary_factor] <- mean_shift

      # Si les groupes dépassent le nombre de facteurs,
      # ajouter une seconde composante pour éviter des profils identiques.
      if (g - 1 > n_latent && n_latent > 1) {
        secondary_factor <- (primary_factor %% n_latent) + 1
        factor_means[g, secondary_factor] <- -mean_shift
      }
    }
  }

  colnames(factor_means) <- factor_names

  rownames(factor_means) <- paste0(
    "G",
    seq_len(n_groups)
  )

  # ------------------------------------------------------------
  # Matrices factorielles par groupe
  # Variances ET corrélations peuvent différer
  # ------------------------------------------------------------

  group_factor_covariances <- vector("list", n_groups)
  group_factor_correlations <- vector("list", n_groups)

  # Intensité de l'hétérogénéité intergroupe
  cov_strength <- switch(group_cov_diff,
    "equal" = 0,
    "moderate" = 0.20,
    "high" = 0.40,
    0
  )

  for (g in seq_len(n_groups)) {
    # ----------------------------------------------------------
    # Groupe 1 : structure factorielle de référence
    # ----------------------------------------------------------
    if (g == 1 || cov_strength == 0) {
      R_g <- Phi
      sd_g <- rep(1, n_latent)
    } else {
      # --------------------------------------------------------
      # 1. Faire varier réellement les corrélations
      #    (le modèle bifactoriel conserve des facteurs orthogonaux :
      #    seules les variances factorielles changent)
      # --------------------------------------------------------
      R_g <- Phi

      if (n_latent > 1 && !identical(structure, "bifactor")) {
        for (i in seq_len(n_latent - 1)) {
          for (j in (i + 1):n_latent) {
            # Alternance déterministe selon groupe et paire
            direction <- if (
              ((g + i + j) %% 2) == 0
            ) {
              1
            } else {
              -1
            }

            delta <- direction * cov_strength

            R_g[i, j] <- R_g[i, j] + delta
            R_g[j, i] <- R_g[i, j]
          }
        }

        # Garder les corrélations dans une zone raisonnable
        R_g[R_g > 0.80] <- 0.80
        R_g[R_g < -0.80] <- -0.80

        diag(R_g) <- 1

        # Garantir une matrice de corrélations admissible
        if (min(eigen(R_g, symmetric = TRUE)$values) <= 1e-8) {
          R_g <- as.matrix(
            Matrix::nearPD(
              R_g,
              corr = TRUE,
              keepDiag = TRUE
            )$mat
          )
        }
      }

      # --------------------------------------------------------
      # 2. Faire également varier les écarts-types factoriels
      # --------------------------------------------------------
      sd_g <- rep(1, n_latent)

      target_factor <- ((g - 2) %% n_latent) + 1

      direction_sd <- if ((g %% 2) == 0) 1 else -1

      sd_g[target_factor] <-
        1 + direction_sd * cov_strength
    }

    # ----------------------------------------------------------
    # 3. Passer corrélations -> covariances
    # ----------------------------------------------------------
    D_g <- diag(sd_g, nrow = n_latent)

    Phi_g <- D_g %*% R_g %*% D_g

    dimnames(R_g) <- list(factor_names, factor_names)
    dimnames(Phi_g) <- list(factor_names, factor_names)

    group_factor_correlations[[g]] <- R_g
    group_factor_covariances[[g]] <- Phi_g
  }

  names(group_factor_correlations) <- paste0(
    "G",
    seq_len(n_groups)
  )

  names(group_factor_covariances) <- paste0(
    "G",
    seq_len(n_groups)
  )

  # ------------------------------------------------------------
  # Tirages qui définissent la POPULATION (avant l'échantillon)
  # ------------------------------------------------------------
  # Tous les choix aléatoires qui décrivent la population sont faits ici :
  # variables à erreur asymétrique, item touché par le DIF, profils Likert
  # variés, variable auxiliaire MAR. Les tirages qui suivent ne concernent
  # plus que les personnes. Une « graine d'échantillon » peut donc produire
  # un nouvel échantillon de la MÊME population.
  skew_plan <- NULL
  if (identical(distribution, "skewed")) {
    # Le niveau choisi sert aussi de proportion approximative de variables touchées;
    # l'intensité varie d'une variable à l'autre, majoritairement vers la droite.
    min_strength <- max(0.15, skew_strength * 0.50)
    max_strength <- min(1.00, skew_strength * 1.30)
    skewed_items <- runif(n_items) < skew_strength
    skew_plan <- data.frame(
      item = which(skewed_items),
      force = runif(sum(skewed_items), min_strength, max_strength),
      sens = sample(c(-1, 1), sum(skewed_items), replace = TRUE, prob = c(0.25, 0.75))
    )
  }

  multi_groups <- n_groups > 1
  intercept_dif_item <- if (identical(measurement_invariance, "intercept_dif") && multi_groups) {
    sample(seq_len(n_items), size = 1)
  } else {
    NULL
  }

  likert_profiles_plan <- NULL
  threshold_dif_item <- NULL
  if (identical(response_format, "likert")) {
    likert_profiles_plan <- if (identical(likert_pattern_mode, "mixed")) {
      sample(c("centered", "balanced", "low", "high"), size = n_items,
             replace = TRUE, prob = c(0.40, 0.25, 0.175, 0.175))
    } else {
      rep(likert_profile, n_items)
    }
    if (identical(measurement_invariance, "threshold_dif") && multi_groups) {
      threshold_dif_item <- sample(seq_len(n_items), size = 1)
    }
  }

  mar_anchor <- if (identical(missingness_mechanism, "mar") && missingness_rate > 0) {
    sample(seq_len(n_items), size = 1)
  } else {
    NULL
  }

  # ------------------------------------------------------------
  # Tirages qui définissent l'ÉCHANTILLON
  # ------------------------------------------------------------
  if (!is.null(sample_seed)) {
    set.seed(as.integer(sample_seed))
  }

  # Générer les scores factoriels groupe par groupe
  factor_scores <- do.call(
    rbind,
    lapply(seq_len(n_groups), function(g) {
      matrix(
        MASS::mvrnorm(
          n = group_sizes[g],
          mu = factor_means[g, ],
          Sigma = group_factor_covariances[[g]]
        ),
        nrow = group_sizes[g]
      )
    })
  )
  colnames(factor_scores) <- factor_names

  group_membership <- rep(
    paste0("G", seq_len(n_groups)),
    times = group_sizes
  )

  # Générer les erreurs standardisées
  errors_std <- matrix(
    rnorm(N * n_items),
    nrow = N,
    ncol = n_items
  )

  # Introduire la non-normalité si elle est demandée
  skewed_variables <- character(0)

  if (!is.null(skew_plan)) {
    # Les facteurs latents restent normaux : la non-normalité est introduite
    # dans les erreurs propres aux variables, selon le plan tiré plus haut.
    for (k in seq_len(nrow(skew_plan))) {
      j <- skew_plan$item[k]
      errors_std[, j] <- skew_plan$sens[k] * make_skewed(errors_std[, j], skew_plan$force[k])
    }
    skewed_variables <- rownames(Lambda)[skew_plan$item]
  }


  # Ajuster chaque erreur à son unicité théorique
  errors <- sweep(
    errors_std,
    MARGIN = 2,
    STATS = sqrt(uniquenesses),
    FUN = "*"
  )

  # Modèle factoriel
  response <- factor_scores %*%
    t(Lambda) +
    errors

  colnames(response) <- rownames(Lambda)

  response <- as.data.frame(
    response
  )

  response_continuous_base <- response
  response_continuous <- response_continuous_base
  likert_info <- NULL

  response_style_cases <- data.frame(
    Ligne = integer(0),
    Groupe = character(0),
    Style = character(0),
    check.names = FALSE
  )

  intercept_dif <- data.frame(
    Variable = character(0),
    Groupe = character(0),
    Décalage = numeric(0),
    check.names = FALSE
  )

  if (!is.null(intercept_dif_item)) {
    affected_item <- intercept_dif_item
    affected_group <- unique(group_membership)[2]
    intercept_shift <- 0.60

    response_continuous[
      group_membership == affected_group,
      affected_item
    ] <- response_continuous[
      group_membership == affected_group,
      affected_item
    ] + intercept_shift

    intercept_dif <- data.frame(
      Variable = names(response_continuous)[affected_item],
      Groupe = affected_group,
      Décalage = intercept_shift,
      check.names = FALSE
    )
  }

  if (identical(response_format, "likert")) {
    styled_response <- apply_response_style(
      response_continuous,
      group_membership = group_membership,
      style = response_style,
      proportion = response_style_prop
    )
    response_continuous <- styled_response$data
    response_style_cases <- styled_response$cases
  }

  response <- response_continuous

  if (identical(response_format, "likert")) {
    likert_info <- discretize_likert(
      response_continuous,
      profile = likert_profile,
      pattern_mode = likert_pattern_mode,
      group_membership = group_membership,
      measurement_invariance = measurement_invariance,
      n_categories = likert_categories,
      item_profiles = likert_profiles_plan,
      dif_item = threshold_dif_item
    )
    response <- likert_info$data
  }

  response_complete <- response

  missingness <- apply_missingness(
    response,
    driver_data = response_continuous,
    group_membership = group_membership,
    mechanism = missingness_mechanism,
    rate = missingness_rate,
    anchor = mar_anchor
  )
  response <- missingness$data

  # ------------------------------------------------------------
  # 7. Retourner les objets utiles
  # ------------------------------------------------------------
  list(
    response = response,
    response_complete = response_complete,
    response_continuous_base = response_continuous_base,
    response_continuous = response_continuous,
    response_format = response_format,
    structure = structure,
    likert_categories = if (identical(response_format, "likert")) likert_categories else NULL,
    likert_profile = if (identical(response_format, "likert")) likert_profile else NULL,
    likert_pattern_mode = if (identical(response_format, "likert")) likert_pattern_mode else NULL,
    measurement_invariance = measurement_invariance,
    response_style = if (identical(response_format, "likert")) response_style else "none",
    response_style_prop = if (identical(response_format, "likert")) response_style_prop else 0,
    response_style_cases = response_style_cases,
    missingness_mechanism = missingness$info$mechanism,
    missingness_rate = missingness$info$target_rate,
    missingness_realized_rate = missingness$info$realized_rate,
    missingness_mar_anchor = missingness$info$mar_anchor,
    missingness_cases = missingness$info$cases,
    likert_item_profiles = if (is.null(likert_info)) NULL else likert_info$profiles,
    likert_thresholds = if (is.null(likert_info)) NULL else likert_info$thresholds,
    likert_probabilities = if (is.null(likert_info)) NULL else likert_info$probabilities,
    threshold_dif = if (is.null(likert_info)) NULL else likert_info$threshold_dif,
    intercept_dif = intercept_dif,
    loadings = Lambda,
    factor_names = factor_names,
    factor_assignments = item_factor,
    reversed_items = reversed_items,
    skewed_variables = skewed_variables,
    factor_correlations = Phi,
    communalities = communalities,
    uniquenesses = uniquenesses,
    population_correlation = Sigma,
    factor_scores = factor_scores,
    factor_means = factor_means,
    group_factor_correlations = group_factor_correlations,
    group_factor_covariances = group_factor_covariances,
    group_membership = group_membership,
    group_sizes = group_sizes
  )
}

# ============================================================
# Corrélation populationnelle globale pour plusieurs groupes
# ============================================================

pooled_population_correlation <- function(data_obj) {

  Lambda <- data_obj$loadings
  Theta <- diag(data_obj$uniquenesses)

  group_sizes <- data_obj$group_sizes
  weights <- group_sizes / sum(group_sizes)

  factor_means <- data_obj$factor_means
  factor_covs <- data_obj$group_factor_covariances

  n_groups <- length(group_sizes)

  # Moyenne observée populationnelle de chaque groupe
  group_means <- lapply(
    seq_len(n_groups),
    function(g) {
      as.numeric(
        Lambda %*% factor_means[g, ]
      )
    }
  )

  # Covariance observée populationnelle de chaque groupe
  group_covs <- lapply(
    seq_len(n_groups),
    function(g) {
      Lambda %*%
        factor_covs[[g]] %*%
        t(Lambda) +
        Theta
    }
  )

  # Moyenne populationnelle globale pondérée
  pooled_mean <- Reduce(
    `+`,
    Map(
      function(w, mu) w * mu,
      weights,
      group_means
    )
  )

  # Covariance de la population mélangée :
  # variation intragroupe + variation intergroupe
  pooled_cov <- matrix(
    0,
    nrow = nrow(Lambda),
    ncol = nrow(Lambda)
  )

  for (g in seq_len(n_groups)) {

    delta <- group_means[[g]] - pooled_mean

    pooled_cov <- pooled_cov +
      weights[g] * (
        group_covs[[g]] +
          tcrossprod(delta)
      )
  }

  dimnames(pooled_cov) <- list(
    rownames(Lambda),
    rownames(Lambda)
  )

  cov2cor(pooled_cov)
}

# ============================================================
# Fidélité populationnelle des échelles (groupe de référence G1)
# ============================================================
# Pour chaque facteur, l'échelle est la somme de ses indicateurs principaux,
# les items inversés étant recodés. Les quantités sont exactes puisque la
# structure populationnelle est connue.
#   ω (total)       = variance commune du score / variance totale du score
#   ω (facteur)     = variance due au seul facteur de l'échelle / variance totale
#   α populationnel = k/(k-1) (1 - somme des variances / variance totale)
population_reliability <- function(data_obj, group = "G1") {
  Lambda <- data_obj$loadings
  Phi_g <- data_obj$group_factor_covariances[[group]]
  Theta <- diag(data_obj$uniquenesses)
  Sigma_g <- Lambda %*% Phi_g %*% t(Lambda) + Theta
  common_g <- Lambda %*% Phi_g %*% t(Lambda)

  item_names <- rownames(Lambda)
  signs <- ifelse(item_names %in% data_obj$reversed_items, -1, 1)
  bifactor <- identical(data_obj$structure, "bifactor")
  offset <- if (bifactor) 1L else 0L
  n_specific <- max(data_obj$factor_assignments)

  scale_stats <- function(idx, factor_col) {
    s <- signs[idx]
    total <- as.numeric(t(s) %*% Sigma_g[idx, idx, drop = FALSE] %*% s)
    common <- as.numeric(t(s) %*% common_g[idx, idx, drop = FALSE] %*% s)
    k <- length(idx)
    alpha <- if (k > 1) {
      k / (k - 1) * (1 - sum(diag(Sigma_g)[idx]) / total)
    } else {
      NA_real_
    }
    factor_only <- if (is.na(factor_col)) {
      NA_real_
    } else {
      (sum(s * Lambda[idx, factor_col]))^2 * Phi_g[factor_col, factor_col] / total
    }
    c(omega = common / total, omega_factor = factor_only, alpha = alpha)
  }

  rows <- lapply(seq_len(n_specific), function(k) {
    idx <- which(data_obj$factor_assignments == k)
    col <- k + offset
    primary <- abs(Lambda[idx, col])
    others <- setdiff(seq_len(ncol(Lambda)), c(col, if (bifactor) 1L))
    has_cross <- length(others) > 0 && any(abs(Lambda[idx, others, drop = FALSE]) > 1e-12)

    nature <- if (bifactor) {
      "Bifactoriel"
    } else if (has_cross) {
      "Congénérique + charges secondaires"
    } else if (diff(range(primary)) < 1e-10) {
      "Parallèle"
    } else {
      "Congénérique"
    }

    st <- scale_stats(idx, col)

    data.frame(
      Échelle = paste0("F", k),
      Items = length(idx),
      Inversés = sum(item_names[idx] %in% data_obj$reversed_items),
      `Charge moy.` = mean(primary),
      `Charge min.` = min(primary),
      `Charge max.` = max(primary),
      `ω total` = st[["omega"]],
      `ω du facteur` = st[["omega_factor"]],
      `α populationnel` = st[["alpha"]],
      Nature = nature,
      check.names = FALSE
    )
  })

  out <- do.call(rbind, rows)

  # Un seul facteur sans facteur général : le score total est l'échelle F1
  if (n_specific == 1 && !bifactor) {
    return(out)
  }

  # Score total sur l'ensemble des items
  all_idx <- seq_along(item_names)
  st_all <- scale_stats(all_idx, if (bifactor) 1L else NA_integer_)
  total_row <- data.frame(
    Échelle = if (bifactor) "Score total (FG)" else "Score total",
    Items = length(all_idx),
    Inversés = length(data_obj$reversed_items),
    `Charge moy.` = if (bifactor) mean(abs(Lambda[, 1])) else NA_real_,
    `Charge min.` = if (bifactor) min(abs(Lambda[, 1])) else NA_real_,
    `Charge max.` = if (bifactor) max(abs(Lambda[, 1])) else NA_real_,
    `ω total` = st_all[["omega"]],
    `ω du facteur` = st_all[["omega_factor"]],
    `α populationnel` = st_all[["alpha"]],
    Nature = if (bifactor) "ω du facteur = ω hiérarchique" else "Score multidimensionnel",
    check.names = FALSE
  )

  rbind(out, total_row)
}

# ============================================================
# Statistiques descriptives par variable
# ============================================================
describe_variables <- function(df) {
  stats <- lapply(names(df), function(v) {
    x <- df[[v]]
    ok <- x[!is.na(x)]
    m <- mean(ok)
    s <- sd(ok)
    z <- (ok - m)
    m2 <- mean(z^2)
    data.frame(
      Variable = v,
      `N valides` = length(ok),
      `% manquant` = 100 * mean(is.na(x)),
      Moyenne = m,
      `Écart-type` = s,
      Min = min(ok),
      Max = max(ok),
      Asymétrie = if (m2 > 0) mean(z^3) / m2^1.5 else NA_real_,
      `Aplatissement (excès)` = if (m2 > 0) mean(z^4) / m2^2 - 3 else NA_real_,
      check.names = FALSE
    )
  })
  do.call(rbind, stats)
}

# ============================================================
# Syntaxe lavaan du modèle populationnel (corrigé enseignant)
# ============================================================
lavaan_syntax <- function(data_obj, data_file = "donnees_etudiants.csv") {
  Lambda <- data_obj$loadings
  item_names <- rownames(Lambda)
  n_specific <- max(data_obj$factor_assignments)
  bifactor <- identical(data_obj$structure, "bifactor")
  likert <- identical(data_obj$response_format, "likert")
  multigroup <- length(data_obj$group_sizes) > 1
  has_missing <- !identical(data_obj$missingness_mechanism, "none")

  wrap_items <- function(items) {
    chunks <- split(items, ceiling(seq_along(items) / 8))
    paste(vapply(chunks, paste, character(1), collapse = " + "), collapse = " +\n         ")
  }

  model_lines <- vapply(seq_len(n_specific), function(k) {
    items <- item_names[data_obj$factor_assignments == k]
    sprintf("  F%d =~ %s", k, wrap_items(items))
  }, character(1))

  if (bifactor) {
    model_lines <- c(sprintf("  FG =~ %s", wrap_items(item_names)), model_lines)
  }

  options <- c("data = donnees", "std.lv = TRUE")
  if (bifactor) options <- c(options, "orthogonal = TRUE")
  if (likert) options <- c(options, "ordered = TRUE")
  if (multigroup) options <- c(options, 'group = "Groupe"')
  if (has_missing) {
    options <- c(options, if (likert) 'missing = "pairwise"' else 'missing = "fiml"')
  }

  c(
    "# ==========================================================",
    "# Modèle de mesure ayant servi à générer les données",
    "# (indicateurs principaux seulement; les charges secondaires",
    "#  éventuelles ne sont pas spécifiées)",
    "# ==========================================================",
    "",
    "library(lavaan)",
    "",
    sprintf('donnees <- read.csv("%s")', data_file),
    "",
    "modele <- '",
    model_lines,
    "'",
    "",
    "ajustement <- cfa(",
    paste0("  modele,\n  ", paste(options, collapse = ",\n  ")),
    ")",
    "",
    "summary(ajustement, fit.measures = TRUE, standardized = TRUE)",
    if (length(data_obj$reversed_items) > 0) {
      c(
        "",
        "# Les items inversés reçoivent une charge négative dans ce modèle :",
        paste0("# ", paste(data_obj$reversed_items, collapse = ", "))
      )
    }
  )
}

# ============================================================
# Réglages par défaut et préréglages
# ============================================================
`%||%` <- function(a, b) if (is.null(a)) b else a

default_settings <- list(
  nfact = 3, vpf_type = "M", vpf_fixed = 5, low_vpf = 5, up_vpf = 15,
  structure = "correlated", gl_type = "M", gl_fixed = 0.5,
  fc_type = "R", fc_fixed = 0.3, pl_type = "R", pl_fixed = 0.6,
  cl_type = "R", cl_fixed = 0.1, cross_loading_prop = "0.25",
  reverse_prop = "0", distri = "normal", skew_strength = "0.5",
  response_format = "continuous", likert_categories = "5",
  likert_pattern_mode = "common", likert_profile = "balanced",
  response_style = "none", response_style_prop = 15,
  missing_mechanism = "none", missing_rate = 10
)

presets <- list(
  preset_personality = list(
    title = "Personnalité",
    text = "5 facteurs corrélés (0,30), 5 items par facteur, charges moyennes et faibles charges secondaires.",
    values = list(nfact = 5, vpf_type = "fixed", vpf_fixed = 5, fc_type = "fixed",
      fc_fixed = 0.30, pl_type = "M", cl_type = "L", cross_loading_prop = "0.25")
  ),
  preset_cognitive = list(
    title = "Tests cognitifs",
    text = "3 aptitudes corrélées (0,40), 6 épreuves par aptitude, charges élevées et structure simple.",
    values = list(nfact = 3, vpf_type = "fixed", vpf_fixed = 6, fc_type = "fixed",
      fc_fixed = 0.40, pl_type = "H", cl_type = "None")
  ),
  preset_social = list(
    title = "Échelles d'attitudes",
    text = "4 facteurs, 5 à 15 items, erreurs asymétriques et charges secondaires marquées.",
    values = list(nfact = 4, vpf_type = "M", distri = "skewed", skew_strength = "0.5",
      fc_type = "fixed", fc_fixed = 0.25, pl_type = "M", cl_type = "H",
      cross_loading_prop = "0.5")
  ),
  preset_academic = list(
    title = "Performance académique",
    text = "2 facteurs fortement corrélés (0,50), 8 items par facteur, charges élevées.",
    values = list(nfact = 2, vpf_type = "fixed", vpf_fixed = 8, fc_type = "fixed",
      fc_fixed = 0.50, pl_type = "H", cl_type = "L", cross_loading_prop = "0.25")
  ),
  preset_bifactor = list(
    title = "Détresse psychologique (bifactoriel)",
    text = "Un facteur général de détresse et 3 facteurs spécifiques orthogonaux, 6 items chacun.",
    values = list(nfact = 3, vpf_type = "fixed", vpf_fixed = 6, structure = "bifactor",
      gl_type = "M", pl_type = "L", cl_type = "None")
  ),
  preset_survey = list(
    title = "Sondage Likert",
    text = "4 échelles de 6 items en 7 points, un tiers d'items inversés, 15 % d'acquiescement et 10 % de données manquantes MAR.",
    values = list(nfact = 4, vpf_type = "fixed", vpf_fixed = 6, fc_type = "fixed",
      fc_fixed = 0.30, pl_type = "M", cl_type = "L", cross_loading_prop = "0.25",
      reverse_prop = "0.3333", response_format = "likert", likert_categories = "7",
      response_style = "acquiescence", response_style_prop = 15,
      missing_mechanism = "mar", missing_rate = 10)
  )
)
