# Projet de Scripting - Gestion de Logs

Ce dépôt contient des scripts Bash pour l'automatisation de la gestion des logs et de l'espace disque.

## Structure du Projet

- `log.bash` : Script principal de gestion quotidienne des logs.
- `gestion_disque.bash` : Script de nettoyage d'urgence en cas de saturation disque.
- `logs/` : Dossier contenant les logs, les archives et le rapport d'exécution.

## Scripts

### 1. `log.bash`

Ce script est destiné à être exécuté régulièrement (ex: via cron tache planifiée).

**Fonctionnalités :**
- Vérifie les fichiers `.log` dans le dossier `./logs/`.
- **Archives** (format `.tar.gz`) les fichiers vieux de plus de **7 jours**.
- **Supprime** les fichiers originaux après archivage (sauf s'ils contiennent "CRITICAL" et sont récents).
- **Supprime définitivement** les fichiers vieux de plus de **30 jours**, même s'ils sont critiques (selon la configuration).
- Génère des logs d'exécution dans `./logs/log/final.log`.

**Utilisation :**
```bash
./log.bash
```

### 2. `gestion_disque.bash`

Ce script surveille l'espace disque et nettoie les archives si nécessaire.

**Fonctionnalités :**
- Vérifie l'espace disque sur la racine `/`.
- Si l'espace utilisé dépasse **90%** :
  - Parcourt les archives dans `./logs/archives/`.
  - Supprime les archives qui ne contiennent **PAS** le mot-clé "CRITICAL".
  - Supprime également les archives (même critiques) vieilles de plus de **1 an**.
- Génère un rapport de nettoyage dans `./logs/rapport_nettoyage.log`.

**Utilisation :**
```bash
./gestion_disque.bash
```

## Installation et Prérequis

Assurez-vous que les scripts ont les droits d'exécution :

```bash
chmod +x log.bash gestion_disque.bash
```

## Automatisation (Cron)

Exemple de configuration `crontab` pour exécuter les scripts automatiquement :

```bash
# Tous les jours à 2h00 du matin
0 2 * * * /chemin/vers/votre/projet/log.bash

# Toutes les heures (vérification disque)
0 * * * * /chemin/vers/votre/projet/gestion_disque.bash
```
