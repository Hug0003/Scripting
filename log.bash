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
    if [[ "$date_du_fichier" -lt "$date_il_y_a_7_jours" ]]; then
        # On archive
        echo "Archivage de $nom_fichier" >> "$cheminLogSystem"
        tar -czf "${cheminLogArchive}/${nom_fichier}.tar.gz" -C "$cheminLog" "$nom_fichier"
        
        # Verification CRITICAL
        if grep -q -i "CRITICAL" "$log"; then
            echo "Impossible de supprimer le fichier (CRITICAL) : $log" >> "$cheminLogSystem"
        else
            echo "Suppression (nettoyage < 7 jours) : $log" >> "$cheminLogSystem"
            rm -f "$log"
        fi
    else
        echo "$nom_fichier n'est pas vieux de 7 jours" >> "$cheminLogSystem"
    fi

    # --- Verification 30 jours ---
    if [ -f "$log" ]; then
        if [[ "$date_du_fichier" < "$date_il_y_a_30_jours" ]]; then
            
            if grep -q -i "CRITICAL" "$log"; then
                rm -f "$log"
                echo "$nom_fichier critical supprimé (expiration 30 jours)" >> "$cheminLogSystem"
            fi
        fi
    fi

done


# Date d'il y a 1 an (format YYYYMMDD compatible string comparison)
limite=$(date -d "1 year ago" +%Y%m%d)

# 1. Check espace
pcent=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

# Seuil à 90%
if [ "$pcent" -ge 90 ]; then
    echo "--- Nettoyage déclenché le $(date) ---" >> "$cheminLogSystem"
    echo "Taux d'occupation avant: ${pcent}%" >> "$cheminLogSystem"

    # 2. Nettoyage

    for f in ./logs/archives/*.tar.gz; do
        # Si pas de fichiers, on sort
        [ -e "$f" ] || continue

        nom=$(basename "$f")
        
        # Extraction date. 
        date_str=$(echo "$nom" | cut -d'_' -f2 | cut -d'.' -f1)
        
        # Conversion YYYYMMDD pour comparaison
        date_f=$(date -d "$date_str" +%Y%m%d 2>/dev/null)

        # Si date invalide, on skip par sécurité
        if [ -z "$date_f" ]; then
            echo "Date invalide pour $nom, ignoré." >> "$cheminLogSystem"
            continue
        fi

        # Check CRITICAL dans l'archive
        is_critical=0
        if tar -Oxzf "$f" | grep -q -i "CRITICAL"; then
            is_critical=1
        fi

        
        if [ "$is_critical" -eq 0 ] || [ "$date_f" -lt "$limite" ]; then
            rm "$f" && echo "Supprimé: $nom (Critical=$is_critical, Date=$date_f)" >> "$cheminLogSystem"
        fi
    done

    nouv_pcent=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    echo "Taux d'occupation après: ${nouv_pcent}%" >> "$cheminLogSystem"
fi