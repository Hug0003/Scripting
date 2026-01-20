# Augustin LAGRANGE & Hugo MEURIEL

# Projet de Scripting - Gestion de Logs

Ce dépôt contient des scripts Bash pour l'automatisation de la gestion des logs et de l'espace disque.

## Entrées
- Emplacement : `/logs/`
- Format de nommage : `<service>_<YYYY-MM-DD>.log`
- Niveaux de log : `Info`, `Error`, `Warning`, `Critical`

## Sorties
- Emplacement : `/logs/archive/`
- Format de nommage : `<service>_<YYYY-MM-DD>.gz`
- Règle d'archivage :
    - Logs standards : archivage après 7 jours.
    - Logs Critical : archivage après 30 jours.
- Fichier de log du traitement



## Pseudo-script
Récupérer les fichiers logs dans le dossiers /logs/
boucle sur le tous les fichiers de logs 
check la date des logs dans /logs/ pour voir si ça fait plus de 7 jours qui sont là:
	si oui : on le compresse en .gz on le copie colle dans /logs/archives et on met 
		le nom du fichier dans le fichier final
		check si : il y a une erreur critique dans le log: 
			si oui : on ne fait rien
			si non : on supprime le log dans /logs et mettre le nom des 
                                                fichier supprimé dans le fichier final 
	si non : on ne fait rien

check la date des logs dans /logs/ pour voir si ça fait plus de 30 jours que des fichiers CRITICAL sont là
	si oui : on le supprime et mettre le nom des fichier supprimé dans le fichier final
	sinon on ne fait rien

Si espace disk > 90%
	check la date des fichiers logs archivé dans le dossier /logs/archives pour voir si c’est le plus vieux et ( ce n’est pas un fichier CRITICAL qui a moins de 1 an)
		si oui : supprimer les fichiers et mettre le nom des fichier supprimé et l’état avant et après suppression de l’espace disque dans le fichier final
		si non : mettre l’état avant et après suppression de l’espace disque dans le fichier final




## Cas d’erreur / limites
Si jamais il y a trop de log critique de moins de 1 ans et de logs de moins de 7 jours cela crée la surcharge de l’espace de stockage. 




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

```bash
# Tous les jours à 2h00 du matin
0 2 * * * /chemin/vers/votre/projet/log.bash

# Toutes les heures (vérification disque)
0 * * * * /chemin/vers/votre/projet/gestion_disque.bash
```

## génération des logs
Grâce au script python : script.py