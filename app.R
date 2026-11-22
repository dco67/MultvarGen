source("global.R")

css_multivgen <- "
.table td, .table th { white-space: nowrap; }
.etape-liste { counter-reset: etape; list-style: none; padding-left: 0; margin-bottom: 0; }
.etape-liste li { counter-increment: etape; position: relative; padding: 0.35rem 0 0.35rem 2.3rem; }
.etape-liste li::before { content: counter(etape); position: absolute; left: 0; top: 0.3rem;
  width: 1.6rem; height: 1.6rem; border-radius: 50%; background: #e7f1ff; color: #0d6efd;
  font-weight: 600; text-align: center; line-height: 1.6rem; font-size: 0.85rem; }
.statut-generation { border-left: 4px solid #198754; background: #f3faf6; padding: 0.6rem 0.9rem;
  border-radius: 4px; margin-top: 0.75rem; }
.statut-generation .graine { font-family: monospace; font-weight: 600; }
.encadre-info { border-left: 4px solid #0d6efd; background: #f4f8ff; padding: 0.6rem 0.9rem;
  border-radius: 4px; margin-bottom: 0.9rem; }
.encadre-att { border-left: 4px solid #fd7e14; background: #fff7ef; padding: 0.6rem 0.9rem;
  border-radius: 4px; margin-bottom: 0.9rem; }
.badge-nature { display: inline-block; padding: 0.15rem 0.55rem; border-radius: 999px;
  background: #e8f5ee; color: #146c43; font-weight: 600; font-size: 0.85rem; }
"

ui <- page_navbar(
  title = "Générateur de données factorielles",
  id = "main_navigation",
  fillable = FALSE,
  header = tags$head(tags$style(HTML(css_multivgen))),

  # ============================================================
  # INTRODUCTION
  # ============================================================
  nav_panel(
    title = "Introduction",
    icon = icon("info-circle"),
    card(
      card_header("Générateur de données factorielles"),
      card_body(
        p(
          "Cette application génère des jeux de données multivariés dont la ",
          "structure factorielle est connue. Puisque la population est fixée par ",
          "vous, il devient possible de vérifier ce qu'une analyse retrouve, ce ",
          "qu'elle manque et pourquoi."
        ),
        h4("Principe de génération"),
        p(
          "Chaque variable observée est construite selon le modèle factoriel ",
          tags$em("X = ΛF + ε"),
          " : une combinaison de facteurs latents (pondérés par les charges Λ) et ",
          "d'une composante unique ε. Vous contrôlez notamment :"
        ),
        tags$ul(
          tags$li(
            "le nombre de facteurs et d'indicateurs, les charges principales et ",
            "secondaires, les corrélations entre facteurs et la proportion d'items ",
            "à formulation inversée;"
          ),
          tags$li(
            "le type de structure : facteurs corrélés ou structure bifactorielle ",
            "(un facteur général commun à tous les items et des facteurs spécifiques);"
          ),
          tags$li(
            "la distribution des variables (normale ou asymétrique) et leur format ",
            "(continu ou Likert de 2 à 7 catégories, avec styles de réponse);"
          ),
          tags$li(
            "plusieurs groupes, dont les moyennes et les covariances factorielles ",
            "peuvent différer, ainsi qu'une violation contrôlée de l'invariance de mesure;"
          ),
          tags$li(
            "des données manquantes selon un mécanisme MCAR, MAR ou MNAR."
          )
        ),
        h4("Parcours recommandé"),
        tags$ol(
          tags$li(
            strong("Paramétrer la population"),
            " dans l'onglet Configurer, ou partir d'un préréglage."
          ),
          tags$li(
            strong("Générer les données"),
            " et noter la graine affichée : elle permet de reproduire exactement ",
            "le même jeu de données. Le bouton « Nouvel échantillon, même population » ",
            "tire de nouvelles personnes sans changer la population."
          ),
          tags$li(
            strong("Décrire les données"),
            " : distributions, corrélations, groupes et données manquantes."
          ),
          tags$li(
            strong("Examiner la structure populationnelle"),
            " qui a servi à produire les données, y compris la fidélité exacte ",
            "de chaque échelle."
          ),
          tags$li(
            strong("Comparer la population et l'échantillon"),
            " afin de distinguer la fluctuation d'échantillonnage des effets ",
            "introduits volontairement."
          ),
          tags$li(
            strong("Exporter"),
            " les données, la matrice de corrélations ou un paquet pédagogique ",
            "(version étudiante ou corrigé enseignant)."
          )
        ),
        tags$div(
          class = "alert alert-info mt-3",
          strong("À retenir : "),
          "la structure populationnelle affichée par l'application est connue ",
          "parce que les données sont simulées. Dans une analyse réelle, cette ",
          "structure doit être estimée à partir des observations."
        ),
        p(
          "L'application est centrée sur la génération, la compréhension de la ",
          "structure simulée et l'exportation des données. Les analyses peuvent ",
          "ensuite être réalisées dans les applications ou logiciels spécialisés ",
          "appropriés."
        )
      )
    )
  ),

  # ============================================================
  # CONFIGURER
  # ============================================================
  nav_panel(
    title = "Configurer",
    icon = icon("sliders"),
    div(
      class = "mb-4",
      h2("Configurer la simulation"),
      p(
        class = "lead mb-0",
        "Choisissez un préréglage ou composez votre propre population avant de générer les données."
      )
    ),

    card(
      card_header(
        div(
          span(icon("sliders"), style = "margin-right: 5px;"),
          "Préréglages et génération"
        )
      ),
      card_body(
        p(
          "Un préréglage remplace tous les réglages ci-dessous (sauf les groupes); ",
          "vous pouvez ensuite les modifier avant de générer les données."
        ),
        div(
          style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px;",
          preset_card("preset_personality", "Personnalité", "5 facteurs - BFI", "user", pal_multivgen[["personality"]]),
          preset_card("preset_cognitive", "Tests cognitifs", "3 facteurs - Aptitudes", "brain", pal_multivgen[["cognitive"]]),
          preset_card("preset_social", "Échelles d'attitudes", "4 facteurs - Asymétrie", "comments", pal_multivgen[["social"]]),
          preset_card("preset_academic", "Performance académique", "2 facteurs - Éducation", "graduation-cap", pal_multivgen[["academic"]]),
          preset_card("preset_bifactor", "Détresse psychologique", "Bifactoriel - général + 3 spécifiques", "sitemap", pal_multivgen[["bifactor"]]),
          preset_card("preset_survey", "Sondage Likert", "7 points - items inversés - MAR", "square-poll-vertical", pal_multivgen[["survey"]])
        ),
        tags$script(HTML("
          $(document).ready(function() {
            $('.preset-card').hover(
              function() { $(this).css('transform', 'translateY(-3px)').css('box-shadow', '0 4px 8px rgba(0,0,0,0.1)'); },
              function() { $(this).css('transform', 'translateY(0)').css('box-shadow', 'none'); }
            );
          });
        ")),
        tags$hr(style = "margin-top: 0.9rem; margin-bottom: 0.9rem;"),
        layout_columns(
          col_widths = c(3, 3, 3, 3),
          textInput(
            "seed",
            "Graine aléatoire (seed) :",
            value = "",
            placeholder = "Vide = tirée au hasard"
          ),
          textInput(
            "sample_seed",
            "Graine de l'échantillon (facultatif) :",
            value = "",
            placeholder = "Vide = suite de la graine"
          ),
          div(
            style = "padding-top: 1.9rem;",
            actionButton(
              "generate",
              "Générer les données",
              icon = icon("play"),
              class = "btn-primary",
              width = "100%"
            )
          ),
          div(
            style = "padding-top: 1.9rem;",
            actionButton(
              "new_sample",
              "Nouvel échantillon, même population",
              icon = icon("shuffle"),
              class = "btn-outline-primary",
              width = "100%"
            )
          )
        ),
        helpText(
          "« Nouvel échantillon, même population » conserve la population du dernier jeu ",
          "généré (charges, corrélations, seuils, item touché par le DIF…) et ne tire ",
          "que de nouvelles personnes; seules les tailles des groupes peuvent changer. ",
          "Les deux graines affichées permettent ensuite de reproduire exactement l'échantillon."
        ),
        uiOutput("generation_status_config")
      )
    ),

    layout_columns(
      col_widths = c(6, 6),

      # ----------------------------------------------------------
      # Structure des facteurs
      # ----------------------------------------------------------
      card(
        card_header("Structure des facteurs"),
        card_body(
          fillable = FALSE,
        layout_columns(
          col_widths = c(6, 6),
          numericInput("nfact", "Nombre de facteurs :",
            value = 3, min = 1, max = 10, step = 1
          ),
          selectInput("vpf_type", "Variables par facteur :",
            choices = c(
              "Fixe" = "fixed",
              "Aléa petit (5-10)" = "S",
              "Aléa moyen (5-15)" = "M",
              "Aléa grand (5-20)" = "L",
              "Aléa personnalisé" = "R"
            ),
            selected = "M"
          )
        ),
        conditionalPanel(
          condition = "input.vpf_type == 'fixed'",
          numericInput("vpf_fixed", "Nombre de variables par facteur :",
            value = 5, min = 2, max = 30, step = 1
          )
        ),
        conditionalPanel(
          condition = "input.vpf_type == 'R'",
          layout_columns(
            col_widths = c(6, 6),
            numericInput("low_vpf", "Minimum de variables :",
              value = 5, min = 2, max = 29, step = 1
            ),
            numericInput("up_vpf", "Maximum de variables :",
              value = 15, min = 3, max = 30, step = 1
            )
          )
        ),
        selectInput(
          "structure",
          "Type de structure :",
          choices = c(
            "Facteurs corrélés" = "correlated",
            "Bifactorielle (facteur général + facteurs spécifiques)" = "bifactor"
          ),
          selected = "correlated"
        ),
        conditionalPanel(
          condition = "input.structure == 'bifactor'",
          selectInput(
            "gl_type",
            "Charges sur le facteur général :",
            choices = c(
              "Fixe" = "fixed",
              "Faibles (0,30-0,45)" = "L",
              "Moyennes (0,45-0,60)" = "M",
              "Élevées (0,60-0,70)" = "H"
            ),
            selected = "M"
          ),
          conditionalPanel(
            condition = "input.gl_type == 'fixed'",
            sliderInput("gl_fixed", "Valeur de charge générale :",
              min = 0.10, max = 0.80, value = 0.50, step = 0.05
            )
          ),
          helpText(
            "Chaque item charge sur le facteur général FG et sur le facteur ",
            "spécifique de son échelle. Les facteurs sont orthogonaux; le nombre ",
            "de facteurs ci-dessus désigne les facteurs spécifiques."
          )
        )
        )
      ),

      # ----------------------------------------------------------
      # Charges et corrélations
      # ----------------------------------------------------------
      card(
        card_header("Charges et corrélations"),
        card_body(
          fillable = FALSE,
        layout_columns(
          col_widths = c(6, 6),
          conditionalPanel(
            condition = "input.structure != 'bifactor'",
            selectInput("fc_type", "Corrélation entre facteurs :",
              choices = c("Fixe" = "fixed", "Aléatoire (0,0-0,5)" = "R"),
              selected = "R"
            )
          ),
          selectInput("pl_type", "Charges factorielles principales :",
            choices = c(
              "Fixe" = "fixed",
              "Faibles (0,35-0,50)" = "L",
              "Moyennes (0,50-0,65)" = "M",
              "Élevées (0,65-0,80)" = "H",
              "Aléatoires (0,35-0,80)" = "R"
            ),
            selected = "R"
          )
        ),
        conditionalPanel(
          condition = "input.fc_type == 'fixed' && input.structure != 'bifactor'",
          sliderInput("fc_fixed", "Valeur de corrélation :",
            min = 0, max = 0.75, value = 0.3, step = 0.05
          )
        ),
        conditionalPanel(
          condition = "input.pl_type == 'fixed'",
          sliderInput("pl_fixed", "Valeur de charge principale :",
            min = 0.10, max = 0.95, value = 0.6, step = 0.05
          )
        ),
        layout_columns(
          col_widths = c(6, 6),
          selectInput("cl_type", "Charges factorielles secondaires :",
            choices = c(
              "Fixe" = "fixed",
              "Faibles (−0,10 à 0,10)" = "L",
              "Élevées (0,10 à 0,20 en valeur absolue)" = "H",
              "Aucune (0)" = "None",
              "Aléatoires (−0,20 à 0,20)" = "R"
            ),
            selected = "R"
          ),
          conditionalPanel(
            condition = "input.cl_type != 'None'",
            selectInput(
              "cross_loading_prop",
              "Proportion de charges secondaires :",
              choices = c(
                "25 %" = "0.25",
                "50 %" = "0.5",
                "75 %" = "0.75",
                "100 %" = "1"
              ),
              selected = "0.25"
            )
          )
        ),
        conditionalPanel(
          condition = "input.cl_type == 'fixed'",
          sliderInput("cl_fixed", "Valeur de charge secondaire :",
            min = -0.30, max = 0.50, value = 0.1, step = 0.05
          )
        ),
        conditionalPanel(
          condition = "input.cl_type != 'None'",
          helpText(
            "La proportion indique la part des charges secondaires potentielles ",
            "qui sont non nulles."
          )
        ),
        selectInput(
          "reverse_prop",
          "Items à formulation inversée (par facteur) :",
          choices = c(
            "Aucun" = "0",
            "Environ 20 %" = "0.2",
            "Environ un tiers" = "0.3333",
            "Environ la moitié" = "0.5"
          ),
          selected = "0"
        ),
        conditionalPanel(
          condition = "input.reverse_prop != '0'",
          helpText(
            "Un item inversé reçoit des charges de signe opposé : il corrèle ",
            "négativement avec les autres items de son échelle et doit être recodé ",
            "avant le calcul d'un score."
          )
        )
        )
      ),

      # ----------------------------------------------------------
      # Groupes
      # ----------------------------------------------------------
      card(
        card_header("Groupes"),
        card_body(
          fillable = FALSE,
        sliderInput(
          "n_groups",
          "Nombre de groupes :",
          min = 1,
          max = 5,
          value = 1,
          step = 1
        ),
        uiOutput("group_sizes_ui"),
        uiOutput("group_total_ui"),
        conditionalPanel(
          condition = "input.n_groups > 1",
          selectInput(
            "group_mean_diff",
            "Différences de moyennes latentes :",
            choices = c(
              "Aucune" = "none",
              "Faibles (0,25 ET)" = "low",
              "Modérées (0,50 ET)" = "moderate",
              "Fortes (0,80 ET)" = "high"
            ),
            selected = "none"
          ),
          helpText(
            "Chaque groupe après G1 est déplacé sur un facteur différent ",
            "(G2 sur le premier facteur, G3 sur le deuxième, etc.)."
          ),
          selectInput(
            "group_cov_diff",
            "Covariances entre groupes :",
            choices = c(
              "Identiques" = "equal",
              "Variations modérées" = "moderate",
              "Variations fortes" = "high"
            ),
            selected = "equal"
          ),
          helpText(
            "Les variations modifient les corrélations entre facteurs et la ",
            "variance d'un facteur par groupe."
          ),
          uiOutput("measurement_invariance_ui")
        )
        )
      ),

      # ----------------------------------------------------------
      # Distribution et format des réponses
      # ----------------------------------------------------------
      card(
        card_header("Distribution et format des réponses"),
        card_body(
          fillable = FALSE,
        layout_columns(
          col_widths = c(6, 6),
          selectInput(
            "distri",
            "Distribution des erreurs :",
            choices = c(
              "Normale" = "normal",
              "Asymétrique" = "skewed"
            ),
            selected = "normal"
          ),
          selectInput(
            "response_format",
            "Format des réponses :",
            choices = c(
              "Continues" = "continuous",
              "Likert ordinales" = "likert"
            ),
            selected = "continuous"
          )
        ),
        conditionalPanel(
          condition = "input.distri == 'skewed'",
          selectInput(
            "skew_strength",
            "Degré d'asymétrie :",
            choices = c(
              "Faible" = "0.25",
              "Modérée" = "0.5",
              "Forte" = "0.75"
            ),
            selected = "0.5"
          ),
          helpText(
            "Un niveau plus élevé augmente l'asymétrie et la proportion de ",
            "variables touchées. Certaines variables peuvent demeurer ",
            "approximativement normales."
          )
        ),
        conditionalPanel(
          condition = "input.response_format == 'likert'",
          layout_columns(
            col_widths = c(6, 6),
            selectInput(
              "likert_categories",
              "Nombre de catégories :",
              choices = c(
                "2 (dichotomique)" = "2",
                "3" = "3",
                "4" = "4",
                "5" = "5",
                "6" = "6",
                "7" = "7"
              ),
              selected = "5"
            ),
            selectInput(
              "likert_pattern_mode",
              "Patron des seuils :",
              choices = c(
                "Commun à tous les items" = "common",
                "Varié selon l'item" = "mixed"
              ),
              selected = "common"
            )
          ),
          conditionalPanel(
            condition = "input.likert_pattern_mode == 'common'",
            selectInput(
              "likert_profile",
              "Profil des seuils de réponse :",
              choices = c(
                "Équilibré (catégories également fréquentes)" = "balanced",
                "Centré symétrique (beaucoup de réponses au centre)" = "centered",
                "Surtout catégories basses" = "low",
                "Surtout catégories élevées" = "high"
              ),
              selected = "balanced"
            )
          ),
          conditionalPanel(
            condition = "input.likert_pattern_mode == 'mixed'",
            helpText(
              "Tirage reproductible par item : 40 % centré symétrique, 25 % ",
              "équilibré, 17,5 % surtout bas et 17,5 % surtout haut."
            )
          ),
          selectInput(
            "response_style",
            "Style de réponse chez certains répondants :",
            choices = c(
              "Aucun" = "none",
              "Tendance au milieu" = "midpoint",
              "Tendance aux extrêmes" = "extreme",
              "Acquiescement (réponses plus élevées)" = "acquiescence"
            ),
            selected = "none"
          ),
          conditionalPanel(
            condition = "input.response_style != 'none'",
            sliderInput(
              "response_style_prop",
              "Proportion de répondants concernés :",
              min = 5,
              max = 30,
              value = 15,
              step = 5,
              post = " %"
            )
          ),
          helpText(
            "Les catégories sont obtenues par seuils fixes appliqués aux réponses ",
            "continues sous-jacentes. Chaque item conserve ses seuils dans tous les ",
            "groupes; les écarts entre groupes sont donc conservés."
          )
        )
        )
      ),

      # ----------------------------------------------------------
      # Données manquantes
      # ----------------------------------------------------------
      card(
        card_header("Données manquantes"),
        card_body(
          fillable = FALSE,
        selectInput(
          "missing_mechanism",
          "Mécanisme :",
          choices = c(
            "Aucune donnée manquante" = "none",
            "MCAR — complètement au hasard" = "mcar",
            "MAR — selon une variable observée" = "mar",
            "MNAR — selon la valeur manquante elle-même" = "mnar"
          ),
          selected = "none"
        ),
        conditionalPanel(
          condition = "input.missing_mechanism != 'none'",
          sliderInput(
            "missing_rate",
            "Proportion de cellules manquantes :",
            min = 5,
            max = 40,
            value = 10,
            step = 5,
            post = " %"
          )
        ),
        conditionalPanel(
          condition = "input.missing_mechanism == 'mcar'",
          helpText(
            "Chaque cellule a la même probabilité d'être manquante. Les moyennes ",
            "calculées sur les cas disponibles restent sans biais."
          )
        ),
        conditionalPanel(
          condition = "input.missing_mechanism == 'mar'",
          helpText(
            "Une variable tirée au hasard reste complète; plus sa valeur est élevée, ",
            "plus les autres réponses de la personne risquent d'être manquantes. ",
            "L'absence s'explique donc par une information observée."
          )
        ),
        conditionalPanel(
          condition = "input.missing_mechanism == 'mnar'",
          helpText(
            "Plus la réponse sous-jacente est élevée, plus elle risque d'être ",
            "manquante. Les valeurs disponibles sous-estiment alors les moyennes."
          )
        )
        )
      ),

      # ----------------------------------------------------------
      # Ordre des opérations
      # ----------------------------------------------------------
      card(
        card_header("Ordre de génération"),
        card_body(
          fillable = FALSE,
        p(
          class = "mb-2",
          "Les réglages s'appliquent toujours dans cet ordre; chaque étape agit ",
          "sur le résultat de la précédente."
        ),
        tags$ol(
          class = "etape-liste",
          tags$li(strong("Facteurs latents"), " : moyennes et covariances de chaque groupe."),
          tags$li(strong("Réponses continues"), " : ΛF + ε, avec erreurs normales ou asymétriques."),
          tags$li(strong("Non-invariance d'intercept"), " (données continues, G2)."),
          tags$li(strong("Styles de réponse"), " (Likert), appliqués à des répondants complets."),
          tags$li(strong("Codage Likert"), " par seuils, avec DIF de seuils éventuel (G2)."),
          tags$li(strong("Données manquantes"), " selon le mécanisme choisi.")
        )
        )
      )
    )
  ),

  # ============================================================
  # DONNÉES
  # ============================================================
  nav_panel(
    title = "Données",
    icon = icon("table"),
    uiOutput("generation_status_data"),
    navset_card_tab(
      nav_panel(
        title = "Données simulées",
        card(
          full_screen = TRUE,
          card_header(
            "Aperçu des données générées"
          ),
          card_body(
            div(
              style = "max-width: 520px; margin-bottom: 14px;",
              radioButtons(
                "download_format",
                label = "Format de téléchargement :",
                choices = c(
                  "CSV" = "csv",
                  "Excel" = "xlsx",
                  "Stata" = "dta",
                  "SPSS" = "sav",
                  "jamovi (.omv)" = "omv"
                ),
                selected = "csv",
                inline = TRUE
              ),
              downloadButton(
                "download_data",
                "Télécharger les données",
                icon = icon("download"),
                class = "btn-primary",
                style = "width: 60%;"
              )
            ),
            tags$div(
              class = "border rounded p-3 mb-3",
              h5("Diffusion pédagogique"),
              p(
                class = "mb-2",
                "Le paquet étudiant contient les données (CSV), un codebook et un ",
                "guide. Le corrigé enseignant ajoute la structure véritable, les ",
                "scores factoriels vrais, la fidélité populationnelle, les données ",
                "complètes et une syntaxe lavaan du modèle."
              ),
              layout_columns(
                col_widths = c(6, 6),
                downloadButton(
                  "download_student_package",
                  "Paquet étudiant (ZIP)",
                  icon = icon("box-archive"),
                  class = "btn-outline-primary",
                  width = "100%"
                ),
                downloadButton(
                  "download_teacher_package",
                  "Corrigé enseignant (ZIP)",
                  icon = icon("user-graduate"),
                  class = "btn-outline-secondary",
                  width = "100%"
                )
              )
            ),
            uiOutput("data_missing_notice"),
            DTOutput("simulated_data")
          ),
          card_footer(
            "L'aperçu affiche au maximum les 100 premières observations. ",
            "Le fichier téléchargé contient le jeu de données complet; les valeurs ",
            "manquantes y sont laissées vides (CSV, Excel) ou codées manquantes ",
            "(Stata, SPSS)."
          )
        )
      ),
      nav_panel(
        title = "Description globale",
        card(
          full_screen = TRUE,
          card_header("Statistiques descriptives"),
          card_body(
            p(
              "Une ligne par variable. L'asymétrie et l'aplatissement (en excès) ",
              "valent 0 pour une distribution normale; ils permettent de repérer ",
              "les variables touchées par l'option « Asymétrique »."
            ),
            DTOutput("global_descriptives_table")
          )
        ),
        card(
          full_screen = TRUE,
          card_header(
            "Matrice de corrélations observées"
          ),
          card_body(
            p(
              "Cette matrice contient les corrélations calculées à partir du ",
              "jeu de données simulé. La représentation graphique permet de ",
              "repérer visuellement les regroupements de variables, tandis que ",
              "le tableau fournit les valeurs numériques exactes."
            ),
            uiOutput("correlation_interpretation"),
            radioButtons(
              "corr_view",
              label = "Affichage :",
              choices = c(
                "Structure visuelle" = "corrplot",
                "Valeurs numériques" = "table"
              ),
              selected = "corrplot",
              inline = TRUE
            ),
            conditionalPanel(
              condition = "input.corr_view == 'corrplot'",
              div(
                style = "width: 100%; display: flex; justify-content: center; align-items: flex-start;",
                plotOutput(
                  "observed_corr_plot",
                  width = "850px",
                  height = "850px"
                )
              )
            ),
            conditionalPanel(
              condition = "input.corr_view == 'table'",
              DTOutput("observed_corr_table")
            ),
            hr(),
            div(
              style = "max-width: 520px; margin-top: 10px; margin-bottom: 8px;",
              radioButtons(
                "corr_download_format",
                label = "Format de téléchargement :",
                choices = c(
                  "CSV" = "csv",
                  "Excel" = "xlsx",
                  "Stata" = "stata",
                  "SPSS" = "spss"
                ),
                selected = "csv",
                inline = TRUE
              ),
              downloadButton(
                "download_corr_matrix",
                "Télécharger la matrice",
                icon = icon("download"),
                class = "btn-primary",
                style = "width: 100%;"
              )
            )
          ),
          card_footer(
            "La matrice est calculée sur toutes les variables générées; la variable ",
            "d'identification du groupe n'entre pas dans son calcul. En présence de ",
            "données manquantes, chaque corrélation utilise les paires disponibles."
          )
        )
      ),
      nav_panel(
        title = "Description par groupe",
        uiOutput("group_description_ui")
      ),
      nav_panel(
        title = "Distributions",
        layout_columns(
          col_widths = c(9, 3),
          card(
            full_screen = TRUE,
            card_header("Distribution des variables"),
            card_body(
              plotOutput(
                "distribution_plot",
                height = "600px"
              )
            )
          ),
          card(
            card_header("Options"),
            card_body(
              uiOutput("distribution_plot_type_ui"),
              uiOutput("distrib_var_selector")
            )
          )
        )
      ),
      nav_panel(
        title = "Données manquantes",
        uiOutput("missing_ui")
      )
    )
  ),

  # ============================================================
  # STRUCTURE POPULATIONNELLE
  # ============================================================
  nav_panel(
    title = "Structure populationnelle",
    icon = icon("project-diagram"),
    navset_card_tab(
      nav_panel(
        title = "Structure des variables",
        card(
          full_screen = TRUE,
          card_header("Structure factorielle populationnelle"),
          card_body(
            p(
              "Le tableau présente les charges factorielles utilisées pour générer ",
              "chaque variable et son facteur principal. Les communalités et les ",
              "unicités sont calculées pour le groupe sélectionné."
            ),
            uiOutput("population_structure_interpretation"),
            uiOutput("measurement_invariance_notice"),
            uiOutput("response_style_notice"),
            uiOutput("population_structure_group_selector"),
            DTOutput("population_structure_table")
          )
        )
      ),
      nav_panel(
        title = "Structure des facteurs",
        card(
          full_screen = TRUE,
          card_header("Moyennes factorielles populationnelles"),
          card_body(
            p(
              "Les lignes représentent les groupes et les colonnes les facteurs. ",
              "Ces valeurs sont les moyennes latentes utilisées pour générer les ",
              "observations. Le groupe G1 constitue le groupe de référence."
            ),
            DTOutput("population_factor_means_table")
          )
        ),
        card(
          full_screen = TRUE,
          card_header("Relations entre facteurs"),
          card_body(
            p(
              "La matrice présente la structure factorielle populationnelle du groupe ",
              "sélectionné. Les covariances reflètent à la fois les relations entre ",
              "facteurs et leurs variances."
            ),
            layout_columns(
              col_widths = c(4, 8),
              uiOutput("population_group_selector"),
              radioButtons(
                "population_factor_matrix_type",
                "Matrice :",
                choices = c(
                  "Corrélations" = "cor",
                  "Covariances" = "cov"
                ),
                selected = "cor",
                inline = TRUE
              )
            ),
            DTOutput("population_factor_matrix_table")
          )
        )
      ),
      nav_panel(
        title = "Fidélité populationnelle",
        card(
          full_screen = TRUE,
          card_header("Fidélité exacte des échelles"),
          card_body(
            p(
              "Chaque échelle est la somme des items dont c'est le facteur principal ",
              "(items inversés recodés). Comme la population est connue, ces valeurs ",
              "ne sont pas des estimations : ce sont les fidélités vraies, dans le ",
              "groupe de référence G1."
            ),
            uiOutput("reliability_summary"),
            DTOutput("reliability_table"),
            uiOutput("reliability_explanation")
          )
        )
      )
    )
  ),

  # ============================================================
  # VÉRIFICATION
  # ============================================================
  nav_panel(
    title = "Vérification",
    icon = icon("magnifying-glass-chart"),
    card(
      full_screen = TRUE,
      card_header("Population et échantillon"),
      card_body(
        uiOutput("verification_source_ui"),
        uiOutput("verification_explanation"),
        plotOutput(
          "population_sample_plot",
          height = "620px"
        ),
        uiOutput("population_sample_summary")
      )
    )
  )
)


server <- function(input, output, session) {
  # Réactive pour stocker les données simulées
  sim_data <- reactiveVal(NULL)

  # Les tailles déjà saisies sont conservées lorsqu'on ajoute ou retire
  # un groupe. La valeur de l'interface reste la source de vérité.
  group_size_memory <- reactiveValues(
    values = c("1" = 500)
  )

  # ============================================================
  # Tailles des groupes
  # ============================================================

  observeEvent(input$n_groups, {
    req(input$n_groups)

    n_groups <- as.integer(input$n_groups)

    default_n <- if (n_groups == 1) 500 else 200

    previous_values <- isolate(group_size_memory$values)
    new_values <- rep(default_n, n_groups)
    names(new_values) <- as.character(seq_len(n_groups))

    retained <- intersect(names(previous_values), names(new_values))
    new_values[retained] <- previous_values[retained]

    group_size_memory$values <- new_values
  }, ignoreInit = FALSE)

  observe({
    req(input$n_groups)

    n_groups <- as.integer(input$n_groups)
    current_values <- vapply(
      seq_len(n_groups),
      function(g) {
        value <- input[[paste0("group_n_", g)]]

        if (is.null(value) || is.na(value)) {
          return(NA_real_)
        }

        as.numeric(value)
      },
      numeric(1)
    )

    if (all(!is.na(current_values))) {
      names(current_values) <- as.character(seq_len(n_groups))
      group_size_memory$values <- current_values
    }
  })

  output$group_sizes_ui <- renderUI({
    req(input$n_groups)

    n_groups <- as.integer(input$n_groups)
    default_n <- if (n_groups == 1) 500 else 200
    saved_values <- isolate(group_size_memory$values)

    tagList(
      lapply(seq_len(n_groups), function(g) {
        value <- saved_values[as.character(g)]
        if (length(value) == 0 || is.na(value)) {
          value <- default_n
        }

        numericInput(
          inputId = paste0("group_n_", g),
          label = paste0("Taille du groupe G", g, " :"),
          value = unname(value),
          min = 10,
          max = 5000,
          step = 10
        )
      })
    )
  })


  output$group_total_ui <- renderUI({
    req(input$n_groups)

    n_groups <- as.integer(input$n_groups)

    sizes <- vapply(
      seq_len(n_groups),
      function(g) {
        value <- input[[paste0("group_n_", g)]]

        if (is.null(value) || is.na(value)) {
          return(NA_real_)
        }

        as.numeric(value)
      },
      numeric(1)
    )

    if (anyNA(sizes)) {
      return(NULL)
    }

    div(
      class = "alert alert-light py-2 mb-3",
      strong("Taille totale de l'échantillon : "),
      format(sum(sizes), big.mark = " ")
    )
  })

  output$measurement_invariance_ui <- renderUI({
    req(input$n_groups, input$response_format)

    if (as.integer(input$n_groups) <= 1) {
      return(NULL)
    }

    if (identical(input$response_format, "likert")) {
      return(
        tagList(
          selectInput(
            "measurement_invariance",
            "Invariance de mesure :",
            choices = c(
              "Aucune violation : seuils identiques" = "invariant",
              "DIF de seuils pour un item (G2)" = "threshold_dif"
            ),
            selected = "invariant"
          ),
          helpText(
            "Le scénario DIF décale de 0,60 tous les seuils d'un item dans G2, sans ",
            "modifier sa structure latente. Il illustre la non-invariance ",
            "scalaire des réponses ordinales."
          )
        )
      )
    }

    tagList(
      selectInput(
        "measurement_invariance",
        "Invariance de mesure :",
        choices = c(
          "Aucune violation : intercepts identiques" = "invariant",
          "DIF d'intercept pour un item (G2)" = "intercept_dif"
        ),
        selected = "invariant"
      ),
      helpText(
        "Le scénario DIF ajoute un intercept de 0,60 à un item dans G2, sans ",
        "modifier son facteur latent ni ses charges. Il illustre la non-invariance ",
        "scalaire des données continues."
      )
    )
  })


  # Observateurs pour les boutons Sélectionner/Désélectionner tout
  observeEvent(input$select_all_distrib_vars, {
    req(sim_data())
    var_names <- colnames(sim_data()$response_numeric)
    updateSelectizeInput(session, "selected_distrib_vars", selected = var_names)
  })

  observeEvent(input$deselect_all_distrib_vars, {
    updateSelectizeInput(session, "selected_distrib_vars", selected = character(0))
  })


  # Garder un minimum strictement inférieur au maximum (aléa personnalisé)
  observe({
    req(identical(input$vpf_type, "R"))
    low <- input$low_vpf
    up <- input$up_vpf
    if (is.numeric(low) && is.numeric(up) && !is.na(low) && !is.na(up) && low > up) {
      updateNumericInput(session, "low_vpf", value = up)
    }
  })

  # ============================================================
  # Génération des données
  # ============================================================

  read_num <- function(x, default = NA_real_) {
    v <- suppressWarnings(as.numeric(x))
    if (length(v) != 1 || is.na(v)) default else v
  }

  label_of <- function(map, value) {
    out <- map[as.character(value)]
    if (length(out) == 0 || is.na(out)) as.character(value) else unname(out)
  }

  describe_settings <- function(p) {
    level_pl <- c(L = "faibles (0,35-0,50)", M = "moyennes (0,50-0,65)",
      H = "élevées (0,65-0,80)", R = "aléatoires (0,35-0,80)")
    level_gl <- c(L = "faibles (0,30-0,45)", M = "moyennes (0,45-0,60)",
      H = "élevées (0,60-0,70)")
    level_cl <- c(None = "aucune", L = "faibles (−0,10 à 0,10)",
      H = "élevées (0,10 à 0,20 en valeur absolue)", R = "aléatoires (−0,20 à 0,20)")
    vpf_map <- c(S = "aléatoire, 5 à 10", M = "aléatoire, 5 à 15", L = "aléatoire, 5 à 20")
    mean_map <- c(none = "aucune", low = "faibles (0,25)", moderate = "modérées (0,50)",
      high = "fortes (0,80)")
    cov_map <- c(equal = "identiques", moderate = "variations modérées",
      high = "variations fortes")
    inv_map <- c(invariant = "respectée", threshold_dif = "DIF de seuils (G2)",
      intercept_dif = "DIF d'intercept (G2)")

    num_or_level <- function(x, map) {
      if (is.numeric(x)) paste0("fixes (", fmt_n(x, 2), ")") else label_of(map, x)
    }

    c(
      "Graine" = as.character(p$seed),
      "Facteurs" = if (identical(p$structure, "bifactor")) {
        paste0(p$nfact, " spécifiques + 1 général (bifactoriel)")
      } else {
        paste0(p$nfact, " (facteurs corrélés)")
      },
      "Variables par facteur" = if (is.numeric(p$vpf)) {
        paste0(p$vpf, " (fixe)")
      } else if (identical(p$vpf, "R")) {
        paste0("aléatoire, ", p$low_vpf, " à ", p$up_vpf)
      } else {
        label_of(vpf_map, p$vpf)
      },
      "Corrélation entre facteurs" = if (identical(p$structure, "bifactor") || p$nfact == 1) {
        "sans objet (facteurs orthogonaux ou facteur unique)"
      } else if (identical(p$fc, "R")) {
        "aléatoire (0,0-0,5)"
      } else {
        fmt_n(as.numeric(p$fc), 2)
      },
      "Charges principales" = num_or_level(p$pl, level_pl),
      "Charges générales" = if (identical(p$structure, "bifactor")) num_or_level(p$gl, level_gl) else "sans objet",
      "Charges secondaires" = if (is.numeric(p$cl)) {
        paste0("fixes (", fmt_n(p$cl, 2), "), proportion ", fmt_pct(p$cross_loading_prop, 0))
      } else if (identical(p$cl, "None")) {
        "aucune"
      } else {
        paste0(label_of(level_cl, p$cl), ", proportion ", fmt_pct(p$cross_loading_prop, 0))
      },
      "Items inversés" = if (p$reverse_prop > 0) paste0("environ ", fmt_pct(p$reverse_prop, 0), " par facteur") else "aucun",
      "Groupes" = paste0(length(p$group_sizes), " (n = ", paste(p$group_sizes, collapse = ", "), ")"),
      "Différences de moyennes latentes" = label_of(mean_map, p$group_mean_diff),
      "Covariances factorielles entre groupes" = label_of(cov_map, p$group_cov_diff),
      "Invariance de mesure" = label_of(inv_map, p$measurement_invariance),
      "Distribution des erreurs" = if (identical(p$distribution, "skewed")) {
        paste0("asymétrique (niveau ", fmt_n(as.numeric(p$skew_strength), 2), ")")
      } else {
        "normale"
      },
      "Format des réponses" = if (identical(p$response_format, "likert")) {
        paste0(
          "Likert, ", p$likert_categories, " catégories, profil ",
          if (identical(p$likert_pattern_mode, "mixed")) "varié selon l'item" else tolower(likert_profile_labels[[p$likert_profile]])
        )
      } else {
        "continu"
      },
      "Style de réponse" = if (identical(p$response_style, "none")) {
        "aucun"
      } else {
        paste0(tolower(response_style_labels[[p$response_style]]), " (", fmt_pct(p$response_style_prop, 0), " des répondants)")
      },
      "Données manquantes" = if (identical(p$missingness_mechanism, "none")) {
        "aucune"
      } else {
        paste0(missingness_labels[[p$missingness_mechanism]], ", ", fmt_pct(p$missingness_rate, 0), " des cellules")
      }
    )
  }

  read_group_sizes <- function() {
    n_groups <- as.integer(input$n_groups)
    vapply(
      seq_len(n_groups),
      function(g) {
        value <- input[[paste0("group_n_", g)]]
        # Si l'input dynamique n'est pas encore disponible,
        # reprendre la valeur par défaut affichée dans l'interface.
        if (is.null(value) || is.na(value)) {
          value <- if (n_groups == 1) 500 else 200
        }
        as.integer(value)
      },
      integer(1)
    )
  }

  check_group_sizes <- function(group_sizes) {
    if (any(group_sizes < 10)) {
      stop("Chaque groupe doit contenir au moins 10 observations.")
    }
    if (sum(group_sizes) > 50000) {
      stop("La taille totale de l'échantillon est limitée à 50 000 observations.")
    }
  }

  read_seed <- function(text, label) {
    text <- trimws(text %||% "")
    if (!nzchar(text)) return(NULL)
    value <- suppressWarnings(as.integer(text))
    if (is.na(value) || value < 0) {
      stop(paste0("La ", label, " doit être un entier positif ou nul."))
    }
    value
  }

  # Réglages lus dans l'onglet Configurer
  params_from_inputs <- function() {
    nfact <- read_num(input$nfact)
    if (is.na(nfact) || nfact != round(nfact) || nfact < 1 || nfact > 10) {
      stop("Le nombre de facteurs doit être un entier compris entre 1 et 10.")
    }
    nfact <- as.integer(nfact)

    structure <- input$structure %||% "correlated"
    if (identical(structure, "bifactor") && nfact < 2) {
      stop("Une structure bifactorielle exige au moins deux facteurs spécifiques.")
    }

    vpf_param <- if (identical(input$vpf_type, "fixed")) {
      v <- read_num(input$vpf_fixed)
      if (is.na(v) || v != round(v) || v < 2 || v > 30) {
        stop("Le nombre de variables par facteur doit être un entier compris entre 2 et 30.")
      }
      as.integer(v)
    } else {
      input$vpf_type
    }

    low_vpf <- read_num(input$low_vpf, 5)
    up_vpf <- read_num(input$up_vpf, 15)
    if (identical(input$vpf_type, "R") &&
      (low_vpf < 2 || up_vpf > 30 || low_vpf > up_vpf)) {
      stop("Les bornes du nombre de variables doivent respecter 2 ≤ minimum ≤ maximum ≤ 30.")
    }

    fc_param <- if (identical(input$fc_type, "fixed")) input$fc_fixed else "R"
    pl_param <- if (identical(input$pl_type, "fixed")) input$pl_fixed else input$pl_type
    cl_param <- if (identical(input$cl_type, "fixed")) input$cl_fixed else input$cl_type
    gl_param <- if (identical(input$gl_type, "fixed")) input$gl_fixed else (input$gl_type %||% "M")

    group_sizes <- read_group_sizes()
    check_group_sizes(group_sizes)
    n_groups <- length(group_sizes)

    is_likert <- identical(input$response_format, "likert")

    params <- list(
      nfact = nfact,
      vpf = vpf_param,
      N = sum(group_sizes),
      fc = fc_param,
      pl = pl_param,
      cl = cl_param,
      low_vpf = low_vpf,
      up_vpf = up_vpf,
      distribution = input$distri,
      skew_strength = if (identical(input$distri, "skewed")) as.numeric(input$skew_strength) else 0.50,
      cross_loading_prop = if (identical(input$cl_type, "None")) 0 else as.numeric(input$cross_loading_prop),
      group_sizes = group_sizes,
      group_mean_diff = if (n_groups == 1) "none" else input$group_mean_diff,
      group_cov_diff = if (n_groups == 1) "equal" else input$group_cov_diff,
      response_format = input$response_format,
      likert_profile = if (is_likert) input$likert_profile else "balanced",
      likert_pattern_mode = if (is_likert) input$likert_pattern_mode else "common",
      likert_categories = if (is_likert) as.integer(input$likert_categories) else 5L,
      measurement_invariance = if (n_groups > 1 && !is.null(input$measurement_invariance)) {
        input$measurement_invariance
      } else {
        "invariant"
      },
      response_style = if (is_likert) input$response_style %||% "none" else "none",
      response_style_prop = if (is_likert) read_num(input$response_style_prop, 15) / 100 else 0,
      missingness_mechanism = input$missing_mechanism %||% "none",
      missingness_rate = read_num(input$missing_rate, 10) / 100,
      structure = structure,
      gl = gl_param,
      reverse_prop = read_num(input$reverse_prop, 0)
    )
    params
  }

  # mode = "full" : nouvelle génération à partir des réglages affichés;
  # mode = "sample" : même population que le dernier jeu, nouvelles personnes.
  run_generation <- function(mode = "full") {
    withProgress(message = "Génération des données...", value = 0.3, {
      tryCatch(
        {
          if (identical(mode, "sample")) {
            previous <- sim_data()
            if (is.null(previous)) stop("Générez d'abord un jeu de données.")
            params <- previous$params
            sizes_now <- read_group_sizes()
            if (length(sizes_now) == length(params$group_sizes)) {
              check_group_sizes(sizes_now)
              params$group_sizes <- sizes_now
              params$N <- sum(sizes_now)
            }
            seed_value <- previous$seed
            seed_drawn <- FALSE
            sample_seed <- sample.int(99999L, 1L)
            updateTextInput(session, "seed", value = as.character(seed_value))
            updateTextInput(session, "sample_seed", value = as.character(sample_seed))
          } else {
            params <- params_from_inputs()
            seed_value <- read_seed(input$seed, "graine")
            seed_drawn <- is.null(seed_value)
            if (seed_drawn) seed_value <- sample.int(99999L, 1L)
            sample_seed <- read_seed(input$sample_seed, "graine de l'échantillon")
          }

          set.seed(seed_value)
          data_obj <- do.call(generate_factor_data, c(params, list(sample_seed = sample_seed)))

          # --------------------------------------------------------
          # Jeu de données multigroupe
          # --------------------------------------------------------

          data_obj$response_numeric <- data_obj$response

          data_obj$response <- data.frame(
            Groupe = factor(
              data_obj$group_membership,
              levels = paste0(
                "G",
                seq_along(data_obj$group_sizes)
              )
            ),
            data_obj$response_numeric,
            check.names = FALSE
          )

          data_obj$n_groups <- length(
            data_obj$group_sizes
          )

          data_obj$seed <- seed_value
          data_obj$seed_drawn <- seed_drawn
          data_obj$sample_seed <- sample_seed
          data_obj$params <- params
          data_obj$settings <- describe_settings(c(params, list(seed = seed_value)))
          if (!is.null(sample_seed)) {
            data_obj$settings <- append(
              data_obj$settings,
              c("Graine de l'échantillon" = as.character(sample_seed)),
              after = 1
            )
          }

          sim_data(data_obj)

          showNotification(
            "Données générées avec succès!",
            type = "message"
          )
        },
        error = function(e) {
          showNotification(
            paste(
              "Erreur lors de la génération des données :",
              conditionMessage(e)
            ),
            type = "error",
            duration = 10
          )
        }
      )
    })
  }

  # Une première génération a lieu à l'ouverture, puis à chaque clic
  observeEvent(input$generate, run_generation("full"), ignoreNULL = FALSE)
  observeEvent(input$new_sample, run_generation("sample"), ignoreInit = TRUE)

  # ------------------------------------------------------------
  # Bandeau de la dernière génération
  # ------------------------------------------------------------
  generation_status <- function() {
    d <- sim_data()
    if (is.null(d)) {
      return(NULL)
    }

    n_specific <- max(d$factor_assignments)

    div(
      class = "statut-generation",
      icon("circle-check", style = "color: #198754;"),
      strong(" Données générées : "),
      paste0(
        "N = ", format(nrow(d$response), big.mark = " "),
        " · ", ncol(d$response_numeric), " variables · ",
        if (identical(d$structure, "bifactor")) {
          paste0("1 facteur général + ", n_specific, " spécifiques")
        } else {
          paste0(n_specific, " facteur", if (n_specific > 1) "s" else "")
        },
        " · ", d$n_groups, " groupe", if (d$n_groups > 1) "s" else "",
        " · ",
        if (identical(d$response_format, "likert")) {
          paste0("Likert ", d$likert_categories, " catégories")
        } else {
          "réponses continues"
        },
        if (!identical(d$missingness_mechanism, "none")) {
          paste0(" · ", fmt_pct(d$missingness_realized_rate, 1), " de cellules manquantes")
        } else {
          ""
        }
      ),
      br(),
      if (is.null(d$sample_seed)) {
        tagList(
          "Graine : ",
          span(class = "graine", d$seed),
          if (isTRUE(d$seed_drawn)) {
            " (tirée au hasard; inscrivez-la dans le champ « Graine » pour reproduire exactement ces données)"
          } else {
            " (fixée)"
          }
        )
      } else {
        tagList(
          "Graine de la population : ",
          span(class = "graine", d$seed),
          " · graine de l'échantillon : ",
          span(class = "graine", d$sample_seed),
          " (ces deux valeurs reproduisent exactement ces données)"
        )
      }
    )
  }

  output$generation_status_config <- renderUI(generation_status())
  output$generation_status_data <- renderUI({
    status <- generation_status()
    if (is.null(status)) return(NULL)
    div(class = "mb-3", status)
  })

  # ============================================================
  # Préréglages
  # ============================================================

  numeric_inputs <- c("nfact", "vpf_fixed", "low_vpf", "up_vpf")
  slider_inputs <- c("gl_fixed", "fc_fixed", "pl_fixed", "cl_fixed",
    "response_style_prop", "missing_rate")

  apply_settings <- function(values) {
    settings <- default_settings
    settings[names(values)] <- values

    for (id in names(settings)) {
      value <- settings[[id]]
      if (id %in% numeric_inputs) {
        updateNumericInput(session, id, value = value)
      } else if (id %in% slider_inputs) {
        updateSliderInput(session, id, value = value)
      } else {
        updateSelectInput(session, id, selected = value)
      }
    }
  }

  lapply(names(presets), function(id) {
    observeEvent(input[[id]], {
      preset <- presets[[id]]
      apply_settings(preset$values)

      showNotification(
        HTML(paste0(
          "<b>Préréglage « ", preset$title, " » appliqué</b><br>",
          preset$text,
          "<br>Cliquez sur « Générer les données »."
        )),
        type = "message",
        duration = 6
      )
    }, ignoreInit = TRUE)
  })

  output$distribution_plot_type_ui <- renderUI({
    req(sim_data())

    if (identical(sim_data()$response_format, "likert")) {
      selectInput(
        "distribution_plot_type",
        "Type de graphique :",
        choices = c("Fréquences par catégorie" = "bar"),
        selected = "bar"
      )
    } else {
      selectInput(
        "distribution_plot_type",
        "Type de graphique :",
        choices = c(
          "Histogrammes" = "hist",
          "Boîtes à moustaches" = "boxplot",
          "Courbes de densité" = "density",
          "QQ-plots" = "qqplot"
        ),
        selected = "hist"
      )
    }
  })

  output$correlation_interpretation <- renderUI({
    req(sim_data())

    d <- sim_data()
    notes <- list()

    if (identical(d$response_format, "likert")) {
      notes <- c(notes, list(div(
        class = "encadre-att",
        strong("Données Likert : "),
        "les corrélations affichées ici sont des corrélations de Pearson calculées ",
        paste0("sur les codes 1 à ", d$likert_categories, ". Elles sont atténuées par "),
        "l'ordinalisation; pour une analyse factorielle de réponses ordinales, ",
        "privilégiez une matrice de corrélations polychoriques (voir l'onglet ",
        "Vérification)."
      )))
    }

    if (length(d$reversed_items) > 0) {
      notes <- c(notes, list(div(
        class = "encadre-info",
        strong("Items inversés : "),
        paste0(
          paste(d$reversed_items, collapse = ", "),
          ". Ils corrèlent négativement avec les autres items de leur échelle tant ",
          "qu'ils ne sont pas recodés."
        )
      )))
    }

    if (length(notes) == 0) NULL else tagList(notes)
  })

  output$verification_source_ui <- renderUI({
    req(sim_data())
    d <- sim_data()

    choices <- c(
      "Réponses continues initiales" = "base",
      "Données finales (Pearson)" = "final"
    )

    if (identical(d$response_format, "likert") && requireNamespace("psych", quietly = TRUE)) {
      choices <- c(choices, "Données finales (polychoriques)" = "poly")
    }

    radioButtons(
      "verification_source",
      "Corrélations comparées à la population :",
      choices = choices,
      selected = {
        previous <- isolate(input$verification_source) %||% "base"
        if (previous %in% choices) previous else "base"
      },
      inline = TRUE
    )
  })

  output$verification_explanation <- renderUI({
    req(sim_data())

    d <- sim_data()
    source <- input$verification_source %||% "base"

    effects <- c(
      if (!identical(d$measurement_invariance, "invariant")) "le DIF",
      if (nrow(d$response_style_cases) > 0) "le style de réponse",
      if (identical(d$response_format, "likert")) "le codage Likert",
      if (!identical(d$missingness_mechanism, "none")) "les données manquantes"
    )
    effects_txt <- if (length(effects) == 0) {
      NULL
    } else if (length(effects) == 1) {
      effects
    } else {
      paste0(paste(effects[-length(effects)], collapse = ", "), " et ", effects[length(effects)])
    }

    if (identical(source, "base")) {
      return(tagList(
        p(
          "Les réponses continues initiales (", tags$em("ΛF + ε"), ") forment un ",
          "échantillon aléatoire de la population définie par les paramètres. Les ",
          "corrélations observées fluctuent donc autour des corrélations ",
          "populationnelles; la bande grise contient environ 95 % des valeurs ",
          "attendues pour cette taille d'échantillon."
        ),
        if (!is.null(effects_txt)) {
          div(
            class = "encadre-info",
            "Cette comparaison est faite avant ", effects_txt,
            " : elle isole la seule fluctuation d'échantillonnage. Choisissez ",
            "« Données finales » pour voir l'effet de ces transformations."
          )
        }
      ))
    }

    if (identical(source, "final")) {
      return(tagList(
        p(
          "Les corrélations de Pearson sont calculées sur les données téléchargées",
          if (!identical(d$missingness_mechanism, "none")) " (paires disponibles)" else "",
          "."
        ),
        if (is.null(effects_txt)) {
          div(
            class = "encadre-info",
            "Aucune transformation n'a été ajoutée : les données finales sont ",
            "identiques aux réponses continues initiales."
          )
        } else {
          div(
            class = "encadre-att",
            "Les écarts par rapport à la diagonale combinent la fluctuation ",
            "d'échantillonnage et l'effet de ", effects_txt, ". ",
            if (identical(d$response_format, "likert")) {
              "Un nuage situé sous la diagonale traduit l'atténuation due à l'ordinalisation."
            } else {
              ""
            }
          )
        }
      ))
    }

    tagList(
      p(
        "Les corrélations polychoriques estiment la corrélation entre les réponses ",
        "continues sous-jacentes à partir des seules catégories observées. Elles ",
        "corrigent en grande partie l'atténuation des corrélations de Pearson."
      ),
      div(
        class = "encadre-info",
        "Leur erreur d'échantillonnage est plus grande que celle d'une corrélation ",
        "de Pearson sur données continues : la bande grise, calculée pour des ",
        "données continues, est ici un repère approximatif."
      )
    )
  })

  output$population_structure_interpretation <- renderUI({
    req(sim_data())

    d <- sim_data()
    notes <- list()

    if (identical(d$structure, "bifactor")) {
      notes <- c(notes, list(div(
        class = "encadre-info",
        strong("Structure bifactorielle : "),
        "la colonne FG contient les charges sur le facteur général, commun à ",
        "tous les items; les colonnes F1, F2, ... contiennent les charges sur ",
        "les facteurs spécifiques. Tous les facteurs sont orthogonaux."
      )))
    }

    if (length(d$reversed_items) > 0) {
      notes <- c(notes, list(div(
        class = "encadre-info",
        strong("Items inversés : "),
        "leurs charges sont négatives (colonne « Sens »). La communalité et ",
        "l'unicité ne changent pas : seule la direction de la relation est inversée."
      )))
    }

    if (identical(d$response_format, "likert")) {
      notes <- c(notes, list(div(
        class = "encadre-info",
        "La structure affichée est celle des réponses continues sous-jacentes. ",
        "Les catégories 1 à ", d$likert_categories, " sont obtenues ensuite par ",
        if (identical(d$likert_pattern_mode, "mixed")) {
          "application du profil de seuils propre à chaque item (indiqué dans le tableau)."
        } else {
          "application du même profil de seuils à tous les items."
        },
        " Chaque item conserve ses seuils dans tous les groupes."
      )))
    }

    if (length(notes) == 0) NULL else tagList(notes)
  })

  output$measurement_invariance_notice <- renderUI({
    req(sim_data())

    data_obj <- sim_data()

    if (identical(data_obj$measurement_invariance, "invariant")) {
      return(NULL)
    }

    if (identical(data_obj$measurement_invariance, "threshold_dif")) {
      dif <- data_obj$threshold_dif

      return(
        div(
          class = "encadre-att",
          strong("DIF de seuils introduit : "),
          "pour ",
          strong(dif$Variable[1]),
          ", les seuils de ",
          strong(dif$Groupe[1]),
          paste0(
            " sont décalés de ", fmt_n(dif[["Décalage"]][1], 2),
            ". À niveau latent égal, ce groupe a donc moins de chances de choisir "
          ),
          "les catégories élevées pour cet item."
        )
      )
    }

    dif <- data_obj$intercept_dif

    div(
      class = "encadre-att",
      strong("DIF d'intercept introduit : "),
      "pour ",
      strong(dif$Variable[1]),
      ", l'intercept de ",
      strong(dif$Groupe[1]),
      paste0(
        " est augmenté de ", fmt_n(dif[["Décalage"]][1], 2),
        ". À niveau latent égal, ce groupe obtient donc une moyenne observée plus "
      ),
      "élevée pour cet item."
    )
  })

  output$response_style_notice <- renderUI({
    req(sim_data())

    data_obj <- sim_data()
    affected_cases <- data_obj$response_style_cases

    if (is.null(affected_cases) || nrow(affected_cases) == 0) {
      return(NULL)
    }

    div(
      class = "encadre-att",
      strong("Style de réponse introduit : "),
      paste0(
        nrow(affected_cases), " répondants (",
        fmt_pct(data_obj$response_style_prop, 0),
        ") présentent le style suivant : ",
        tolower(affected_cases$Style[1]),
        ". Il est appliqué à leurs réponses de tous les items avant le codage Likert."
      ),
      if (identical(data_obj$response_style, "acquiescence") && length(data_obj$reversed_items) > 0) {
        " Comme l'acquiescement augmente aussi les réponses aux items inversés, il ajoute une variance de méthode qui ne suit pas le sens des items."
      }
    )
  })

  output$data_missing_notice <- renderUI({
    req(sim_data())
    d <- sim_data()
    if (identical(d$missingness_mechanism, "none")) {
      return(NULL)
    }
    div(
      class = "encadre-att",
      strong("Données manquantes : "),
      paste0(
        fmt_pct(d$missingness_realized_rate, 1), " des cellules sont vides (",
        missingness_labels[[d$missingness_mechanism]], "). "
      ),
      "Voir l'onglet « Données manquantes » pour leurs conséquences."
    )
  })

  # Afficher les données simulées
  output$simulated_data <- renderDT({
    req(sim_data())

    data_obj <- sim_data()

    # Limiter à un échantillon plus petit pour l'affichage
    response_data <- data_obj$response

    if (nrow(response_data) > 100) {
      display_data <- response_data[1:100, ]
    } else {
      display_data <- response_data
    }

    dt_fr(
      display_data,
      digits = 3,
      options = list(
        pageLength = 10,
        paging = TRUE,
        dom = "rtip"
      ),
      caption = if (nrow(response_data) > 100) {
        paste0(
          "Affichage des 100 premières observations (sur ",
          format(nrow(response_data), big.mark = " "),
          ")"
        )
      } else {
        paste0(
          "Jeu de données complet : ",
          nrow(response_data),
          " observations"
        )
      }
    )
  })

  # ============================================================
  # DESCRIPTION DES DONNÉES GÉNÉRÉES
  # ============================================================

  output$global_descriptives_table <- renderDT({
    req(sim_data())

    desc <- describe_variables(sim_data()$response_numeric)
    if (identical(sim_data()$missingness_mechanism, "none")) {
      desc[["% manquant"]] <- NULL
    }

    many <- nrow(desc) > 25

    dt_fr(
      desc,
      digits = 3,
      options = list(
        paging = many,
        pageLength = 25,
        dom = if (many) "tip" else "t"
      )
    )
  })

  output$group_description_ui <- renderUI({
    req(sim_data())

    data_obj <- sim_data()

    if (data_obj$n_groups <= 1) {
      return(
        div(
          class = "alert alert-info",
          "Un seul groupe a été généré. Les statistiques descriptives ",
          "sont présentées dans « Description globale »."
        )
      )
    }

    tagList(
      card(
        full_screen = TRUE,
        card_header("Moyennes par groupe"),
        card_body(
          p(
            "Chaque ligne présente le vecteur des moyennes observées ",
            "dans un groupe."
          ),
          DTOutput("group_means_table")
        )
      ),
      card(
        full_screen = TRUE,
        card_header("Structure par groupe"),
        card_body(
          layout_columns(
            col_widths = c(4, 8),
            selectInput(
              "description_group",
              "Groupe :",
              choices = paste0(
                "G",
                seq_len(data_obj$n_groups)
              ),
              selected = "G1"
            ),
            radioButtons(
              "group_matrix_type",
              "Matrice :",
              choices = c(
                "Corrélations" = "cor",
                "Covariances" = "cov"
              ),
              selected = "cor",
              inline = TRUE
            )
          ),
          uiOutput("group_matrix_n"),
          DTOutput("group_matrix_table")
        )
      )
    )
  })


  output$group_means_table <- renderDT({
    req(sim_data())

    data_obj <- sim_data()
    x <- data_obj$response_numeric
    groups <- data_obj$group_membership

    group_levels <- unique(groups)

    result <- do.call(
      rbind,
      lapply(
        group_levels,
        function(g) {
          idx <- groups == g

          vapply(
            x[idx, , drop = FALSE],
            mean,
            numeric(1),
            na.rm = TRUE
          )
        }
      )
    )

    display <- data.frame(
      Groupe = group_levels,
      N = as.integer(table(factor(groups, levels = group_levels))),
      result,
      check.names = FALSE,
      row.names = NULL
    )

    dt_fr(display, digits = 3)
  })


  output$group_matrix_table <- renderDT({
    req(
      sim_data(),
      input$description_group
    )

    data_obj <- sim_data()

    group_id <- input$description_group

    idx <- data_obj$group_membership == group_id

    x <- data_obj$response_numeric[
      idx, ,
      drop = FALSE
    ]

    mat <- if (identical(input$group_matrix_type, "cov")) {
      cov(x, use = "pairwise.complete.obs")
    } else {
      cor(x, use = "pairwise.complete.obs")
    }

    display <- data.frame(
      Variable = rownames(mat),
      mat,
      check.names = FALSE,
      row.names = NULL
    )

    dt_fr(display, digits = 3)
  })

  output$group_matrix_n <- renderUI({
    req(sim_data(), input$description_group)

    data_obj <- sim_data()
    n_group <- sum(data_obj$group_membership == input$description_group)

    div(
      class = "alert alert-light py-2 mb-3",
      strong("Taille du groupe sélectionné : "),
      format(n_group, big.mark = " ")
    )
  })

  # ============================================================
  # Matrice de corrélations observées
  # ============================================================

  output$observed_corr_table <- renderDT({
    req(sim_data())

    response_data <- sim_data()$response_numeric

    R <- cor(
      response_data,
      use = "pairwise.complete.obs"
    )

    df <- data.frame(
      Variable = rownames(R),
      R,
      check.names = FALSE
    )

    dt_fr(df, digits = 3, class = "compact stripe")
  })

  # ============================================================
  # Représentation visuelle des corrélations observées
  # ============================================================

  output$observed_corr_plot <- renderPlot({
    req(sim_data())

    R <- cor(
      sim_data()$response_numeric,
      use = "pairwise.complete.obs"
    )
    R[is.na(R)] <- 0

    p <- ncol(R)

    corrplot::corrplot(
      R,
      method = "color",
      type = "full",
      order = "hclust",
      hclust.method = "ward.D2",
      tl.col = "black",
      tl.cex = max(0.45, min(1.15, 28 / p)),
      tl.srt = 45,
      diag = TRUE,
      addgrid.col = if (p > 60) NA else "grey85",
      mar = c(0, 0, 2, 0),
      title = "Structure des corrélations observées"
    )
  })


  output$download_corr_matrix <- downloadHandler(
    filename = function() {
      ext <- switch(input$corr_download_format,
        "csv"   = ".csv",
        "xlsx"  = ".xlsx",
        "stata" = ".do",
        "spss"  = ".sav"
      )

      paste0(
        if (!is.null(sim_data()) && identical(sim_data()$response_format, "likert")) {
          "matrice_correlations_pearson_likert_"
        } else {
          "matrice_correlations_"
        },
        format(Sys.time(), "%Y%m%d_%H%M%S"),
        ext
      )
    },
    content = function(file) {
      req(sim_data())

      # ----------------------------------------------------------
      # Statistiques observées de l'échantillon
      # ----------------------------------------------------------
      response_data <- sim_data()$response_numeric

      R <- cor(
        response_data,
        use = "pairwise.complete.obs"
      )

      N <- nrow(response_data)

      means <- colMeans(
        response_data,
        na.rm = TRUE
      )

      sds <- vapply(
        response_data,
        sd,
        numeric(1),
        na.rm = TRUE
      )

      varnames <- colnames(R)
      p <- length(varnames)

      # Écriture numérique stable avec point décimal
      fmt <- function(x, digits = 6) {
        out <- sprintf(
          paste0("%.", digits, "f"),
          x
        )

        gsub(
          ",",
          ".",
          out,
          fixed = TRUE
        )
      }

      # ==========================================================
      # CSV
      # ==========================================================
      if (input$corr_download_format == "csv") {
        csv_data <- data.frame(
          Variable = rownames(R),
          R,
          check.names = FALSE
        )

        write.csv(
          csv_data,
          file,
          row.names = FALSE
        )

        # ==========================================================
        # Excel
        # ==========================================================
      } else if (input$corr_download_format == "xlsx") {
        wb <- openxlsx::createWorkbook()

        openxlsx::addWorksheet(
          wb,
          "Correlations"
        )

        # N
        openxlsx::writeData(
          wb,
          sheet = "Correlations",
          x = paste0(
            "N = ", N,
            if (anyNA(response_data)) " (données manquantes : corrélations calculées sur les paires disponibles)" else ""
          ),
          startRow = 1,
          startCol = 1
        )

        # Moyennes
        means_df <- data.frame(
          Statistique = "Moyenne",
          t(means),
          check.names = FALSE
        )

        names(means_df)[-1] <- varnames

        openxlsx::writeData(
          wb,
          sheet = "Correlations",
          x = means_df,
          startRow = 3,
          startCol = 1
        )

        # Écarts-types
        sds_df <- data.frame(
          Statistique = "Écart-type",
          t(sds),
          check.names = FALSE
        )

        names(sds_df)[-1] <- varnames

        openxlsx::writeData(
          wb,
          sheet = "Correlations",
          x = sds_df,
          startRow = 5,
          startCol = 1
        )

        # Matrice
        excel_data <- data.frame(
          Variable = rownames(R),
          R,
          check.names = FALSE
        )

        openxlsx::writeData(
          wb,
          sheet = "Correlations",
          x = excel_data,
          startRow = 8,
          startCol = 1
        )

        openxlsx::saveWorkbook(
          wb,
          file,
          overwrite = TRUE
        )

        # ==========================================================
        # Stata
        # ==========================================================
      } else if (input$corr_download_format == "stata") {
        # --------------------------------------------------------
        # Matrice complète pour factormat / pcamat
        # --------------------------------------------------------
        matrix_rows <- vapply(
          seq_len(p),
          function(i) {
            paste(
              fmt(R[i, ]),
              collapse = ", "
            )
          },
          character(1)
        )

        # --------------------------------------------------------
        # Triangle inférieur pour SSD
        # --------------------------------------------------------
        corr_rows <- vapply(
          seq_len(p),
          function(i) {
            paste(
              fmt(R[i, seq_len(i)]),
              collapse = " "
            )
          },
          character(1)
        )

        lines <- c(
          "* ========================================================",
          "* Matrice de corrélations observées",
          paste0("* N = ", N),
          if (anyNA(response_data)) {
            c(
              "* Attention : données manquantes. Les corrélations sont calculées",
              "* sur les paires disponibles; N correspond au nombre total de lignes."
            )
          },
          "* ========================================================",
          "",
          "* --------------------------------------------------------",
          "* 1. Matrice Stata pour AFE / ACP",
          "* --------------------------------------------------------",
          "",
          "#delimit ;",
          "matrix input C = (",
          paste(
            matrix_rows,
            collapse = " \\\n"
          ),
          ");",
          "#delimit cr",
          "",
          sprintf(
            "matrix rownames C = %s",
            paste(varnames, collapse = " ")
          ),
          sprintf(
            "matrix colnames C = %s",
            paste(varnames, collapse = " ")
          ),
          "",
          "matrix list C",
          "",
          "* Exemples AFE / ACP :",
          sprintf(
            "* factormat C, n(%d) factors(3)",
            N
          ),
          sprintf(
            "* pcamat C, n(%d) components(3)",
            N
          ),
          "",
          "* --------------------------------------------------------",
          "* 2. Summary Statistics Data (SSD) pour SEM / CFA",
          "* --------------------------------------------------------",
          "",
          "clear",
          "",
          sprintf(
            "ssd init %s",
            paste(varnames, collapse = " ")
          ),
          sprintf(
            "ssd set obs %d",
            N
          ),
          sprintf(
            "ssd set means %s",
            paste(fmt(means), collapse = " ")
          ),
          sprintf(
            "ssd set sd %s",
            paste(fmt(sds), collapse = " ")
          ),
          "",
          "#delimit ;",
          "ssd set correlations",
          paste(
            corr_rows,
            collapse = " \\\n"
          ),
          ";",
          "#delimit cr",
          "",
          "ssd status",
          "",
          "* Les données SSD sont maintenant prêtes pour sem.",
          "* Exemple CFA à adapter :",
          "* sem (F1 -> V1 V2 V3 V4 V5)",
          "",
          "* Le SEM Builder peut également utiliser ces données SSD."
        )

        writeLines(
          lines,
          con = file,
          useBytes = TRUE
        )

        # ==========================================================
        # SPSS
        # ==========================================================
      } else if (input$corr_download_format == "spss") {
        # ----------------------------------------------------------
        # Fichier matriciel SPSS / AMOS
        # ----------------------------------------------------------

        # Préparer les deux variables spéciales SPSS
        rowtype <- character(p + 3)
        varname <- character(p + 3)

        # Ordre :
        # 1 = N
        # 2:(p+1) = CORR
        # p+2 = STDDEV
        # p+3 = MEAN

        rowtype[1] <- "n"

        rowtype[2:(p + 1)] <- "corr"
        varname[2:(p + 1)] <- varnames

        rowtype[p + 2] <- "stddev"
        rowtype[p + 3] <- "mean"

        # ----------------------------------------------------------
        # Partie numérique
        # ----------------------------------------------------------

        M <- matrix(
          NA_real_,
          nrow = p + 3,
          ncol = p
        )

        colnames(M) <- varnames

        # N
        M[1, ] <- N

        # Corrélations : triangle inférieur seulement
        for (i in seq_len(p)) {
          M[i + 1, seq_len(i)] <- R[i, seq_len(i)]
        }

        # Écarts-types
        M[p + 2, ] <- sds

        # Moyennes
        M[p + 3, ] <- means

        # ----------------------------------------------------------
        # Construire le fichier matriciel
        # ----------------------------------------------------------

        spss_matrix <- data.frame(
          rowtype_ = sprintf("%-8s", rowtype),
          varname_ = sprintf("%-8s", varname),
          M,
          check.names = FALSE,
          stringsAsFactors = FALSE
        )

        # Écrire directement un vrai fichier SAV
        haven::write_sav(
          spss_matrix,
          file
        )
      }
    }
  )


  # ============================================================
  # Structure populationnelle
  # ============================================================

  output$population_structure_table <- renderDT({
    req(sim_data())

    data_obj <- sim_data()
    Lambda <- data_obj$loadings

    group_name <- if (length(data_obj$group_factor_covariances) == 1) {
      "G1"
    } else {
      req(input$population_structure_group)
      input$population_structure_group
    }

    # Les charges sont communes aux groupes, mais les communalités
    # dépendent de la covariance factorielle du groupe choisi.
    common_variance <- diag(
      Lambda %*%
        data_obj$group_factor_covariances[[group_name]] %*%
        t(Lambda)
    )
    total_variance <- common_variance + data_obj$uniquenesses
    communalities <- common_variance / total_variance
    uniquenesses <- data_obj$uniquenesses / total_variance

    df <- data.frame(
      Variable = rownames(Lambda),
      Lambda,
      `Facteur principal` = paste0("F", data_obj$factor_assignments),
      check.names = FALSE
    )

    if (length(data_obj$reversed_items) > 0) {
      df$Sens <- ifelse(rownames(Lambda) %in% data_obj$reversed_items, "Inversé", "Direct")
    }

    df$Communalité <- communalities
    df$Unicité <- uniquenesses

    if (identical(data_obj$response_format, "likert")) {
      item_profiles <- data_obj$likert_item_profiles[rownames(Lambda)]
      item_thresholds <- data_obj$likert_thresholds[
        rownames(Lambda),
        ,
        drop = FALSE
      ]

      df[["Profil Likert"]] <- unname(likert_profile_labels[item_profiles])
      df <- cbind(df, item_thresholds)
    }

    many <- nrow(df) > 25

    dt <- dt_fr(
      df,
      digits = 3,
      options = list(
        paging = many,
        pageLength = 25,
        dom = if (many) "tip" else "t"
      )
    )

    if ("Sens" %in% names(df)) {
      dt <- formatStyle(
        dt,
        "Sens",
        target = "row",
        backgroundColor = styleEqual("Inversé", "#fff7ef")
      )
    }

    dt
  })

  output$population_structure_group_selector <- renderUI({
    req(sim_data())

    data_obj <- sim_data()
    n_groups <- length(data_obj$group_factor_covariances)

    if (n_groups <= 1) {
      return(NULL)
    }

    tagList(
      selectInput(
        "population_structure_group",
        "Communalités et unicités du groupe :",
        choices = paste0("G", seq_len(n_groups)),
        selected = "G1"
      ),
      div(
        class = "encadre-info",
        "Les charges factorielles sont communes aux groupes; les communalités et ",
        "les unicités peuvent varier lorsque les covariances factorielles diffèrent."
      )
    )
  })

  # ============================================================
  # STRUCTURE FACTORIELLE POPULATIONNELLE PAR GROUPE
  # ============================================================

  output$population_factor_means_table <- renderDT({
    req(sim_data())

    obj <- sim_data()

    display <- data.frame(
      Groupe = rownames(obj$factor_means),
      obj$factor_means,
      check.names = FALSE,
      row.names = NULL
    )

    dt_fr(display, digits = 3)
  })


  output$population_group_selector <- renderUI({
    req(sim_data())

    obj <- sim_data()

    n_groups <- length(obj$group_factor_covariances)

    if (n_groups <= 1) {
      return(
        div(
          style = "padding-top: 0.4rem;",
          strong("Groupe : "),
          "G1"
        )
      )
    }

    selectInput(
      "population_group",
      "Groupe :",
      choices = paste0(
        "G",
        seq_len(n_groups)
      ),
      selected = "G1"
    )
  })


  output$population_factor_matrix_table <- renderDT({
    req(sim_data())

    obj <- sim_data()

    group_name <- if (
      length(obj$group_factor_covariances) == 1
    ) {
      "G1"
    } else {
      req(input$population_group)
      input$population_group
    }

    mat <- if (
      identical(
        input$population_factor_matrix_type,
        "cov"
      )
    ) {
      obj$group_factor_covariances[[group_name]]
    } else {
      obj$group_factor_correlations[[group_name]]
    }

    display <- data.frame(
      Facteur = rownames(mat),
      mat,
      check.names = FALSE,
      row.names = NULL
    )

    dt_fr(display, digits = 3)
  })

  # ============================================================
  # Fidélité populationnelle
  # ============================================================

  reliability <- reactive({
    req(sim_data())
    population_reliability(sim_data(), "G1")
  })

  output$reliability_table <- renderDT({
    rel <- reliability()
    dt <- dt_fr(rel, digits = 3)
    if (nrow(rel) > 1 && grepl("^Score total", rel$Échelle[nrow(rel)])) {
      dt <- formatStyle(
        dt,
        "Échelle",
        target = "row",
        fontWeight = styleEqual(rel$Échelle[nrow(rel)], "bold")
      )
    }
    dt
  })

  output$reliability_summary <- renderUI({
    d <- sim_data()
    req(d)
    rel <- reliability()
    scales <- rel[!grepl("^Score total", rel$Échelle), , drop = FALSE]

    badges <- list()

    if (all(scales$Nature == "Parallèle")) {
      badges <- c(badges, list(div(
        class = "encadre-info",
        span(class = "badge-nature", "Modèle parallèle exact"),
        " Dans chaque échelle, les items ont la même charge et la même unicité : ",
        "ils sont parallèles (donc aussi tau-équivalents). L'alpha de Cronbach ",
        "est alors exactement égal à ω."
      )))
    } else if (any(scales$Nature == "Parallèle")) {
      badges <- c(badges, list(div(
        class = "encadre-info",
        span(class = "badge-nature", "Échelles parallèles"),
        " ", paste(scales$Échelle[scales$Nature == "Parallèle"], collapse = ", "),
        " : items parallèles, α = ω."
      )))
    }

    if (identical(d$structure, "bifactor")) {
      L <- d$loadings
      general_sq <- sum(L[, 1]^2)
      specific_sq <- sum(L[, -1]^2)
      ecv <- general_sq / (general_sq + specific_sq)
      omega_h <- rel$`ω du facteur`[nrow(rel)]

      badges <- c(badges, list(div(
        class = if (omega_h >= 0.80) "encadre-info" else "encadre-att",
        strong("Indices bifactoriels : "),
        paste0(
          "ω hiérarchique = ", fmt_n(omega_h, 3),
          "; part de la variance commune due au facteur général (ECV) = ", fmt_n(ecv, 3), ". "
        ),
        if (omega_h >= 0.80 && ecv >= 0.70) {
          "Le score total reflète surtout le facteur général : il peut être interprété comme essentiellement unidimensionnel."
        } else if (omega_h >= 0.80) {
          "Le score total reflète surtout le facteur général, mais les facteurs spécifiques conservent une part notable de la variance commune."
        } else {
          "Une part importante de la variance du score total provient des facteurs spécifiques ou de l'erreur : un modèle à un seul facteur serait réducteur."
        }
      )))
    }

    if (length(badges) == 0) NULL else tagList(badges)
  })

  output$reliability_explanation <- renderUI({
    d <- sim_data()
    req(d)
    rel <- reliability()
    scales <- rel[!grepl("^Score total", rel$Échelle), , drop = FALSE]
    gap <- max(scales$`ω total` - scales$`α populationnel`, na.rm = TRUE)

    div(
      class = "mt-3",
      tags$dl(
        tags$dt("ω total"),
        tags$dd(
          "Part de la variance du score de l'échelle qui est commune (due aux ",
          "facteurs). C'est la fidélité du score."
        ),
        tags$dt("ω du facteur"),
        tags$dd(
          "Part de la variance du score due au seul facteur de l'échelle. Sans ",
          "charges secondaires, elle égale ω total. Des charges secondaires positives ",
          "ajoutent de la variance commune venant d'autres facteurs (ω total plus ",
          "élevé); des charges négatives en retirent. Dans un modèle bifactoriel, ",
          "le facteur général s'ajoute; pour le score total, cette colonne donne le ",
          "ω hiérarchique."
        ),
        tags$dt("α populationnel"),
        tags$dd(
          paste0(
            "Valeur que prendrait l'alpha de Cronbach dans la population. Il égale ω ",
            "lorsque les items sont tau-équivalents et le sous-estime sinon (écart ",
            "maximal ici : ", fmt_n(max(gap, 0), 3), ")."
          )
        )
      ),
      p(
        class = "text-muted mb-0",
        "Les valeurs sont calculées dans G1, où chaque facteur a une variance de 1. ",
        "Dans un groupe dont la variance factorielle diffère, la fidélité change aussi."
      )
    )
  })

  # ============================================================
  # Comparaison population - échantillon
  # ============================================================

  verification_matrix <- reactive({
    req(sim_data())
    d <- sim_data()
    source <- input$verification_source %||% "base"

    if (identical(source, "poly") && identical(d$response_format, "likert")) {
      R <- withProgress(message = "Calcul des corrélations polychoriques...", value = 0.5, {
        tryCatch(
          suppressWarnings(suppressMessages(
            psych::polychoric(d$response_numeric, correct = 0)$rho
          )),
          error = function(e) NULL
        )
      })
      if (is.null(R)) {
        showNotification(
          "Les corrélations polychoriques n'ont pas pu être calculées; les corrélations de Pearson sont affichées.",
          type = "warning"
        )
        source <- "final"
      } else {
        dimnames(R) <- list(colnames(d$response_numeric), colnames(d$response_numeric))
        return(list(R = R, n = nrow(d$response_numeric), source = source))
      }
    }

    if (identical(source, "final")) {
      x <- d$response_numeric
      R <- cor(x, use = "pairwise.complete.obs")
      observed <- !is.na(as.matrix(x))
      pair_n <- crossprod(observed)
      return(list(R = R, n = mean(pair_n[lower.tri(pair_n)]), source = source))
    }

    list(R = cor(d$response_continuous_base), n = nrow(d$response_continuous_base), source = "base")
  })

  comparison_data <- reactive({
    d <- sim_data()
    req(d)
    vm <- verification_matrix()
    Sigma <- pooled_population_correlation(d)
    keep <- lower.tri(Sigma)
    rho <- Sigma[keep]
    r <- vm$R[keep]
    half_width <- 1.96 * (1 - rho^2) / sqrt(vm$n)
    list(
      df = data.frame(population = rho, sample = r, inside = abs(r - rho) <= half_width),
      n = vm$n,
      source = vm$source
    )
  })

  output$population_sample_plot <- renderPlot({
    cd <- comparison_data()
    comparison <- cd$df

    lim <- range(c(comparison$population, comparison$sample, 0), finite = TRUE)
    lim <- lim + c(-0.05, 0.05)
    band <- data.frame(x = seq(lim[1], lim[2], length.out = 200))
    band$hw <- 1.96 * (1 - band$x^2) / sqrt(cd$n)

    comparison$Position <- factor(
      ifelse(comparison$inside, "Dans la bande", "Hors de la bande"),
      levels = c("Dans la bande", "Hors de la bande")
    )

    source_label <- switch(
      cd$source,
      base = "réponses continues initiales",
      final = "données finales, corrélations de Pearson",
      poly = "données finales, corrélations polychoriques"
    )

    comma <- scales::label_number(accuracy = 0.1, decimal.mark = ",", style_negative = "minus")
    breaks <- seq(-1, 1, by = 0.2)

    ggplot(comparison, aes(x = population, y = sample)) +
      geom_ribbon(
        data = band,
        aes(x = x, ymin = x - hw, ymax = x + hw),
        inherit.aes = FALSE,
        fill = "grey85",
        alpha = 0.7
      ) +
      geom_abline(intercept = 0, slope = 1, linewidth = 0.9, colour = "grey30") +
      geom_point(aes(colour = Position), alpha = 0.7, size = 2.4) +
      scale_colour_manual(
        values = c("Dans la bande" = "#2c7fb8", "Hors de la bande" = "#e6550d"),
        drop = FALSE,
        name = NULL
      ) +
      scale_x_continuous(breaks = breaks, labels = comma) +
      scale_y_continuous(breaks = breaks, labels = comma) +
      coord_equal(xlim = lim, ylim = lim) +
      labs(
        title = "Corrélations populationnelles et observées",
        subtitle = paste0(
          "N = ", format(nrow(sim_data()$response), big.mark = " "),
          " — ", source_label, "; chaque point représente une paire de variables"
        ),
        x = "Corrélation populationnelle",
        y = "Corrélation observée"
      ) +
      theme_minimal(base_size = 15) +
      theme(
        plot.title = element_text(size = 18, face = "bold"),
        plot.subtitle = element_text(size = 13),
        axis.title = element_text(size = 15),
        axis.text = element_text(size = 13),
        legend.position = "top",
        legend.text = element_text(size = 13)
      )
  })


  output$population_sample_summary <- renderUI({
    cd <- comparison_data()
    df <- cd$df
    differences <- df$sample - df$population

    mean_abs <- mean(abs(differences))
    max_abs <- max(abs(differences))
    mean_signed <- mean(differences)
    inside <- mean(df$inside)

    interpretation <- if (identical(cd$source, "base")) {
      paste0(
        "Ces écarts représentent la fluctuation d'échantillonnage. Ils ne ",
        "constituent pas une erreur du générateur et diminuent lorsque la taille ",
        "de l'échantillon augmente. Environ 95 % des paires devraient se trouver ",
        "dans la bande."
      )
    } else if (mean_signed > 0.02) {
      paste0(
        "En moyenne, les corrélations observées dépassent de ",
        fmt_n(mean_signed, 3),
        " les corrélations populationnelles : une source de variance commune ",
        "étrangère aux facteurs (par exemple un style de réponse) s'ajoute à tous ",
        "les items et gonfle leurs relations."
      )
    } else if (mean_signed < -0.02) {
      paste0(
        "En moyenne, les corrélations observées sont inférieures de ",
        fmt_n(abs(mean_signed), 3),
        " aux corrélations populationnelles : les transformations appliquées ",
        "atténuent les relations au-delà de la seule fluctuation d'échantillonnage."
      )
    } else if (inside < 0.80) {
      paste0(
        "L'écart moyen signé est faible, mais seulement ", fmt_pct(inside, 0),
        " des paires se trouvent dans la bande : les transformations appliquées ",
        "ajoutent beaucoup de dispersion aux corrélations, sans les déplacer ",
        "systématiquement dans un sens."
      )
    } else {
      paste0(
        "L'écart moyen signé est faible : les transformations appliquées ne ",
        "biaisent pas systématiquement les corrélations, même si certaines paires ",
        "peuvent s'écarter davantage."
      )
    }

    div(
      class = "alert alert-light mt-3",
      p(
        strong("Écart absolu moyen : "), fmt_n(mean_abs, 3),
        " — ", strong("écart absolu maximal : "), fmt_n(max_abs, 3),
        " — ", strong("écart moyen signé : "), fmt_n(mean_signed, 3),
        " — ", strong("paires dans la bande : "), paste0(fmt_pct(inside, 0), ".")
      ),
      p(class = "mb-0", interpretation)
    )
  })

  # ============================================================
  # Données manquantes
  # ============================================================

  output$missing_ui <- renderUI({
    req(sim_data())
    d <- sim_data()

    if (identical(d$missingness_mechanism, "none")) {
      return(div(
        class = "alert alert-info",
        "Aucune donnée manquante n'a été générée. Choisissez un mécanisme dans la ",
        "carte « Données manquantes » de l'onglet Configurer pour étudier ses ",
        "conséquences."
      ))
    }

    tagList(
      card(
        card_header("Résumé"),
        card_body(uiOutput("missing_summary"))
      ),
      card(
        full_screen = TRUE,
        card_header("Moyennes : données complètes et cas disponibles"),
        card_body(
          p(
            "Les données complètes, avant suppression, sont connues. On peut donc ",
            "mesurer exactement le biais de la moyenne calculée sur les seuls cas ",
            "disponibles. Les lignes en orange présentent un écart d'au moins ",
            "0,10 écart-type."
          ),
          DTOutput("missing_bias_table")
        )
      ),
      layout_columns(
        col_widths = c(5, 7),
        card(
          card_header("Données manquantes par groupe"),
          card_body(DTOutput("missing_group_table"))
        ),
        card(
          full_screen = TRUE,
          card_header("Aperçu du patron"),
          card_body(
            plotOutput("missing_pattern_plot", height = "420px")
          )
        )
      )
    )
  })

  missing_bias <- reactive({
    d <- sim_data()
    req(d, !identical(d$missingness_mechanism, "none"))

    complete <- d$response_complete
    observed <- d$response_numeric

    out <- data.frame(
      Variable = names(observed),
      `% manquant` = 100 * colMeans(is.na(observed)),
      `Moyenne complète` = colMeans(complete),
      `Moyenne des cas disponibles` = colMeans(observed, na.rm = TRUE),
      check.names = FALSE
    )
    out$Écart <- out$`Moyenne des cas disponibles` - out$`Moyenne complète`
    out$`Écart (en ET)` <- out$Écart / vapply(complete, sd, numeric(1))

    if (identical(d$missingness_mechanism, "mar")) {
      anchor <- d$missingness_mar_anchor
      out$`r avec la variable auxiliaire` <- as.numeric(cor(complete)[, anchor])
      out$Rôle <- ifelse(out$Variable == anchor, "Variable auxiliaire (complète)", "")
    }

    rownames(out) <- NULL
    out
  })

  output$missing_summary <- renderUI({
    d <- sim_data()
    req(d, !identical(d$missingness_mechanism, "none"))

    x <- d$response_numeric
    n <- nrow(x)
    complete_cases <- sum(stats::complete.cases(x))
    bias <- missing_bias()
    abs_bias <- abs(bias$`Écart (en ET)`)

    mechanism_text <- switch(
      d$missingness_mechanism,
      mcar = "Chaque cellule avait la même probabilité d'être effacée. Les cas disponibles forment un sous-échantillon aléatoire : les moyennes restent sans biais, seule la précision diminue.",
      mar = paste0(
        "La probabilité d'absence augmente avec la valeur de ", d$missingness_mar_anchor,
        ", qui reste complète. Les personnes dont la valeur de ", d$missingness_mar_anchor,
        " est élevée perdent davantage de réponses : les variables corrélées positivement avec ",
        d$missingness_mar_anchor, " voient leur moyenne sous-estimée sur les cas disponibles, ",
        "celles qui y sont corrélées négativement (items inversés, par exemple), surestimée. Le biais ",
        "croît avec cette corrélation et avec le taux d'absence. Une méthode qui exploite ",
        d$missingness_mar_anchor, " (maximum de vraisemblance, imputation multiple) peut le corriger."
      ),
      mnar = "Chaque réponse avait d'autant plus de chances de disparaître qu'elle était élevée. Les moyennes des cas disponibles sont sous-estimées, et aucune variable observée ne permet de corriger complètement ce biais."
    )

    tagList(
      p(
        strong("Mécanisme : "), missingness_labels[[d$missingness_mechanism]], br(),
        strong("Cellules manquantes : "),
        paste0(fmt_pct(d$missingness_realized_rate, 1), " (cible : ", fmt_pct(d$missingness_rate, 0), ")"),
        br(),
        strong("Cas complets : "),
        paste0(
          format(complete_cases, big.mark = " "), " sur ", format(n, big.mark = " "),
          " (", fmt_pct(complete_cases / n, 1), ")"
        ),
        br(),
        strong("Écart des moyennes (cas disponibles − complètes) : "),
        paste0(
          "moyenne absolue de ", fmt_n(mean(abs_bias), 3), " écart-type, maximum de ",
          fmt_n(max(abs_bias), 3)
        )
      ),
      div(class = "encadre-info", mechanism_text),
      div(
        class = "encadre-att",
        strong("Suppression des cas incomplets : "),
        "une analyse qui écarte toute personne ayant au moins une réponse manquante ",
        "ne conserverait que ", fmt_pct(complete_cases / n, 1), " de l'échantillon. ",
        "Avec ", ncol(x), " variables, même un faible taux par cellule se cumule ",
        "rapidement."
      )
    )
  })

  output$missing_bias_table <- renderDT({
    bias <- missing_bias()
    many <- nrow(bias) > 25

    dt_fr(
      bias,
      digits = 3,
      options = list(paging = many, pageLength = 25, dom = if (many) "tip" else "t")
    ) |>
      formatStyle(
        "Écart (en ET)",
        target = "row",
        backgroundColor = styleInterval(c(-0.10, 0.10 - 1e-9), c("#fff3e6", "", "#fff3e6"))
      )
  })

  output$missing_group_table <- renderDT({
    d <- sim_data()
    req(d, !identical(d$missingness_mechanism, "none"))
    x <- d$response_numeric
    groups <- factor(d$group_membership, levels = paste0("G", seq_len(d$n_groups)))

    out <- do.call(rbind, lapply(levels(groups), function(g) {
      xg <- x[groups == g, , drop = FALSE]
      data.frame(
        Groupe = g,
        N = nrow(xg),
        `% de cellules manquantes` = 100 * mean(is.na(xg)),
        `% de cas complets` = 100 * mean(stats::complete.cases(xg)),
        check.names = FALSE
      )
    }))

    dt_fr(out, digits = 1)
  })

  output$missing_pattern_plot <- renderPlot({
    d <- sim_data()
    req(d, !identical(d$missingness_mechanism, "none"))
    x <- d$response_numeric
    rows <- seq_len(min(150, nrow(x)))
    m <- is.na(as.matrix(x[rows, , drop = FALSE]))

    long <- data.frame(
      Observation = rep(rows, times = ncol(m)),
      Variable = factor(rep(colnames(m), each = length(rows)), levels = colnames(m)),
      Statut = ifelse(as.vector(m), "Manquante", "Observée")
    )

    ggplot(long, aes(x = Variable, y = Observation, fill = Statut)) +
      geom_tile() +
      scale_fill_manual(values = c("Manquante" = "#d6604d", "Observée" = "#eef2f7"), name = NULL) +
      scale_y_reverse(expand = c(0, 0)) +
      labs(
        title = paste0("Les ", length(rows), " premières observations"),
        x = NULL,
        y = "Observation"
      ) +
      theme_minimal(base_size = 13) +
      theme(
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = if (ncol(m) > 40) 7 else 10),
        panel.grid = element_blank(),
        legend.position = "top"
      )
  })

  # ============================================================
  # Paquets pédagogiques
  # ============================================================

  student_codebook <- function(data_obj) {
    item_names <- names(data_obj$response_numeric)
    is_likert <- identical(data_obj$response_format, "likert")
    has_missing <- !identical(data_obj$missingness_mechanism, "none")

    response_type <- if (is_likert) "Likert ordinal" else "Continue"
    coding <- if (is_likert) {
      paste0("1 à ", data_obj$likert_categories, "; catégories ordinales")
    } else {
      "Valeur continue simulée"
    }
    if (has_missing) coding <- paste0(coding, "; cellule vide = valeur manquante")

    codebook <- data.frame(
      Variable = c("Groupe", item_names),
      Type = c("Groupe d'appartenance", rep(response_type, length(item_names))),
      Codage = c(
        paste0("G1 à G", length(data_obj$group_sizes)),
        rep(coding, length(item_names))
      ),
      Description = c(
        "Identifiant du groupe simulé",
        rep("Item simulé", length(item_names))
      ),
      check.names = FALSE
    )

    if (length(data_obj$reversed_items) > 0) {
      codebook[["Sens de formulation"]] <- c(
        "",
        ifelse(item_names %in% data_obj$reversed_items, "Inversé (à recoder avant de calculer un score)", "Direct")
      )
    }

    codebook
  }

  student_guide <- function(data_obj) {
    is_likert <- identical(data_obj$response_format, "likert")
    has_missing <- !identical(data_obj$missingness_mechanism, "none")

    guide <- c(
      "JEU DE DONNÉES POUR ANALYSE FACTORIELLE",
      "",
      paste0("Nombre total d'observations : ", nrow(data_obj$response)),
      paste0("Nombre de variables : ", ncol(data_obj$response_numeric)),
      paste0("Nombre de groupes : ", length(data_obj$group_sizes)),
      paste0("Taille(s) des groupes : ", paste(data_obj$group_sizes, collapse = ", ")),
      paste0(
        "Format des items : ",
        if (is_likert) paste0("Likert ordinal (1 à ", data_obj$likert_categories, ")") else "continu"
      ),
      "",
      "Contenu du paquet :",
      "- donnees_etudiants.csv : jeu de données à analyser;",
      "- codebook_etudiants.csv : description des variables;",
      "- guide_etudiant.txt : ce guide.",
      "",
      "Consigne suggérée :",
      "Explorez le nombre de dimensions, la structure des charges et la cohérence",
      "des regroupements d'items. Justifiez les décisions avec les résultats obtenus."
    )

    if (is_likert) {
      guide <- c(
        guide,
        "",
        "Note pour les données ordinales : pour l'analyse factorielle, privilégiez",
        "une matrice de corrélations polychoriques lorsque votre logiciel le permet."
      )
    }

    if (length(data_obj$reversed_items) > 0) {
      guide <- c(
        guide,
        "",
        "Items inversés : certains items sont formulés en sens inverse (voir le",
        "codebook). Recodez-les avant de calculer un score d'échelle ou un alpha."
      )
    }

    if (has_missing) {
      guide <- c(
        guide,
        "",
        "Données manquantes : les cellules vides du fichier CSV sont des valeurs",
        "manquantes. Examinez leur répartition avant de choisir une stratégie",
        "de traitement (cas complets, paires disponibles, FIML, imputation)."
      )
    }

    guide
  }

  teacher_key <- function(data_obj) {
    Lambda <- data_obj$loadings
    key <- data.frame(
      Variable = rownames(Lambda),
      round(Lambda, 4),
      `Facteur principal` = paste0("F", data_obj$factor_assignments),
      Sens = ifelse(rownames(Lambda) %in% data_obj$reversed_items, "Inversé", "Direct"),
      `Communalité (G1)` = round(data_obj$communalities, 4),
      `Variance résiduelle` = round(data_obj$uniquenesses, 4),
      `Erreur asymétrique` = ifelse(rownames(Lambda) %in% data_obj$skewed_variables, "Oui", "Non"),
      check.names = FALSE
    )

    if (identical(data_obj$response_format, "likert")) {
      key[["Profil Likert"]] <- unname(
        likert_profile_labels[data_obj$likert_item_profiles[rownames(Lambda)]]
      )
      key <- cbind(
        key,
        round(data_obj$likert_thresholds[rownames(Lambda), , drop = FALSE], 4)
      )
    }

    key
  }

  write_csv_utf8 <- function(x, path) {
    write.csv(x, path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  }

  write_student_materials <- function(directory, data_obj) {
    write_csv_utf8(data_obj$response, file.path(directory, "donnees_etudiants.csv"))
    write_csv_utf8(student_codebook(data_obj), file.path(directory, "codebook_etudiants.csv"))
    writeLines(
      student_guide(data_obj),
      file.path(directory, "guide_etudiant.txt"),
      useBytes = TRUE
    )
  }

  create_teaching_package <- function(file, data_obj, include_key = FALSE) {
    package_dir <- tempfile("paquet_factoriel_")
    dir.create(package_dir, recursive = TRUE)
    on.exit(unlink(package_dir, recursive = TRUE, force = TRUE), add = TRUE)

    write_student_materials(package_dir, data_obj)

    if (isTRUE(include_key)) {
      write_csv_utf8(teacher_key(data_obj), file.path(package_dir, "corrige_enseignant.csv"))
      write_csv_utf8(
        data.frame(
          Groupe = paste0("G", seq_along(data_obj$group_sizes)),
          N = data_obj$group_sizes,
          data_obj$factor_means,
          check.names = FALSE
        ),
        file.path(package_dir, "parametres_groupes.csv")
      )
      group_factor_structure <- do.call(
        rbind,
        lapply(seq_along(data_obj$group_factor_correlations), function(g) {
          rbind(
            data.frame(
              Groupe = paste0("G", g),
              Type = "Corrélation",
              Facteur = rownames(data_obj$group_factor_correlations[[g]]),
              data_obj$group_factor_correlations[[g]],
              check.names = FALSE
            ),
            data.frame(
              Groupe = paste0("G", g),
              Type = "Covariance",
              Facteur = rownames(data_obj$group_factor_covariances[[g]]),
              data_obj$group_factor_covariances[[g]],
              check.names = FALSE
            )
          )
        })
      )
      write_csv_utf8(group_factor_structure, file.path(package_dir, "structure_factorielle_par_groupe.csv"))

      rel <- population_reliability(data_obj, "G1")
      rel[sapply(rel, is.numeric)] <- lapply(rel[sapply(rel, is.numeric)], round, 4)
      write_csv_utf8(rel, file.path(package_dir, "fidelite_populationnelle.csv"))

      pop_cor <- pooled_population_correlation(data_obj)
      write_csv_utf8(
        data.frame(Variable = rownames(pop_cor), round(pop_cor, 4), check.names = FALSE),
        file.path(package_dir, "matrice_correlations_population.csv")
      )

      write_csv_utf8(
        data.frame(Groupe = data_obj$response$Groupe, round(data_obj$factor_scores, 4), check.names = FALSE),
        file.path(package_dir, "scores_factoriels_vrais.csv")
      )

      writeLines(
        lavaan_syntax(data_obj),
        file.path(package_dir, "modele_lavaan.R"),
        useBytes = TRUE
      )

      has_threshold_dif <- !is.null(data_obj$threshold_dif) &&
        nrow(data_obj$threshold_dif) > 0
      has_intercept_dif <- !is.null(data_obj$intercept_dif) &&
        nrow(data_obj$intercept_dif) > 0
      has_response_style <- !is.null(data_obj$response_style_cases) &&
        nrow(data_obj$response_style_cases) > 0
      has_missing <- !identical(data_obj$missingness_mechanism, "none")
      is_likert <- identical(data_obj$response_format, "likert")

      if (has_threshold_dif) {
        write_csv_utf8(data_obj$threshold_dif, file.path(package_dir, "non_invariance_seuils.csv"))
      }
      if (has_intercept_dif) {
        write_csv_utf8(data_obj$intercept_dif, file.path(package_dir, "non_invariance_intercepts.csv"))
      }
      if (has_response_style) {
        write_csv_utf8(data_obj$response_style_cases, file.path(package_dir, "styles_reponses_enseignant.csv"))
      }
      if (has_missing) {
        write_csv_utf8(
          data.frame(Groupe = data_obj$response$Groupe, data_obj$response_complete, check.names = FALSE),
          file.path(package_dir, "donnees_completes_avant_manquantes.csv")
        )
      }
      if (is_likert) {
        write_csv_utf8(
          data.frame(Groupe = data_obj$response$Groupe, round(data_obj$response_continuous, 4), check.names = FALSE),
          file.path(package_dir, "reponses_continues_sous_jacentes.csv")
        )
      }

      settings <- data_obj$settings
      settings_lines <- paste0("- ", names(settings), " : ", settings)

      writeLines(
        c(
          "CORRIGÉ ENSEIGNANT — NE PAS DISTRIBUER AUX ÉTUDIANTS",
          "",
          "Paramètres de la simulation",
          settings_lines,
          "",
          paste0(
            "Pour reproduire exactement ces données : inscrire la graine ",
            data_obj$seed, " et les mêmes réglages dans l'application."
          ),
          "",
          "Effets introduits",
          paste0(
            "- Non-invariance de mesure : ",
            if (has_threshold_dif) {
              paste0("seuils de ", data_obj$threshold_dif$Variable[1], " décalés dans ", data_obj$threshold_dif$Groupe[1])
            } else if (has_intercept_dif) {
              paste0("intercept de ", data_obj$intercept_dif$Variable[1], " augmenté dans ", data_obj$intercept_dif$Groupe[1])
            } else {
              "aucune"
            }
          ),
          paste0(
            "- Style de réponse : ",
            if (has_response_style) {
              paste0(data_obj$response_style_cases$Style[1], " chez ", nrow(data_obj$response_style_cases), " répondants")
            } else {
              "aucun"
            }
          ),
          paste0(
            "- Items inversés : ",
            if (length(data_obj$reversed_items) > 0) paste(data_obj$reversed_items, collapse = ", ") else "aucun"
          ),
          paste0(
            "- Données manquantes : ",
            if (has_missing) {
              paste0(
                fmt_pct(data_obj$missingness_realized_rate, 1), " des cellules",
                if (identical(data_obj$missingness_mechanism, "mar")) {
                  paste0("; variable auxiliaire complète : ", data_obj$missingness_mar_anchor)
                } else {
                  ""
                }
              )
            } else {
              "aucune"
            }
          ),
          "",
          "Fichiers",
          "- corrige_enseignant.csv : charges, facteur principal, sens, communalités, unicités et, s'il y a lieu, seuils Likert;",
          "- parametres_groupes.csv et structure_factorielle_par_groupe.csv : moyennes et matrices latentes par groupe;",
          "- fidelite_populationnelle.csv : ω total, ω du facteur et α populationnels de chaque échelle (G1);",
          "- matrice_correlations_population.csv : corrélations populationnelles de l'ensemble des données;",
          "- scores_factoriels_vrais.csv : scores latents véritables de chaque personne;",
          "- modele_lavaan.R : syntaxe d'une AFC du modèle ayant servi à générer les données;",
          if (has_missing) "- donnees_completes_avant_manquantes.csv : données avant la suppression des valeurs;",
          if (is_likert) "- reponses_continues_sous_jacentes.csv : réponses continues avant le codage Likert;",
          if (has_threshold_dif || has_intercept_dif) "- non_invariance_*.csv : item et groupe touchés par le DIF;",
          if (has_response_style) "- styles_reponses_enseignant.csv : répondants présentant un style de réponse."
        ),
        file.path(package_dir, "lisez_moi_enseignant.txt"),
        useBytes = TRUE
      )
    }

    status <- utils::zip(
      zipfile = file,
      files = list.files(package_dir, full.names = TRUE),
      flags = "-jq"
    )

    if (!identical(status, 0L)) {
      stop("La création du paquet ZIP a échoué.")
    }
  }

  output$download_student_package <- downloadHandler(
    filename = function() {
      paste0("paquet_etudiant_factoriel_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".zip")
    },
    content = function(file) {
      req(sim_data())
      create_teaching_package(file, sim_data(), include_key = FALSE)
    }
  )

  output$download_teacher_package <- downloadHandler(
    filename = function() {
      paste0("corrige_enseignant_factoriel_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".zip")
    },
    content = function(file) {
      req(sim_data())
      create_teaching_package(file, sim_data(), include_key = TRUE)
    }
  )

  # Téléchargement des données simulées dans différents formats
  output$download_data <- downloadHandler(
    filename = function() {
      ext <- switch(input$download_format,
        "csv" = ".csv",
        "xlsx" = ".xlsx",
        "dta" = ".dta",
        "sav" = ".sav",
        "omv" = ".omv"
      )
      prefix <- if (!is.null(sim_data()) && identical(sim_data()$response_format, "likert")) {
        "donnees_likert_"
      } else {
        "donnees_simulees_"
      }
      paste0(prefix, format(Sys.time(), "%Y%m%d_%H%M%S"), ext)
    },
    content = function(file) {
      data_obj <- sim_data()
      req(data_obj)

      data_to_export <- as.data.frame(data_obj$response)

      # Noms compatibles avec Stata et SPSS
      if (input$download_format %in% c("dta", "sav")) {
        names(data_to_export) <- make.names(names(data_to_export), unique = TRUE)
        names(data_to_export) <- gsub("\\.", "_", names(data_to_export))
      }

      switch(input$download_format,
        "csv" = write.csv(data_to_export, file, row.names = FALSE, na = ""),
        "xlsx" = openxlsx::write.xlsx(data_to_export, file, rowNames = FALSE),
        "dta" = haven::write_dta(data_to_export, file),
        "sav" = haven::write_sav(data_to_export, file),
        "omv" = {
          if (!requireNamespace("jmvReadWrite", quietly = TRUE)) {
            message <- "Installez le package R « jmvReadWrite » pour télécharger au format jamovi."
            showNotification(message, type = "error")
            stop(message, call. = FALSE)
          }

          if (identical(data_obj$response_format, "likert")) {
            item_names <- names(data_obj$response_numeric)
            categories <- seq_len(data_obj$likert_categories)
            data_to_export[item_names] <- lapply(
              data_to_export[item_names], ordered, levels = categories
            )
          }

          omv_file <- tempfile(fileext = ".omv")
          on.exit(unlink(omv_file), add = TRUE)
          jmvReadWrite::write_omv(data_to_export, omv_file)
          if (!file.copy(omv_file, file, overwrite = TRUE)) {
            stop("Impossible de préparer le fichier jamovi pour le téléchargement.", call. = FALSE)
          }
        }
      )
    }
  )

  # ============================================================
  # Distributions
  # ============================================================

  output$distrib_var_selector <- renderUI({
    req(sim_data())
    var_names <- colnames(sim_data()$response_numeric)

    tagList(
      selectizeInput(
        "selected_distrib_vars",
        "Variables affichées :",
        choices = var_names,
        selected = var_names[seq_len(min(8, length(var_names)))],
        multiple = TRUE,
        options = list(plugins = list("remove_button"))
      ),
      helpText("Au plus 20 variables sont tracées à la fois afin de garder des graphiques lisibles."),
      actionLink("select_all_distrib_vars", "Tout sélectionner"),
      " · ",
      actionLink("deselect_all_distrib_vars", "Tout désélectionner")
    )
  })

  output$distribution_plot <- renderPlot({
    req(sim_data(), input$distribution_plot_type)

    data_obj <- sim_data()
    response_data <- data_obj$response_numeric
    vars_to_display <- intersect(input$selected_distrib_vars, colnames(response_data))

    if (length(vars_to_display) == 0) {
      plot.new()
      title(main = "Aucune variable sélectionnée")
      return(invisible())
    }

    vars_to_display <- vars_to_display[seq_len(min(20, length(vars_to_display)))]

    n_cols <- min(4, length(vars_to_display))
    n_rows <- ceiling(length(vars_to_display) / n_cols)

    old_par <- par(no.readonly = TRUE)
    on.exit(par(old_par), add = TRUE)

    grid_par <- function() {
      par(
        mfrow = c(n_rows, n_cols),
        mar = c(4.5, 4.5, 3.5, 1.5),
        cex.axis = 1.1,
        cex.lab = 1.2,
        cex.main = 1.2
      )
    }

    reversed <- data_obj$reversed_items
    plot_title <- function(var) if (var %in% reversed) paste0(var, " (inversé)") else var

    type <- input$distribution_plot_type

    if (identical(type, "bar") && identical(data_obj$response_format, "likert")) {
      grid_par()
      k <- data_obj$likert_categories
      for (var in vars_to_display) {
        frequencies <- table(factor(response_data[[var]], levels = seq_len(k)))
        barplot(
          frequencies,
          names.arg = seq_len(k),
          main = plot_title(var),
          xlab = "Catégorie",
          ylab = "Fréquence",
          col = "#4C78A8",
          border = NA
        )
      }
    } else if (identical(type, "hist")) {
      grid_par()
      for (var in vars_to_display) {
        x <- response_data[[var]]
        x <- x[!is.na(x)]
        hist(x, main = plot_title(var), xlab = "Valeur", ylab = "Densité",
          probability = TRUE, border = "white", col = "#9ecae1")
        tryCatch(lines(density(x), lwd = 2), error = function(e) NULL)
      }
    } else if (identical(type, "boxplot")) {
      par(
        mar = c(7, 4.5, 3.5, 1.5),
        cex.axis = 1.05,
        cex.lab = 1.2,
        cex.main = 1.2
      )
      boxplot(
        response_data[, vars_to_display, drop = FALSE],
        main = "Boîtes à moustaches des variables sélectionnées",
        ylab = "Valeur",
        las = 2,
        col = "#deebf7"
      )
    } else if (identical(type, "density")) {
      grid_par()
      for (var in vars_to_display) {
        x <- response_data[[var]]
        x <- x[!is.na(x)]
        tryCatch(
          plot(density(x), main = plot_title(var), xlab = "Valeur", ylab = "Densité", lwd = 2),
          error = function(e) {
            plot.new()
            title(main = paste(var, "- densité non calculable"))
          }
        )
      }
    } else if (identical(type, "qqplot")) {
      grid_par()
      for (var in vars_to_display) {
        x <- response_data[[var]]
        x <- x[!is.na(x)]
        qqnorm(x, main = paste("QQ-plot :", plot_title(var)),
          xlab = "Quantiles théoriques", ylab = "Quantiles observés", pch = 16,
          col = grDevices::adjustcolor("#2c7fb8", 0.5))
        qqline(x, lwd = 2)
      }
    }
  })
}

shinyApp(ui, server)
