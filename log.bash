#!/bin/bash

# Definition des chemins
cheminLog="./logs/"
cheminLogArchive="./logs/archives"
cheminLogSystem="./logs/log/final.log"

# Creation du dossier archives s'il n'existe pas (bonnes pratiques)
if [ ! -d "$cheminLogArchive" ]; then
    mkdir -p "$cheminLogArchive"
fi

# Creation du fichier de log systeme s'il n'existe pas
if [ -f "$cheminLogSystem" ]; then
    echo "fichier déjà existant"
else
    # Assurer que le dossier parent existe
    mkdir -p "$(dirname "$cheminLogSystem")"
    touch "$cheminLogSystem"
fi

# Boucle sur les fichiers de log dans le dossier (ignorer les dossiers et *.tar.gz s'il y en a)
# On utilise la substitution de commande ou globbing. Attention si le dossier est vide.
for log in "$cheminLog"*.log; do
    # Si aucun fichier ne matche, on sort
    [ -e "$log" ] || continue

    nom_fichier=$(basename "$log")
    
    # Extraction de la date (format attendu: auth_YYYY-MM-DD.log)
    # On prend la partie après le dernier '_' et avant le premier '.'
    date_du_fichier=$(echo "$nom_fichier" | cut -d'_' -f2 | cut -d'.' -f1)
    
    # Dates de références
    date_il_y_a_7_jours=$(date -d "7 days ago" +%Y-%m-%d)
    date_il_y_a_30_jours=$(date -d "30 days ago" +%Y-%m-%d)

    # --- Verification 7 jours ---
    if [[ "$date_du_fichier" < "$date_il_y_a_7_jours" ]]; then
        # On archive
        echo "Archivage de $nom_fichier"
        tar -czf "${cheminLogArchive}/${nom_fichier}.tar.gz" -C "$cheminLog" "$nom_fichier"
        
        # Verification CRITICAL
        if grep -q -i "CRITICAL" "$log"; then
            echo "Impossible de supprimer le fichier (CRITICAL) : $log" >> "$cheminLogSystem"
        else
            echo "Suppression (nettoyage < 7 jours) : $log"
            rm -f "$log"
        fi
    else
        echo "$nom_fichier n'est pas vieux de 7 jours" >> "$cheminLogSystem"
    fi

    # --- Verification 30 jours (seulement si le fichier existe encore) ---
    if [ -f "$log" ]; then
        if [[ "$date_du_fichier" < "$date_il_y_a_30_jours" ]]; then
            # S'il est encore là après 30 jours, c'est qu'il était CRITICAL
            # Mais après 30 jours, on supprime même les critical ?
            # Le script original semblait vouloir dire : 
            # "Si > 30 jours et contient CRITICAL, on supprime et on log"
            
            if grep -q -i "CRITICAL" "$log"; then
                rm -f "$log"
                echo "$nom_fichier critical supprimé (expiration 30 jours)" >> "$cheminLogSystem"
            fi
        fi
    fi

done
