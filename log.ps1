$cheminlog = "./logs/"
$cheminLogArchive = "./logs/archives"
$cheminLogSystem = "./logs/log/final.log"
 
if (Test-Path $cheminLogArchive) {
    Add-Content -Path $cheminLogSystem -Value "Le dossier archives existe déjà"
}
else {
    New-Item -ItemType Directory -Force -Path $cheminLogArchive | Out-Null
    Add-Content -Path $cheminLogSystem -Value "Dossier archives créé"
}

if (Test-Path $cheminLogSystem) {
    Add-Content -Path $cheminLogSystem -Value "fichier déjà existant"
}
else {
    $parentLogDir = Split-Path $cheminLogSystem -Parent
    if (-not (Test-Path $parentLogDir)) {
        New-Item -ItemType Directory -Force -Path $parentLogDir | Out-Null
    }
    New-Item -ItemType File -Path $cheminLogSystem -Force | Out-Null
    Add-Content -Path $cheminLogSystem -Value "Fichier log système créé"
}
 
foreach ($log in $cheminlog) {
    #definition de nos variables
    $chemin_complet = "$cheminlog\$log"
    $nom_fichier = $log.Name
    $date_du_fichier = $log.split('_')[1].split('.')[0]
    $date_il_y_a_7_jours = (Get-Date).AddDays(-7)
    $date_il_y_a_30_jours = (Get-Date).AddDays(-30)
 
    if ($date_du_fichier -lt $date_il_y_a_7_jours) {
 
        Add-Content -Path $cheminLogSystem -Value "Archivage de $nom_fichier"
        $nomArchive = "$cheminLogArchive\$nom_fichier.tar.gz"
        tar -czf $nomArchive -C $cheminlog $nom_fichier
 
        if (Select-String -Path $chemin_complet -Pattern "CRITICAL" -Quiet) {
            Add-Content -Path $cheminLogSystem -Value "Impossible de supprimer le fichier (CRITICAL) : $chemin_complet"
        }
        else {
 
            Add-Content -Path $cheminLogSystem -Value "suppression de $nom_fichier car il est vieux de plus de 7 jours"
            Remove-Item -Path $chemin_complet
        }
    }
 
    if ($date_du_fichier -lt $date_il_y_a_30_jours) {
 
        # Si le fichier existe encore (donc critical), on le supprime quand même après 30 jours
        if (Test-Path $chemin_complet) {
            Add-Content -Path $cheminLogSystem -Value "suppression du fichier (CRITICAL) $nom_fichier car il est vieux de plus de 30 jours"
            Remove-Item -Path $chemin_complet
        }
    }
   
 
}
  

$limite = (Get-Date).AddYears(-1)
 
$infoDisque = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$espaceOccupe = $infoDisque.Size - $infoDisque.FreeSpace
$pourcentage = [math]::Round(($espaceOccupe / $infoDisque.Size) * 100)
 
# si plus de 90% d'espace utilisé
if ($pourcentage -gt 90) {
    Add-Content -Path $cheminLogSystem -Value "Netoyage déclenché le $(Get-Date)"
    Add-Content -Path $cheminLogSystem -Value "taux d'occupation avant: $pourcentage`%"
 
 
    foreach ($fichier in Get-ChildItem -Path "./logs/archives/" -Filter "*.zip") {
        $date_du_fichier = $log.split('_')[1].split('.')[0]
        $date_objet = [datetime]::ParseExact($date_du_fichier, "yyyy-MM-dd", $null)
        # si on  est repassé sous les 90% donc on arrete
        if ($pcentActuel -le 90) {
            break
        }
 
           
 
        $dossierTemp = ".\temp_check_$nom"
        Expand-Archive -Path $cheminComplet -DestinationPath $dossierTemp -Force
        $estCritique = Select-String -Path "$dossierTemp\*" -Pattern "CRITICAL" -Quiet
        Remove-Item -Path $dossierTemp -Recurse -Force
 
        #definition de la variable de suppréssion
        $doitSupprimer = $false
 
        if (-not  ($estCritique)) {
            $doitSupprimer = $true
 
        }
           
        elseif ($estCritique -and $date_objet -lt $limite) {
            Write-Host "Suppression de l'archive $($fichier.Name) car elle est plus vieille qu'un an"
            Remove-Item -Path $fichier.FullName  
        }
        if ($doitSupprimer) {
            Remove-Item -Path $fichier.FullName -Force
            Add-Content -Path $cheminLogSystem -Value "Supprimé : $($fichier.Name)"
        }
           
 
   
    }
   
    $infoApres = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    $pcentApres = [math]::Round((($infoApres.Size - $infoApres.FreeSpace) / $infoApres.Size) * 100)
    Add-Content -Path $cheminLogSystem -Value "Taux d'occupation après: $pcentApres %"
 
 
}
 