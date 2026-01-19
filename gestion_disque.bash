#!/bin/bash
rapport="./logs/rapport_nettoyage.log"
# Date d'il y a 1 an (format YYYYMMDD compatible string comparison)
limite=$(date -d "1 year ago" +%Y%m%d)

# 1. Check espace
pcent=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

# Seuil à 90%
if [ "$pcent" -ge 90 ]; then
    echo "--- Nettoyage déclenché le $(date) ---" >> "$rapport"
    echo "Taux d'occupation avant: ${pcent}%" >> "$rapport"

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
            echo "Date invalide pour $nom, ignoré." >> "$rapport"
            continue
        fi

        # Check CRITICAL dans l'archive
        is_critical=0
        if tar -Oxzf "$f" | grep -q -i "CRITICAL"; then
            is_critical=1
        fi

        
        if [ "$is_critical" -eq 0 ] || [ "$date_f" -lt "$limite" ]; then
            rm "$f" && echo "Supprimé: $nom (Critical=$is_critical, Date=$date_f)" >> "$rapport"
        fi
    done

    nouv_pcent=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    echo "Taux d'occupation après: ${nouv_pcent}%" >> "$rapport"
fi