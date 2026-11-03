param (
    [string]$KeystorePath = "android\berea-release.jks",
    [string]$KeyPropertiesPath = "android\key.properties",
    [string]$KeyAlias = "berea_key",
    [string]$KeystorePassword = "",
    [string[]]$Versions = @("v1.3.0", "v1.3.1", "v1.3.2")
)

$ErrorActionPreference = "Stop"

# Resolver credenciales desde android/key.properties si no se pasaron explícitamente
if ([string]::IsNullOrWhiteSpace($KeystorePassword) -and (Test-Path $KeyPropertiesPath)) {
    foreach ($line in Get-Content $KeyPropertiesPath) {
        if ($line -match '^\s*storePassword\s*=\s*(.+)$') {
            $KeystorePassword = $Matches[1].Trim()
        }
        elseif ($line -match '^\s*keyAlias\s*=\s*(.+)$' -and [string]::IsNullOrWhiteSpace($KeyAlias)) {
            $KeyAlias = $Matches[1].Trim()
        }
    }
}

if ([string]::IsNullOrWhiteSpace($KeystorePassword)) {
    Write-Error "No se pudo resolver storePassword desde $KeyPropertiesPath ni por parametro."
    exit 1
}

$SdkRoot = "$env:LOCALAPPDATA\Android\Sdk\build-tools"
$LatestBuildTools = Get-ChildItem -Path $SdkRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1
$ZipAlign = Join-Path $LatestBuildTools.FullName "zipalign.exe"
$ApkSigner = Join-Path $LatestBuildTools.FullName "apksigner.bat"
$BaseDir = "release_builds"

if (-not (Test-Path $KeystorePath)) {
    Write-Error "No se encontro el keystore en: $KeystorePath"
    exit 1
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

foreach ($Ver in $Versions) {
    $TargetFolder = Join-Path $BaseDir $Ver
    if (-not (Test-Path $TargetFolder)) {
        Write-Host "Omitiendo $TargetFolder (no existe)" -ForegroundColor Gray
        continue
    }

    Write-Host "`n=======================================================" -ForegroundColor Yellow
    Write-Host " Firmando oficialmente Berea Interlineal $Ver en $TargetFolder" -ForegroundColor Yellow
    Write-Host "=======================================================" -ForegroundColor Yellow

    # Limpiar posibles residuos .sha1 o .tmp
    Get-ChildItem -Path $TargetFolder -Include "*.sha1", "*.tmp", "*.idsig" -File -ErrorAction SilentlyContinue | Remove-Item -Force

    $ApkFiles = Get-ChildItem -Path $TargetFolder -Filter "*.apk" | Sort-Object Name
    foreach ($Apk in $ApkFiles) {
        $SourceFile = $Apk.FullName
        $TempAligned = "$SourceFile.aligned.tmp"

        Write-Host "`n[APK] $($Apk.Name)" -ForegroundColor Cyan
        Write-Host "  1. Alineando a 4 bytes con zipalign (-v -f -p 4)..." -ForegroundColor DarkCyan
        & $ZipAlign -f -p 4 $SourceFile $TempAligned | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Fallo zipalign en $($Apk.Name)"
            exit 1
        }

        Write-Host "  2. Firmando con apksigner (esquemas v1, v2 y v3; v4=false)..." -ForegroundColor DarkCyan
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
            Write-Error "Fallo apksigner sign en $($Apk.Name)"
            exit 1
        }

        Remove-Item $TempAligned -Force -ErrorAction SilentlyContinue
        Remove-Item "$SourceFile.idsig" -Force -ErrorAction SilentlyContinue

        Write-Host "  3. Verificando esquemas v1, v2, v3 y certificado con apksigner verify..." -ForegroundColor DarkGreen
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $verifyOutput = (& $ApkSigner verify --min-sdk-version 21 --verbose --print-certs $SourceFile 2>&1 | Out-String)
        $verifyCode = $LASTEXITCODE
        $ErrorActionPreference = $prevEap
        if ($verifyCode -ne 0) {
            Write-Error "Fallo apksigner verify en $($Apk.Name):`n$verifyOutput"
            exit 1
        }

        $v1Ok = $verifyOutput -match "Verified using v1 scheme \(JAR signing\): true"
        $v2Ok = $verifyOutput -match "Verified using v2 scheme \(APK Signature Scheme v2\): true"
        $v3Ok = $verifyOutput -match "Verified using v3 scheme \(APK Signature Scheme v3\): true"
        if (-not ($v1Ok -and $v2Ok -and $v3Ok)) {
            Write-Error "Esquemas de firma incompletos en $($Apk.Name) (v1=$v1Ok, v2=$v2Ok, v3=$v3Ok)"
            exit 1
        }

        if ($verifyOutput -match "certificate SHA-256 digest:\s*([0-9a-fA-F]+)") {
            Write-Host "  [OK] v1+v2+v3 verificados | Cert SHA-256 = $($Matches[1])" -ForegroundColor Green
        }
    }

    # 4. Generar checksums.txt estandarizado (formato sha256sum según Sección 6)
    Write-Host "`n  4. Generando checksums.txt (SHA-256) para $Ver..." -ForegroundColor Magenta
    $ChecksumFile = Join-Path $TargetFolder "checksums.txt"
    $lines = Get-ChildItem -Path $TargetFolder -Filter "*.apk" | Sort-Object Name | ForEach-Object {
        $hash = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash
        "$hash  $($_.Name)"
    }
    [System.IO.File]::WriteAllLines($ChecksumFile, $lines, $Utf8NoBom)
    Write-Host "  [OK] $ChecksumFile generado ($($lines.Count) entradas)." -ForegroundColor Green
}

Write-Host "`n=======================================================" -ForegroundColor Green
Write-Host " Alineacion, firmado v1+v2+v3 y checksums completados!" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
