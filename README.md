# MultvarGen

**Générateur pédagogique de données multivariées à structure factorielle connue.**

MultvarGen est une application **R/Shiny** permettant de construire une population, d’en tirer des échantillons et d’examiner les données obtenues. Elle fournit les paramètres du modèle générateur pour aider à comprendre ce qu’une analyse statistique retrouve dans un échantillon.

Elle permet de préparer des démonstrations, des travaux pratiques et des exercices de simulation en analyse factorielle, psychométrie et statistique multivariée.

- [Ouvrir l’application](https://shiny.dcstats.org/MultvarGen/)
- [Consulter le manuel pédagogique](https://dcstats.org/MultvarGen/)

## Pourquoi utiliser MultvarGen ?

Dans une étude réelle, la structure de la population reste inconnue. Avec des données simulées, on peut fixer cette structure, introduire une difficulté précise, puis examiner ses conséquences.

MultvarGen aide notamment à :

- comprendre les liens entre facteurs latents et variables observées ;
- étudier l’effet des charges principales, des charges secondaires et des corrélations entre facteurs ;
- distinguer les propriétés de la population des fluctuations d’échantillonnage ;
- explorer les conséquences du format ordinal, des items inversés et des données manquantes ;
- construire des groupes qui diffèrent par leurs moyennes, leurs covariances ou certains paramètres de mesure ;
- produire des jeux de données reproductibles accompagnés d’un dossier étudiant et d’un corrigé enseignant.

L’application assure la **génération, l’inspection et l’exportation**. Les données peuvent ensuite être analysées dans R, jamovi, SPSS, Stata, AMOS ou un autre logiciel approprié, pour une AFE, une AFC, une analyse multigroupe, une MANOVA, une analyse discriminante ou une corrélation canonique.

## Fonctionnalités

| Domaine | Possibilités |
| --- | --- |
| Structure factorielle | Facteurs corrélés ou modèle bifactoriel avec facteur général et facteurs spécifiques orthogonaux. |
| Indicateurs | Nombre de variables par facteur fixe ou variable, charges principales et secondaires, proportion d’items inversés. |
| Groupes | Effectifs par groupe, différences de moyennes latentes et de covariances factorielles. |
| Distribution | Composantes d’erreur normales ou asymétriques. |
| Réponses ordinales | Échelles Likert de 2 à 7 catégories, seuils communs ou profils de seuils variés, styles de réponse. |
| Invariance de mesure | Introduction ciblée d’un décalage d’intercept ou de seuils dans le deuxième groupe. |
| Données manquantes | Mécanismes MCAR, MAR et MNAR, avec proportion réglable. |
| Inspection | Statistiques descriptives, distributions, corrélations numériques et carte des corrélations ordonnée par regroupement hiérarchique. |
| Population connue | Charges, communalités, unicités, moyennes et matrices factorielles, indices de fidélité issus du modèle générateur. |
| Vérification | Comparaison des corrélations de la population et de l’échantillon ; option de corrélations polychoriques pour les données ordinales. |
| Réplication | Nouvel échantillon tiré dans la population déjà construite et gestion des graines de simulation. |

Six préréglages proposent des points de départ : **Personnalité**, **Tests cognitifs**, **Échelles d’attitudes**, **Performance académique**, **Détresse psychologique** et **Sondage Likert**. Ces intitulés désignent des scénarios simulés.

## Principe de génération

Le modèle factoriel continu constitue le point de départ :

$$
\mathbf{x} = \mathbf{\Lambda}\mathbf{f} + \boldsymbol{\varepsilon}
$$

Les variables observées résultent de facteurs latents, pondérés par les charges de la matrice Λ, et de composantes uniques. Les options choisies peuvent ensuite ajouter une non-invariance d’intercept, des styles de réponse, un codage ordinal avec non-invariance de seuils, puis des valeurs manquantes.

Les différents onglets permettent de suivre ces transformations et de confronter les observations à leur modèle générateur.

## Installation locale

### Dépendances principales

Installez les packages suivants dans R :

```r
install.packages(c(
  "shiny", "bslib", "DT", "ggplot2", "htmltools",
  "MASS", "Matrix", "corrplot", "scales"
))
```

### Exports et fonctions complémentaires

```r
install.packages(c("openxlsx", "haven", "psych", "jmvReadWrite"))
```

| Package | Fonction |
| --- | --- |
| `openxlsx` | Export Excel. |
| `haven` | Export des données Stata et SPSS. |
| `psych` | Calcul des corrélations polychoriques. |
| `jmvReadWrite` | Export au format jamovi `.omv`. |

Les paquets pédagogiques ZIP utilisent `utils::zip()` et nécessitent un utilitaire ZIP accessible depuis R. Vous pouvez vérifier son emplacement avec `Sys.which("zip")`.

Pour exécuter le script d’AFC fourni dans le corrigé enseignant, installez également `lavaan` :

```r
install.packages("lavaan")
```

### Lancement

Clonez ou téléchargez le dépôt. Conservez **`app.R` et `global.R` dans le même dossier**.

Depuis ce dossier, lancez :

```r
shiny::runApp(".", launch.browser = TRUE)
```

Dans RStudio, vous pouvez aussi ouvrir `app.R` et cliquer sur **Run App**.

## Première exploration guidée

**Besoin :** comprendre comment trois facteurs latents créent des regroupements de variables corrélées, et pourquoi les corrélations observées varient d’un échantillon à l’autre.

1. Dans **Configurer**, choisissez le préréglage **Tests cognitifs**. Il définit trois facteurs, six indicateurs par facteur, des charges principales élevées et des corrélations de 0,40 entre facteurs.
2. Choisissez **un groupe de 500 personnes** et inscrivez **2024** comme graine aléatoire. Conservez des réponses continues et l’absence de données manquantes, puis cliquez sur **Générer les données**.
3. Dans **Données**, examinez les distributions et la carte des corrélations. Cherchez les ensembles d’indicateurs qui partagent un même facteur. Les corrélations à l’intérieur de ces ensembles devraient généralement être plus fortes que celles entre ensembles.
4. Ouvrez **Structure populationnelle**. Vérifiez les charges principales, l’absence de charges secondaires et les relations entre facteurs : ces paramètres expliquent les regroupements observés.
5. Ouvrez **Vérification** pour comparer les corrélations de l’échantillon à celles de la population. Les écarts reflètent notamment la fluctuation d’échantillonnage.
6. Cliquez sur **Nouvel échantillon, même population**. Examinez ce qui change dans les observations et ce qui reste constant dans la structure génératrice.
7. Exportez les données en CSV pour poursuivre par une analyse factorielle dans votre logiciel habituel.

**Résultat à retenir :** les regroupements de variables proviennent du modèle factoriel, tandis que leurs caractéristiques observées dépendent aussi de l’échantillon. Une analyse réalisée sur les données exportées peut alors être comparée à une structure connue.

Le manuel développe d’autres scénarios : groupes, réponses ordinales, structure bifactorielle, non-invariance et données manquantes.

## Reproductibilité

Conservez **les réglages et les graines affichées** avec chaque jeu de données.

- **Générer les données** applique la configuration affichée pour reconstruire le scénario.
- **Nouvel échantillon, même population** réutilise les paramètres de la dernière population générée et tire de nouvelles personnes. Les effectifs des groupes peuvent être ajustés.
- La **graine de l’échantillon** permet d’identifier le nouveau tirage lorsque la population est conservée.

Un changement de graine peut modifier la structure lorsque certains paramètres sont tirés au hasard. Le bouton de nouvel échantillon est donc la commande adaptée pour étudier la variabilité à population constante.

## Exports et matériel pédagogique

### Données et matrices

- Données individuelles : **CSV**, **Excel**, **Stata**, **SPSS** et **jamovi**.
- Matrice de corrélations : **CSV**, **Excel**, **syntaxe Stata `.do`** et **fichier SPSS**.

La variable `Groupe` identifie l’appartenance aux groupes. L’aperçu affiche jusqu’à 100 observations ; le téléchargement contient le jeu complet.

### Paquet étudiant

L’archive ZIP contient les données CSV, un codebook et un guide de travail.

### Corrigé enseignant

L’archive ajoute les paramètres de génération, les structures factorielles, les scores latents véritables, les indices de fidélité populationnels et une syntaxe `lavaan` fondée sur les indicateurs principaux. Selon le scénario, elle comprend aussi les données complètes avant suppression, les réponses continues sous-jacentes et les informations sur les effets introduits.

Les deux archives permettent de distribuer un exercice tout en conservant les informations nécessaires à sa correction.

## Repères d’interprétation

- Une corrélation observée fluctue autour de sa valeur populationnelle ; l’augmentation de l’effectif améliore généralement la précision.
- Pour les réponses Likert, la matrice descriptive utilise les corrélations de Pearson sur les codes des catégories. La comparaison polychorique est proposée dans **Vérification** lorsque `psych` est installé.
- Les items inversés demandent un recodage adapté avant le calcul d’un score d’échelle.
- Les indices de fidélité populationnels sont issus du modèle continu sous-jacent, avec le groupe G1 comme référence ; les transformations des réponses doivent être prises en compte dans leur interprétation.
- Les mécanismes MCAR, MAR et MNAR sont connus ici parce qu’ils sont définis par la simulation. Leur identification dans des données réelles demande un raisonnement supplémentaire.

## Fichiers essentiels

| Fichier | Rôle |
| --- | --- |
| `app.R` | Interface, génération interactive, descriptions, vérifications et exports. |
| `global.R` | Moteur de simulation, préréglages et fonctions statistiques et graphiques. |
| `README.md` | Présentation, installation et prise en main. |

## Signaler un problème

Pour reproduire un problème, indiquez les réglages, les graines, la suite des manipulations et le message d’erreur. Vous pouvez joindre les informations de session R obtenues avec `sessionInfo()`.

## Auteur

**Daniel Coulombe — DCStats**
