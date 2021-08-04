# =============================================================================
# Fournir les répertoires
# =============================================================================

projet_dir <- "C:/EHCVM/NSU/"                       # où se trouve le projet
donnees_entree_dir <- paste0(projet_dir, "entree/") # où se trouvent les données brutes NSU
donnees_sortie_dir <- paste0(projet_dir, "sortie/") # où mettre les données fusionnées
images_entree_dir <- donnees_entree_dir             # où se trouver les images NSU
images_sortie_dir <- paste0(projet_dir, "images/")  # où mettre les images classées et leurs répertoires

# =============================================================================
# Charger les packages requis
# =============================================================================

# packages requis
packagesNeeded <- c(
    "devtools",     # faciliter l'installation de {nsuoutils} depuis GitHub
    "nsuoutils"     # fusionner les bases et classer les images NSU
)

# identifier les packages à installer
packagesToInstall <- packagesNeeded[!(packagesNeeded %in% installed.packages()[,"Package"])]

if ("devtools" %in% packagesToInstall) {
    install.packages(
        "devtools",  
        quiet = TRUE, 
        repos = 'https://cloud.r-project.org/', 
        dep = TRUE
    )
}

if ("nsuoutils" %in% packagesToInstall) {
    devtools::install_github("arthur-shaw/nsuoutils")
}

library(nsuoutils)

# =============================================================================
# Fusionner les bases NSU
# =============================================================================

# En spécifiant:
# - `dir_in`: le répertoire parent où retrouver les sous-répertoires avec données
# - `dir_regexp`: le texte--une expression régulière--qui identifie les sous-répertoires avec données
# - `dir_out`: le répertoire où sauvegarder les bases fusionnées en format Stata
nsuoutils::combine_nsu_data(
    dir_in = donnees_entree_dir,
    dir_regexp = "_STATA_",
    dir_out = donnees_sortie_dir
)

# =============================================================================
# Classer les images NSU
# =============================================================================

# D'abord, faire l'inventaire des produits-unités
produits_unites <- nsuoutils::inventory_product_units(dir = donnees_sortie_dir)

# Ensuite, créer des répertoires pour chaque produit et produit-unité retrouvé
nsuoutils::create_image_dirs(
    inventory_df = produits_unites, 
    dir = donnees_sortie_dir
)

# Puis, copier les images vers les répertoires produit-unité
nsuoutils::sort_images(
    inventory_df = produits_unites,
    dir_in = images_entree_dir,
    image_dir_pattern = "_Binary_",
    dir_out = images_sortie_dir    
)
