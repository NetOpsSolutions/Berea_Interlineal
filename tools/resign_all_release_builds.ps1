param (
    [string]$KeystorePath = "android\berea-release.jks",
    [string]$KeyAlias = "berea_key",
    [string]$KeystorePassword = "BereaInterlineal#2026@ProductionSecure"
)

$ErrorActionPreference = "Stop"

$ZipAlign = "C:\Users\User\AppData\Local\Android\Sdk\build-tools\36.0.0\zipalign.exe"
$ApkSigner = "C:\Users\User\AppData\Local\Android\Sdk\build-tools\36.0.0\apksigner.bat"
$BaseDir = "release_builds"

if (-not (Test-Path $KeystorePath)) {
    Write-Error "No se encontro el keystore en: $KeystorePath"
    exit 1
}

$Versions = @("v1.3.0", "v1.3.1", "v1.3.2")

foreach ($Ver in $Versions) {
    $TargetFolder = Join-Path $BaseDir $Ver
    if (-not (Test-Path $TargetFolder)) { 
        Write-Host "Omitiendo $TargetFolder (no existe)" -ForegroundColor Gray
        continue 
    }
    
    Write-Host "`n=======================================================" -ForegroundColor Yellow
    Write-Host " Procesando version: $Ver en $TargetFolder" -ForegroundColor Yellow
    Write-Host "=======================================================" -ForegroundColor Yellow

    $ApkFiles = Get-ChildItem -Path $TargetFolder -Filter "*.apk"
    foreach ($Apk in $ApkFiles) {
        $SourceFile = $Apk.FullName
        $TempAligned = "$SourceFile.aligned.tmp"
        
        Write-Host "`n[APK] $($Apk.Name)" -ForegroundColor Cyan
        Write-Host "  1. Alineando con zipalign (4 bytes / 4KB page align)..." -ForegroundColor DarkCyan
        & $ZipAlign -f -p 4 $SourceFile $TempAligned
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Fallo zipalign en $($Apk.Name)"
            exit 1
        }
        
        Write-Host "  2. Refirmando con apksigner (v1, v2 y v3)..." -ForegroundColor DarkCyan
        & $ApkSigner sign --ks $KeystorePath `
            --ks-key-alias $KeyAlias `
            --ks-pass "pass:$KeystorePassword" `
            --min-sdk-version 21 `
            --v1-signing-enabled true `
            --v2-signing-enabled true `
            --v3-signing-enabled true `
            --v4-signing-enabled false `
            --out $SourceFile $TempAligned

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Fallo apksigner en $($Apk.Name)"
            exit 1
        }
            
        Remove-Item $TempAligned -Force -ErrorAction SilentlyContinue

        Write-Host "  3. Verificando firma digital con apksigner verify..." -ForegroundColor DarkGreen
        $verifyOutput = & $ApkSigner verify --verbose --print-certs $SourceFile 2>&1
        $sha256Match = $verifyOutput | Select-String "certificate SHA-256 digest: ([0-9a-fA-F]+)"
        if ($sha256Match) {
            Write-Host "  [OK] Certificado verificado: SHA-256 = $($sha256Match.Matches[0].Groups[1].Value)" -ForegroundColor Green
        } else {
            Write-Host "  [VERIFICACION]:" -ForegroundColor Gray
            $verifyOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        }

        # Actualizar .sha1 individuales si existen (como en v1.3.0)
        $Sha1File = "$SourceFile.sha1"
        if (Test-Path $Sha1File) {
            $sha1Hash = (Get-FileHash -Path $SourceFile -Algorithm SHA1).Hash.ToLower()
            [System.IO.File]::WriteAllText($Sha1File, $sha1Hash)
            Write-Host "  [OK] Actualizado $Sha1File" -ForegroundColor DarkGray
        }
    }

    # 4. Regenerar checksums.txt para el Release
    Write-Host "`n  4. Regenerando checksums.txt para $Ver..." -ForegroundColor Magenta
    $ChecksumFile = Join-Path $TargetFolder "checksums.txt"
    $lines = @()
    
    if ($Ver -eq "v1.3.0") {
        $lines = Get-ChildItem -Path $TargetFolder -Filter "*.apk" | ForEach-Object {
            $hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash.ToUpper()
            "$hash  $($_.Name)"
        }
    } elseif ($Ver -eq "v1.3.1") {
        $lines += "# Logos K Logos v1.3.1+5 -- SHA-256 Checksums"
        $lines += "# Generado automaticamente por tools/resign_all_release_builds.ps1"
        $lines += ""
        $lines += Get-ChildItem -Path $TargetFolder -Filter "*.apk" | ForEach-Object {
            $hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash.ToLower()
            $sizeMb = [math]::Round($_.Length / 1MB, 1)
            "$hash  $($_.Name)  ($sizeMb MB)"
        }
    } elseif ($Ver -eq "v1.3.2") {
        $lines += "# Berea Interlineal v1.3.2+7 -- SHA-256 Checksums"
        $lines += "# Generado automaticamente por tools/resign_all_release_builds.ps1"
        $lines += ""
        $lines += Get-ChildItem -Path $TargetFolder -Filter "*.apk" | ForEach-Object {
            $hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash.ToLower()
            $sizeMb = [math]::Round($_.Length / 1MB, 1)
            "$hash  $($_.Name)  ($sizeMb MB)"
        }
    }
    
    [System.IO.File]::WriteAllLines($ChecksumFile, $lines, [System.Text.Encoding]::UTF8)
    Write-Host "  [OK] $ChecksumFile actualizado con exito." -ForegroundColor Green
}

Write-Host "`n=======================================================" -ForegroundColor Green
Write-Host " Refirmado completado con exito para todas las versiones locales!" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
