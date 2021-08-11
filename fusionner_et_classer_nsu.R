# =============================================================================
# Fournir les répertoires
# =============================================================================

projet_dir <- "C:/EHCVM/NSU/"                       # où se trouve le projet

# NSU de consommation
nsu_conso_dir <- paste0(projet_dir, "consommation/") # répertoire racine des NSU de consommation
nsu_conso_entree <- paste0(nsu_conso_dir, "entree/") # où retrouver les fichier d'entrée
nsu_conso_donnees_entree <- paste0(nsu_conso_entree, "donnees/") # données d'entrée
nsu_conso_images_entree <- paste0(nsu_conso_entree, "images/") # images d'entrée
nsu_conso_sortie <- paste0(nsu_conso_dir, "sortie/") # où retourver les fichiers de sortie
nsu_conso_donnees_sortie <- paste0(nsu_conso_sortie, "donnees/") # données de sortie
nsu_conso_images_sortie <- paste0(nsu_conso_sortie, "images/") # images de sortie

# NSU de production
nsu_prod_dir <- paste0(projet_dir, "production/") # répertoire racine des NSU de consommation
nsu_prod_entree <- paste0(nsu_prod_dir, "entree/") # où se trouvent les données brutes NSU
nsu_prod_sortie <- paste0(nsu_prod_dir, "sortie/")  # où les bases fusionnées seront sauvegardées

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
    dir_in = nsu_conso_donnees_entree,
    dir_regexp = "_STATA_",
    data_type = "consumption",
    dir_out = nsu_conso_donnees_sortie
)

# Fusionner les observations au niveau des marchés
nsuoutils::combine_market_data(
    dir_in = nsu_conso_donnees_entree,
    dir_regexp = "_STATA_",
    data_type = "consumption",
    dir_out = nsu_conso_donnees_sortie
)

# -----------------------------------------------------------------------------
# Classer les images NSU
# -----------------------------------------------------------------------------

# D'abord, faire l'inventaire des produits-unités
produits_unites <- nsuoutils::inventory_product_units(dir = nsu_conso_donnees_sortie)

# Ensuite, créer des répertoires pour chaque produit et produit-unité retrouvé
nsuoutils::create_image_dirs(
    inventory_df = produits_unites, 
    dir = nsu_conso_images_sortie
)

# Puis, copier les images vers les répertoires produit-unité
nsuoutils::sort_images(
    inventory_df = produits_unites,
    dir_in = nsu_conso_images_entree,
    image_dir_pattern = "_Binary_",
    dir_out = nsu_conso_images_sortie    
)

# =============================================================================
# NSU de production
# =============================================================================

nsuoutils::combine_nsu_data(
    dir_in = nsu_prod_entree,
    dir_regexp = "_production_", # NOTEZ BIEN: modifier selon votre situation
    data_type = "production",
    dir_out = nsu_prod_sortie
)

# Fusionner les observations au niveau des marchés
nsuoutils::combine_market_data(
    dir_in = nsu_prod_entree,
    dir_regexp = "_production_", # NOTEZ BIEN: modifier selon votre situation
    data_type = "production",
    dir_out = nsu_prod_sortie
)

