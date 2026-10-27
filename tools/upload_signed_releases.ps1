param (
    [string]$Owner = "NetOpsSolutions",
    [string]$Repo = "Berea_Interlineal"
)

$ErrorActionPreference = "Stop"

# Obtener token de git remote o variable de entorno
$GitHubToken = $env:GITHUB_TOKEN
if (-not $GitHubToken) {
    $remote = git remote get-url origin
    if ($remote -match 'https://([^@:]+)@') {
        $GitHubToken = $matches[1]
    }
}

if (-not $GitHubToken) {
    Write-Error "No se encontro el token de GitHub."
    exit 1
}

# Ejecutar el orquestador en Python que maneja streaming eficiente y reintentos
$pythonExe = (Get-Command python -ErrorAction SilentlyContinue).Source
if ($pythonExe) {
    & python "tools\upload_all_signed_releases.py"
} else {
    Write-Error "Python no esta instalado o no se encuentra en el PATH."
    exit 1
}
