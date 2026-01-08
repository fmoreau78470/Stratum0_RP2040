# Script pour définir la version du firmware Stratum0
# Utilisation :
#   .\Set-Version.ps1 -Version 1.2.0  (Force une version)
#   .\Set-Version.ps1                 (Incrémente le Patch automatiquement)

param(
    [Parameter(Mandatory=$false)]
    [string]$Version
)

# --- Chemin du fichier de version ---
# Utilise le chemin absolu du dossier du script pour cibler src\version.h
$versionHeaderPath = Join-Path $PSScriptRoot "src\version.h"

if (-not (Test-Path $versionHeaderPath)) {
    Write-Host "Le fichier '$versionHeaderPath' est introuvable. Création d'un fichier par défaut." -ForegroundColor Yellow
    $initialContent = '#pragma once' + [System.Environment]::NewLine + '#define VERSION "0.0.0"'
    $dir = Split-Path -Path $versionHeaderPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
    Set-Content -Path $versionHeaderPath -Value $initialContent
}

# --- Logique d'auto-incrémentation ---
if ([string]::IsNullOrWhiteSpace($Version)) {
    $content = Get-Content $versionHeaderPath -Raw
    if ($content -match '(?m)^#define\s+VERSION\s+"(\d+)\.(\d+)\.(\d+)"') {
        $currentVersion = "$($matches[1]).$($matches[2]).$($matches[3])"
        $newPatch = [int]$matches[3] + 1
        $Version = "$($matches[1]).$($matches[2]).$newPatch"
        Write-Host "Auto-incrémentation du firmware : $currentVersion -> $Version" -ForegroundColor Yellow
    } elseif ($content -match '(?m)^\s*(\d+)\.(\d+)\.(\d+)\s*$') {
        $currentVersion = "$($matches[1]).$($matches[2]).$($matches[3])"
        $newPatch = [int]$matches[3] + 1
        $Version = "$($matches[1]).$($matches[2]).$newPatch"
        Write-Host "Réparation et incrémentation du fichier version.h malformé : $currentVersion -> $Version" -ForegroundColor Yellow
    } else {
        Write-Error "Impossible de lire la version actuelle depuis $versionHeaderPath pour l'incrémenter."
        exit 1
    }
}

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Error "Le format de la version doit être X.Y.Z (ex: 1.2.0). Fourni : $Version"
    exit 1
}

Write-Host "Mise à jour du firmware vers la version $Version..." -ForegroundColor Cyan

# --- Mise à jour du fichier version.h ---
# On écrase le fichier pour garantir le format correct et corriger toute corruption
$newContent = '#pragma once' + [System.Environment]::NewLine + "#define VERSION `"$Version`""
Set-Content -Path $versionHeaderPath -Value $newContent
Write-Host "$versionHeaderPath mis à jour." -ForegroundColor Green

Write-Host "Versionning du firmware terminé pour v$Version." -ForegroundColor Cyan