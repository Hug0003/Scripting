import os
import random
from datetime import datetime, timedelta

# --- Configuration ---
OUTPUT_DIR = "logs_test"
SERVICES = ["api", "auth", "payment"]
LEVELS = ["INFO", "WARNING", "ERROR", "CRITICAL"]
# Date de fin : Aujourd'hui (simulation basée sur votre date : 19 Jan 2026)
END_DATE = datetime(2026, 1, 19) 
# Durée : 1 an et 1 mois (approx 395 jours)
DURATION_DAYS = 395 

# Messages types pour le réalisme
MESSAGES = {
    "INFO": ["Démarrage session", "Requête reçue", "Ping service", "Utilisateur déconnecté"],
    "WARNING": ["Temps de réponse élevé", "API dépréciée utilisée", "Tentative de reconnexion"],
    "ERROR": ["Échec de connexion DB", "Fichier introuvable", "Timeout requête externe"],
    "CRITICAL": ["Service arrêté inopinément", "CORRUPTION DE DONNÉES", "Disque plein"]
}

def generate_log_content():
    """Génère entre 5 et 20 lignes de logs aléatoires pour un fichier."""
    lines = []
    for _ in range(random.randint(5, 20)):
        level = random.choices(LEVELS, weights=[50, 30, 15, 5])[0] # Pondération (plus d'INFO que de CRITICAL)
        msg = random.choice(MESSAGES[level])
        timestamp = datetime.now().strftime("%H:%M:%S")
        lines.append(f"{level} [{timestamp}] - {msg}")
    return "\n".join(lines)

def main():
    # Création du dossier
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        print(f"Dossier '{OUTPUT_DIR}' créé.")

    print(f"Génération des logs du {END_DATE.date()} jusqu'à {(END_DATE - timedelta(days=DURATION_DAYS)).date()}...")

    count = 0
    # Boucle sur chaque jour en arrière
    for i in range(DURATION_DAYS + 1):
        current_date = END_DATE - timedelta(days=i)
        date_str = current_date.strftime("%Y-%m-%d")

        for service in SERVICES:
            filename = f"{service}_{date_str}.log"
            filepath = os.path.join(OUTPUT_DIR, filename)
            
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(generate_log_content())
            count += 1

    print(f"Terminé ! {count} fichiers de logs ont été générés dans '{OUTPUT_DIR}'.")

if __name__ == "__main__":
    main()