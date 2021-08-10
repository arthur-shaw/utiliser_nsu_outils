# =============================================================================
# Fournir les répertoires
# =============================================================================


projet_dir <- "C:/EHCVM/NSU/"                       # où se trouve le projet

# NSU de consommation
nsu_conso_dir <- paste0(projet_dir, "consommation/") # répertoire racine des NSU de consommation
conso_donnees_entree_dir <- paste0(nsu_conso_dir, "entree/") # où se trouvent les données brutes NSU
conso_donnees_sortie_dir <- paste0(nsu_conso_dir, "sortie/") # où les bases fusionnées seront sauvegardées
conso_image_entree_dir <- conso_donnees_entree_dir # où se trouver les images NSU
conso_images_sortie_dir <- paste0(projet_dir, "images/") # où mettre les images classées et leurs répertoires

# NSU de production
nsu_prod_dir <- paste0(projet_dir, "production/") # répertoire racine des NSU de consommation
prod_donnees_entree_dir <- paste0(nsu_prod_dir, "entree/") # où se trouvent les données brutes NSU
prod_donnees_sortie_dir <- paste0(nsu_conso_dir, "sortie/")  # où les bases fusionnées seront sauvegardées

# =============================================================================
# Charger les packages requis
# =============================================================================

# packages requis
packagesNeeded <- c(
    "devtools",     # faciliter l'installation de {nsuoutils} depuis GitHub
    "nsuoutils"     # fusionner  les bases et classer les images NSU
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
# NSU de consommation
# =============================================================================

# -----------------------------------------------------------------------------
# Fusionner les bases NSU
# -----------------------------------------------------------------------------

# En spécifiant:
# - `dir_in`: le répertoire parent où retrouver les sous-répertoires avec données
# - `dir_regexp`: le texte--une expression régulière--qui identifie les sous-répertoires avec données
# - `dir_out`: le répertoire où sauvegarder les bases fusionnées en format Stata
nsuoutils::combine_nsu_data(
    dir_in = conso_donnees_entree_dir,
    dir_regexp = "_STATA_",
    data_type = "consumption",
    dir_out = conso_donnees_sortie_dir
)

# Fusionner les observations au niveau des marchés
nsuoutils::combine_market_data(
    dir_in = conso_donnees_entree_dir,
    dir_regexp = "_STATA_",
    data_type = "consumption",
    dir_out = conso_donnees_sortie_dir
)

# -----------------------------------------------------------------------------
# Classer les images NSU
# -----------------------------------------------------------------------------

# D'abord, faire l'inventaire des produits-unités
produits_unites <- nsuoutils::inventory_product_units(dir = conso_donnees_sortie_dir)

# Ensuite, créer des répertoires pour chaque produit et produit-unité retrouvé
nsuoutils::create_image_dirs(
    inventory_df = produits_unites, 
    dir = conso_images_sortie_dir
)

# Puis, copier les images vers les répertoires produit-unité
nsuoutils::sort_images(
    inventory_df = produits_unites,
    dir_in = conso_image_entree_dir,
    image_dir_pattern = "_Binary_",
    dir_out = conso_images_sortie_dir    
)

# =============================================================================
# NSU de production
# =============================================================================

nsuoutils::combine_nsu_data(
    dir_in = prod_donnees_entree_dir,
    dir_regexp = "_production_", # NOTEZ BIEN: modifier selon votre situation
    data_type = "production",
    dir_out = prod_donnees_sortie_dir
)

# Fusionner les observations au niveau des marchés
nsuoutils::combine_market_data(
    dir_in = prod_donnees_entree_dir,
    dir_regexp = "_production_", # NOTEZ BIEN: modifier selon votre situation
    data_type = "production",
    dir_out = prod_donnees_sortie_dir
)

