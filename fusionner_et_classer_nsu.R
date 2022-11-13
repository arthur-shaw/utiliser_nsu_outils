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
# Définir les strates
# =============================================================================

# Mettre les variables qui, ensemble, définissent les strates
# Les valeurs serviront à créer des sous-répertoires strates au sein de chaque
# répertoire de produit-unité observé
# - en cas de plusieurs variables, formuler comme suit: c("var1", "var2")
# - en cas d'une seule variable formuler comme un texte: "var1"
variables_strate <- c("s00q01", "s00q04")

# =============================================================================
# Charger les packages requis dans les versions requises
# =============================================================================

# mettre en place toutes les dépendences pour que le programme marche 
# de la même manière chez chaque utilisateur
renv::restore()

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
    market_path = paste0(nsu_conso_donnees_sortie, "marches.dta"),
    strata_vars = variables_strate,
    dir = nsu_conso_images_sortie
)

# Puis, copier les images vers les répertoires produit-unité
nsuoutils::sort_images(
    inventory_df = produits_unites,
    data_dir = nsu_conso_donnees_sortie,
    dir_in = nsu_conso_images_entree,
    image_dir_pattern = "_Binary_",
    dir_out = nsu_conso_images_sortie,
    strata_vars = variables_strate
)

# =============================================================================
# NSU de production
# =============================================================================

# -----------------------------------------------------------------------------
# Corriger des erreurs de nom de variable et de base avant la fusion
# -----------------------------------------------------------------------------

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# identifier le répertoire où se trouve les fichiers problématiques
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

prob_dir <- fs::dir_ls(path = nsu_prod_entree, type = "directory")

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Fichiers unitesAutre
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#' Rename variables
#' 
#' Replace finale product name with "autre"
#' 
#' @param dir Character. Directory where files are stored
#' @param file Character. File name in `dir`.
rename_variables <- function(
    dir,
    file
) {

    file_path <- paste0(dir, file)

    df <- haven::read_dta(file = file_path)

    product_name <- stringr::str_extract(
        string = file, 
        pattern = "(?<=_)[a-z]+(?=\\.dta)"
    )

    df_fixed <- df |>
        dplyr::rename_with(
            .fn = ~ stringr::str_replace(
                string = .x,
                pattern = "(?<=_)[a-z]+(?=[12])",
                replacement = "autre"
            )
        ) |>
        dplyr::rename_with(
            .fn = ~ stringr::str_replace(
                string = .x,
                pattern = "(?<=unites)[a-z]+(?=[12])",
                replacement = "Autre"
            )
        )

    haven::write_dta(data = df_fixed, path = file_path)

}

#' Rename files to reflect their content
#' 
#' Replacing first occurrence of product name with "Autre"
#' 
#' @param dir Character. Directory where data files are found
#' @param pattern Character. Regular expression that identifies the files to be renamed
rename_files <- function(
  dir,
  pattern
) {

  # find file(s)
  problem_files <- fs::dir_ls(path = dir, type = "file", regexp = pattern)

  # transform file name
  # ... extracting product name
  product_name <- stringr::str_extract(string = problem_files[1], pattern = "(?<=_)[a-z]+(?=\\.dta)")
  # ... replacing its first occurrence with "Autre
  fixed_files <- stringr::str_replace(string = problem_files, pattern = product_name, replacement = "Autre")
  
  # rename files
  fs::file_move(path = problem_files, new_path = fixed_files)
  
}

#' Fix files
#' 
#' By first renaming variables and then renaming files
#' 
#' @param dir Character. Directory where data files are found
#' @param pattern Character. Regular expression that identifies the files to be renamed
fix_files <- function(dir, pattern) {

    # rename variables
    file_names <- fs::dir_ls(path = dir, type = "file", regexp = pattern) |>
        fs::path_file()

    purrr::walk(
        .x = file_names,
        .f = ~ rename_variables(
            dir = dir,
            file = .x
        )
    )

    # rename files
    rename_files(
        dir = dir,
        pattern = pattern
    )

}

# liste des fichiers problématiques dont le nom suit ce format: "unites[a-z]+[12]_[a-z]\\.dta"
prob_file_patterns <- c(
  "unitesananas[12]_ananas\\.dta",
  "unitesbanane[12]_banane\\.dta",
  "unitescanscr[12]_canscr\\.dta",
  "uniteschoufr[12]_choufr\\.dta",
  "unitesciblet[12]_ciblet\\.dta",
  "unitescitron[12]_citron\\.dta",
  "unitescotier[12]_cotier\\.dta",
  "unitescurpal[12]_curpal\\.dta",
  "unitesgoyave[12]_goyave\\.dta",
  "unitesjacq[12]_jacq\\.dta",
  "unitesnoixco[12]_noixco\\.dta",
  "unitespapaye[12]_papaye\\.dta",
  "unitespocaju[12]_pocaju\\.dta",
  "unitespompin[12]_pompin\\.dta",
  "unitestifa[12]_tifa\\.dta"
)

purrr::walk(
    .x = prob_file_patterns, 
    .f = ~ fix_files(
        dir = prob_dir,
        pattern = .x
    )
)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Fichiers unitesFixes
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#' Find unitesFixes files with problem in q105 variable name
#' 
#' @param dir Character. Directory where files are stored
#' @param file Character. File name in `dir`.
find_unites_fixes_probs <- function(
    dir,
    file
) {

    df <- haven::read_dta(paste0(data_dir, file))

    vars <- stringr::str_subset(string = names(df), pattern = "^q105autre")

    has_var <- dplyr::if_else(length(vars) == 0, true = FALSE, false = TRUE) 

    result <- tibble::tribble(
        ~ file, ~ var,
        file, has_var
    )

    return(result)

}

#' Fix q105autre variable name in unitesFixes files
#' 
#' @param dir Character. Directory where files are stored
#' @param file Character. File name in `dir`.
fix_unites_fixes <- function(
    dir,
    file
) {

    # file path
    file_path <- paste0(dir, file)

    # ingest file
    df <- haven::read_dta(file = file_path)

    # rename problem variable
    df_fixed <- df |>
        dplyr::rename_with(
            .fn = ~ stringr::str_replace(
                string = .x,
                pattern = "(?<=q105)[a-z]+(?=_)",
                replacement = "autre"
            )
        )

    # save file, overwriting original
    haven::write_dta(data = df_fixed, path = file_path)

}

# lister les fichiers unitesFixes
unites_fixes <- fs::dir_ls(path = data_dir, type = "file", regexp = "\\.dta") |>
    fs::path_file() |> stringr::str_subset(pattern = "^unitesFixes")

# obtenir la liste de ceux avec des problèmes
has_q105_problem <- unites_fixes |>
    purrr::map_dfr(
        .f = ~ find_unites_fixes_probs(
            dir = prob_dir,
            file = .x
        )
    ) |>
    dplyr::filter(var == FALSE) |>
    dplyr::pull(file)

# corriger le problème avec la variable q105autre
purrr::walk(
    .x = has_q105_problem,
    .f = ~ fix_unites_fixes(
        dir = data_dir,
        file = .x
    )
)

# -----------------------------------------------------------------------------
# Fusionner
# -----------------------------------------------------------------------------

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
