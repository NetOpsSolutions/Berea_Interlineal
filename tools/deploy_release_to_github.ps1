# Script: tools/deploy_release_to_github.ps1
# Automatiza la sustitucion de APKs estandarizados y checksums.txt en GitHub Releases
# preservando artefactos iOS (.ipa / .ipa.sha256) y sincronizando la tabla SHA-256 del Release.
param (
    [Parameter(Mandatory=$true)]
    [string]$VersionTag, # Ej: "1.3.0", "1.3.1", "1.3.2" o "v1.3.2"
    [string]$Owner = "NetOpsSolutions",
    [string]$Repo = "Berea_Interlineal",
    [string]$GitHubToken = $env:GITHUB_TOKEN,
    [switch]$ReplaceIpa = $false
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ([string]::IsNullOrWhiteSpace($GitHubToken)) {
    try {
        $RemoteUrl = (git remote get-url origin 2>$null).Trim()
        if ($RemoteUrl -match 'https://([^@:]+)@') {
            $GitHubToken = $Matches[1]
        }
    } catch {}
}

if ([string]::IsNullOrWhiteSpace($GitHubToken)) {
    Write-Error "No se encontro GITHUB_TOKEN ni credenciales en 'git remote get-url origin'."
    exit 1
}

$CleanVer = $VersionTag.TrimStart('v')
$LocalFolder = "release_builds/v$CleanVer"
if (-not (Test-Path $LocalFolder)) {
    Write-Error "No se encontro la carpeta local: $LocalFolder"
    exit 1
}

$Headers = @{
    "Authorization" = "Bearer $GitHubToken"
    "Accept"        = "application/vnd.github+json"
    "User-Agent"    = "Berea-Release-Deployer"
}

$CandidateTags = @($VersionTag, "v$CleanVer", $CleanVer) | Select-Object -Unique
$Release = $null
$ResolvedTag = $null

foreach ($Candidate in $CandidateTags) {
    try {
        Write-Host "Consultando Release en GitHub para el tag '$Candidate'..." -ForegroundColor Cyan
        $Url = "https://api.github.com/repos/$Owner/$Repo/releases/tags/$Candidate"
        $Resp = Invoke-WebRequest -Uri $Url -Headers $Headers -Method Get -UseBasicParsing
        $JsonText = [System.Text.Encoding]::UTF8.GetString($Resp.RawContentStream.ToArray())
        $Release = $JsonText | ConvertFrom-Json
        $ResolvedTag = $Candidate
        break
    } catch {
        # Probar siguiente variante
    }
}

if ($null -eq $Release) {
    Write-Error "No se encontro ningun Release en GitHub para las variantes de tag: $($CandidateTags -join ', ')"
    exit 1
}

$ReleaseId = $Release.id
$UploadUrlBase = $Release.upload_url -replace '\{\?name,label\}', ''
Write-Host "[OK] Release encontrado: '$($Release.name)' (ID: $ReleaseId, Tag: $ResolvedTag)" -ForegroundColor Green

# 1. Eliminar assets Android/checksum antiguos (preservando .ipa / .ipa.sha256 salvo -ReplaceIpa)
Write-Host "`n1. Eliminando assets Android/checksum obsoletos..." -ForegroundColor Yellow
$PreservedIpaName = $null
foreach ($Asset in $Release.assets) {
    $AssetName = $Asset.name
    $IsIpaAsset = ($AssetName -like "*.ipa") -or ($AssetName -like "*.ipa.sha256")
    if ($IsIpaAsset -and (-not $ReplaceIpa)) {
        if ($AssetName -like "*.ipa") {
            $PreservedIpaName = $AssetName
        }
        Write-Host "  [PRESERVADO iOS] $AssetName" -ForegroundColor DarkGray
        continue
    }
    Write-Host "  - Borrando $AssetName (ID: $($Asset.id))..." -ForegroundColor Yellow
    Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/releases/assets/$($Asset.id)" -Headers $Headers -Method Delete | Out-Null
    Start-Sleep -Milliseconds 300
}

# 2. Subir binarios oficiales con la firma de produccion + checksums.txt
Write-Host "`n2. Subiendo paquetes oficiales Berea Interlineal v$CleanVer..." -ForegroundColor Cyan
$LocalFiles = Get-ChildItem -Path $LocalFolder -File | Where-Object {
    if ($ReplaceIpa) {
        $_.Extension -in @(".apk", ".ipa") -or $_.Name -in @("checksums.txt") -or $_.Name -like "*.ipa.sha256"
    } else {
        $_.Extension -eq ".apk" -or $_.Name -eq "checksums.txt"
    }
} | Sort-Object Name

foreach ($File in $LocalFiles) {
    $SizeMb = [math]::Round($File.Length / 1MB, 2)
    $ContentType = if ($File.Extension -eq ".apk") {
        "application/vnd.android.package-archive"
    } elseif ($File.Name -eq "checksums.txt" -or $File.Name -like "*.sha256") {
        "text/plain; charset=utf-8"
    } else {
        "application/octet-stream"
    }

    Write-Host "  [SUBIENDO] $($File.Name) ($SizeMb MB)..." -ForegroundColor Green
    $EscapedName = [uri]::EscapeDataString($File.Name)
    $UploadUri = "${UploadUrlBase}?name=${EscapedName}"
    $FileBytes = [System.IO.File]::ReadAllBytes($File.FullName)

    $Uploaded = $null
    for ($Attempt = 1; $Attempt -le 3; $Attempt++) {
        try {
            $Uploaded = Invoke-RestMethod -Uri $UploadUri -Headers @{
                "Authorization" = "Bearer $GitHubToken"
                "Accept"        = "application/vnd.github+json"
                "Content-Type"  = $ContentType
                "User-Agent"    = "Berea-Release-Deployer"
            } -Method Post -Body $FileBytes -TimeoutSec 300
            break
        } catch {
            Write-Host "    [Reintento $Attempt/3] Error al subir $($File.Name): $($_.Exception.Message)" -ForegroundColor Yellow
            if ($Attempt -eq 3) { throw }
            Start-Sleep -Seconds 2
        }
    }
    Write-Host "    [OK] Asset ID: $($Uploaded.id)" -ForegroundColor DarkGreen
}

# 3. Actualizar tabla de paquetes y bloque SHA-256 en el cuerpo Markdown del Release
Write-Host "`n3. Sincronizando tabla de descargas y hashes SHA-256 en notas del Release..." -ForegroundColor Cyan
$ChecksumLines = Get-Content -Path (Join-Path $LocalFolder "checksums.txt") -Encoding UTF8 | Where-Object { $_.Trim() -ne "" }

$PhoneIcon = [char]::ConvertFromUtf32(0x1F4F1)
$LockIcon  = [char]::ConvertFromUtf32(0x1F512)
$RocketIcon = [char]::ConvertFromUtf32(0x1F680)
$QueWord   = "$([char]0x00BF)Qu$([char]0x00E9)"
$MasWord   = "Mayor$([char]0x00ED)a"
$TelWord   = "tel$([char]0x00E9)fonos"
$InstalacionWord = "Instalaci$([char]0x00F3)n"
$ViaWord   = "v$([char]0x00ED)a"
$VerifWord = "Verificaci$([char]0x00F3)n"
$VersionWord = "Versi$([char]0x00F3)n"

$IpaRow = ""
if (-not [string]::IsNullOrWhiteSpace($PreservedIpaName)) {
    $IpaRow = "`n| ``$PreservedIpaName`` | iOS 15.0+ (iPhone / iPad) | $InstalacionWord en iPhone $ViaWord AltStore, Sideloadly o TrollStore |"
}

$StandardDownloadSection = @"
## $PhoneIcon $QueWord paquete descargar?
| Archivo | Plataforma / Arquitectura | Dispositivos recomendados |
|---|---|---|
| ``berea_interlineal_${CleanVer}_arm64-v8a.apk`` | Android ARM 64-bit | $MasWord de $TelWord y tablets Android modernos (2017+) |
| ``berea_interlineal_${CleanVer}_armeabi-v7a.apk`` | Android ARM 32-bit | Dispositivos Android anteriores o de 32 bits |
| ``berea_interlineal_${CleanVer}_x86_64.apk`` | Android Intel / AMD 64-bit | Emuladores Android en PC y ChromeOS |
| ``berea_interlineal_${CleanVer}_universal.apk`` | Android Universal (Multi-ABI) | Compatible con cualquier dispositivo Android |$IpaRow

---

## $LockIcon $VerifWord de Integridad (SHA-256)
``````text
$($ChecksumLines -join "`n")
``````
"@

$OriginalBody = [string]$Release.body
$SplitMarker = "## $PhoneIcon"
$SplitIdx = $OriginalBody.IndexOf($SplitMarker)
if ($SplitIdx -gt 0) {
    $PrefixBody = $OriginalBody.Substring(0, $SplitIdx).TrimEnd()
    if (-not $PrefixBody.EndsWith("---")) {
        $PrefixBody = "$PrefixBody`n`n---"
    }
    $UpdatedBody = "$PrefixBody`n`n$StandardDownloadSection"
} else {
    $UpdatedBody = "$($OriginalBody.TrimEnd())`n`n---`n`n$StandardDownloadSection"
}

if ($CleanVer -eq "1.3.0") {
    $UpdatedBody = $UpdatedBody -replace "Novedades en la $VersionWord 1\.3\.0 \(Build \d+\)", "Novedades en Berea Interlineal v1.3.0 (Build 4)"
}

$PatchPayload = @{
    body = $UpdatedBody
} | ConvertTo-Json -Depth 5

$PatchBytes = [System.Text.Encoding]::UTF8.GetBytes($PatchPayload)
Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/releases/$ReleaseId" -Headers @{
    "Authorization" = "Bearer $GitHubToken"
    "Accept"        = "application/vnd.github+json"
    "Content-Type"  = "application/json; charset=utf-8"
    "User-Agent"    = "Berea-Release-Deployer"
} -Method Patch -Body $PatchBytes | Out-Null
Write-Host "  [OK] Notas del Release sincronizadas con nombres y SHA-256 oficiales." -ForegroundColor Green

# 4. Verificacion HTTP 200 de la Release y de cada Asset publicado
Write-Host "`n4. Verificando disponibilidad HTTP 200 de todos los assets publicados..." -ForegroundColor Cyan
$RelVerifyResp = Invoke-WebRequest -Uri "https://api.github.com/repos/$Owner/$Repo/releases/$ReleaseId" -Headers $Headers -Method Get -UseBasicParsing
if ($RelVerifyResp.StatusCode -ne 200) {
    Write-Error "Verificacion del Release devolvio HTTP $($RelVerifyResp.StatusCode)"
    exit 1
}
$RelVerified = [System.Text.Encoding]::UTF8.GetString($RelVerifyResp.RawContentStream.ToArray()) | ConvertFrom-Json
foreach ($Asset in $RelVerified.assets) {
    $HeadResp = Invoke-WebRequest -Uri $Asset.browser_download_url -Method Head -MaximumRedirection 5 -UseBasicParsing
    $SizeMb = [math]::Round($Asset.size / 1MB, 2)
    if ($HeadResp.StatusCode -ne 200) {
        Write-Error "Asset $($Asset.name) devolvio HTTP $($HeadResp.StatusCode)"
        exit 1
    }
    Write-Host ("  [HTTP {0}] {1,-44} ({2,6} MB)" -f $HeadResp.StatusCode, $Asset.name, $SizeMb) -ForegroundColor Green
}

Write-Host "`nRelease v$CleanVer actualizado y verificado (HTTP 200) exitosamente en GitHub!" -ForegroundColor Green
