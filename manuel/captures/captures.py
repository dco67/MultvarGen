"""Captures d'écran de MultvarGen pour le manuel.
Usage : python3 captures/captures.py --url http://127.0.0.1:8851 --images images [--seulement nom1,nom2]
L'application doit tourner (shiny::runApp). Chaque capture part d'une configuration
explicite et d'une graine fixe, de sorte que les nombres visibles correspondent au texte."""
import argparse, time
from pathlib import Path
from playwright.sync_api import sync_playwright

CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"

def attendre(page, pause=0.8):
    page.wait_for_function("() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected() && !document.documentElement.classList.contains('shiny-busy')", timeout=300000)
    time.sleep(pause)
    page.wait_for_function("() => !document.documentElement.classList.contains('shiny-busy')", timeout=300000)

def onglet(page, titre):
    loc = page.locator(f"xpath=//a[(@data-bs-toggle='tab' or @data-toggle='tab') and normalize-space()=\"{titre}\"]")
    for k in range(loc.count()):
        if loc.nth(k).is_visible():
            loc.nth(k).click(); attendre(page, 1.5); return
    raise RuntimeError("onglet introuvable : " + titre)

def choisir(page, i, v):
    page.evaluate("([id, v]) => { const el=$('#'+id); if (el[0].selectize) el[0].selectize.setValue(v); else el.val(v).trigger('change'); }", [i, str(v)]); attendre(page, 0.8)

def saisir(page, i, v):
    page.evaluate("([id, v]) => { const el = document.getElementById(id); el.value = v; $(el).trigger('change'); }", [i, str(v)]); attendre(page, 0.6)

def curseur(page, i, v):
    page.evaluate("([id, v]) => { $('#'+id).data('ionRangeSlider').update({from: v}); }", [i, v]); attendre(page, 0.6)

def radio(page, nom, v):
    page.evaluate("([n, v]) => { const el = document.querySelector(`input[name='${n}'][value='${v}']`); el.checked = true; $(el).trigger('change'); }", [nom, v]); attendre(page, 0.8)

def nettoyer(page):
    page.evaluate("() => document.querySelectorAll('.shiny-notification').forEach(n => n.remove())")

# Réglages « fil rouge » : 3 facteurs corrélés à 0,30, 5 items, charges élevées, aucune charge secondaire
BASE = dict(nfact=3, vpf_type="fixed", vpf_fixed=5, structure="correlated", fc_type="fixed", fc_fixed=0.30,
            pl_type="H", cl_type="None", reverse_prop="0", distri="normal", response_format="continuous",
            missing_mechanism="none", n_groups=1, sizes=[500])

NUM = {"nfact", "vpf_fixed", "low_vpf", "up_vpf"}
SLI = {"fc_fixed", "pl_fixed", "cl_fixed", "gl_fixed", "response_style_prop", "missing_rate"}

def configurer(page, graine, **kw):
    """Applique BASE modifié par kw, puis génère avec la graine."""
    r = dict(BASE); r.update(kw)
    onglet(page, "Configurer")
    curseur(page, "n_groups", r.pop("n_groups")); attendre(page, 1.2)
    sizes = r.pop("sizes")
    for g, n in enumerate(sizes, start=1):
        saisir(page, f"group_n_{g}", n)
    # l'ordre compte : format avant les options Likert, groupes avant l'invariance
    ordre = ["structure", "response_format"] + [k for k in r if k not in ("structure", "response_format")]
    for k in ordre:
        if k not in r: continue
        v = r[k]
        if k in NUM: saisir(page, k, v)
        elif k in SLI: curseur(page, k, v)
        else: choisir(page, k, v)
    saisir(page, "seed", graine)
    page.evaluate("() => document.getElementById('generate').click()"); attendre(page, 3)
    nettoyer(page)

def carte(page, entete, fichier, debut=0):
    """Capture la carte dont l'en-tête est exactement « entete »."""
    loc = page.locator(f"xpath=//div[contains(concat(' ', normalize-space(@class), ' '), ' card ')][./div[contains(@class,'card-header') and normalize-space()=\"{entete}\"]]")
    n = loc.count()
    for k in range(n):
        if loc.nth(k).is_visible():
            el = loc.nth(k); el.scroll_into_view_if_needed(); time.sleep(0.6)
            el.screenshot(path=str(fichier)); print("  ✓", Path(fichier).name, flush=True); return
    raise RuntimeError("carte introuvable : " + entete)

def element(page, css, fichier):
    el = page.locator(css).first; el.scroll_into_view_if_needed(); time.sleep(0.6)
    el.screenshot(path=str(fichier)); print("  ✓", Path(fichier).name, flush=True)

def rogner(fichier, haut=None, bas=None):
    from PIL import Image
    im = Image.open(fichier); w, h = im.size
    im.crop((0, haut or 0, w, min(h, bas) if bas else h)).save(fichier)

# --- Les captures --------------------------------------------------------
def c_configurer(page, out):
    configurer(page, 2024)
    onglet(page, "Configurer")
    carte(page, "Préréglages et génération", out / "cap-configurer-haut.png")
    # grille des cartes de réglages
    el = page.locator("xpath=//div[contains(@class,'bslib-grid')][.//div[contains(@class,'card-header') and normalize-space()='Structure des facteurs']]").first
    el.scroll_into_view_if_needed(); time.sleep(0.6)
    el.screenshot(path=str(out / "cap-configurer-cartes.png")); print("  ✓ cap-configurer-cartes.png")

def c_donnees(page, out):
    configurer(page, 2024)
    onglet(page, "Données"); onglet(page, "Données simulées")
    carte(page, "Aperçu des données générées", out / "cap-donnees-apercu.png")
    rogner(out / "cap-donnees-apercu.png", bas=900)
    onglet(page, "Description globale")
    carte(page, "Statistiques descriptives", out / "cap-descriptives.png")
    rogner(out / "cap-descriptives.png", bas=760)
    radio(page, "corr_view", "corrplot"); attendre(page, 2)
    element(page, "#observed_corr_plot", out / "cap-correlations.png")

def c_structure(page, out):
    configurer(page, 2024)
    onglet(page, "Structure populationnelle"); onglet(page, "Structure des variables")
    carte(page, "Structure factorielle populationnelle", out / "cap-structure-variables.png")
    rogner(out / "cap-structure-variables.png", bas=780)
    onglet(page, "Fidélité populationnelle")
    carte(page, "Fidélité exacte des échelles", out / "cap-fidelite.png")
    onglet(page, "Vérification")
    radio(page, "verification_source", "base"); attendre(page, 2)
    carte(page, "Population et échantillon", out / "cap-verification.png")

def c_verif_petit(page, out):
    configurer(page, 2024, sizes=[50])
    onglet(page, "Vérification"); radio(page, "verification_source", "base"); attendre(page, 2)
    carte(page, "Population et échantillon", out / "cap-verification-n50.png")

def c_parallele(page, out):
    configurer(page, 2024, nfact=1, vpf_fixed=6, pl_type="fixed", pl_fixed=0.70)
    onglet(page, "Structure populationnelle"); onglet(page, "Fidélité populationnelle")
    carte(page, "Fidélité exacte des échelles", out / "cap-fidelite-parallele.png")

def c_bifacteur(page, out):
    configurer(page, 2024, vpf_fixed=6, structure="bifactor", gl_type="M", pl_type="L")
    onglet(page, "Structure populationnelle"); onglet(page, "Structure des variables")
    carte(page, "Structure factorielle populationnelle", out / "cap-structure-bifactor.png")
    rogner(out / "cap-structure-bifactor.png", bas=760)
    onglet(page, "Fidélité populationnelle")
    carte(page, "Fidélité exacte des échelles", out / "cap-fidelite-bifactor.png")

def c_groupes(page, out):
    configurer(page, 2024, n_groups=3, sizes=[300, 300, 300], group_mean_diff="moderate", group_cov_diff="equal")
    onglet(page, "Données"); onglet(page, "Description par groupe")
    carte(page, "Moyennes par groupe", out / "cap-moyennes-groupes.png")
    onglet(page, "Structure populationnelle"); onglet(page, "Structure des facteurs")
    carte(page, "Moyennes factorielles populationnelles", out / "cap-moyennes-latentes.png")

def c_covgroupes(page, out):
    configurer(page, 2024, n_groups=2, sizes=[300, 300], group_mean_diff="none", group_cov_diff="high")
    onglet(page, "Structure populationnelle"); onglet(page, "Structure des facteurs")
    choisir(page, "population_group", "G2"); radio(page, "population_factor_matrix_type", "cov"); attendre(page, 1.5)
    carte(page, "Relations entre facteurs", out / "cap-covariances-g2.png")

def c_manquantes(page, out):
    configurer(page, 2024, missing_mechanism="mar", missing_rate=20)
    onglet(page, "Données"); onglet(page, "Données manquantes")
    carte(page, "Résumé", out / "cap-manquantes-resume.png")
    carte(page, "Moyennes : données complètes et cas disponibles", out / "cap-manquantes-biais.png")
    rogner(out / "cap-manquantes-biais.png", bas=820)

def c_likert(page, out):
    configurer(page, 2024, response_format="likert", likert_categories="5", likert_pattern_mode="mixed")
    onglet(page, "Données"); onglet(page, "Distributions")
    element(page, "#distribution_plot", out / "cap-likert-distributions.png")
    onglet(page, "Vérification"); radio(page, "verification_source", "final"); attendre(page, 2)
    carte(page, "Population et échantillon", out / "cap-verif-likert-pearson.png")
    radio(page, "verification_source", "poly"); attendre(page, 4)
    carte(page, "Population et échantillon", out / "cap-verif-likert-poly.png")

def c_inverses(page, out):
    configurer(page, 2024, reverse_prop="0.3333")
    onglet(page, "Données"); onglet(page, "Description globale")
    radio(page, "corr_view", "corrplot"); attendre(page, 2)
    element(page, "#observed_corr_plot", out / "cap-correlations-inverses.png")

TOUTES = dict(configurer=c_configurer, donnees=c_donnees, structure=c_structure, verif_petit=c_verif_petit,
              parallele=c_parallele, bifacteur=c_bifacteur, groupes=c_groupes, covgroupes=c_covgroupes,
              manquantes=c_manquantes, likert=c_likert, inverses=c_inverses)

if __name__ == "__main__":
    a = argparse.ArgumentParser()
    a.add_argument("--url", default="http://127.0.0.1:8851")
    a.add_argument("--images", default="images")
    a.add_argument("--seulement", default="")
    args = a.parse_args()
    out = Path(args.images); out.mkdir(exist_ok=True)
    noms = [n for n in args.seulement.split(",") if n] or list(TOUTES)
    with sync_playwright() as p:
        b = p.chromium.launch(executable_path=CHROME)
        for nom in noms:
            page = b.new_page(viewport={"width": 1300, "height": 2400}, device_scale_factor=1.5, locale="fr-CA")
            page.goto(args.url); attendre(page, 3); nettoyer(page)
            print(nom, flush=True)
            TOUTES[nom](page, out)
            page.close()
        b.close()
