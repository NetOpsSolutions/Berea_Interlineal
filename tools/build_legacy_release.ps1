param (
    [Parameter(Mandatory=$true)]
    [string]$VersionTag, # "1.3.0" or "1.3.1"
    [string]$AppId = "com.netopssolutions.berea_interlineal",
    [string]$KeystorePass = "BereaInterlineal#2026@ProductionSecure"
)

$ErrorActionPreference = "Stop"
$Root = (Get-Item -Path ".").FullName
$WorktreeDir = Join-Path (Split-Path $Root -Parent) "build_worktree_$($VersionTag.Replace('.', ''))"

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host " Compilando Version Legacy: $VersionTag con ID: $AppId" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

# Limpiar worktree previo si existe
if (Test-Path $WorktreeDir) {
    Write-Host "Eliminando worktree previo en $WorktreeDir..." -ForegroundColor DarkGray
    git worktree remove $WorktreeDir --force -ErrorAction SilentlyContinue
    Remove-Item $WorktreeDir -Recurse -Force -ErrorAction SilentlyContinue
}

# 1. Crear nuevo worktree
Write-Host "1. Creando git worktree para tag $VersionTag..." -ForegroundColor Cyan
git worktree add -f $WorktreeDir $VersionTag
if ($LASTEXITCODE -ne 0) {
    Write-Error "No se pudo crear el worktree para $VersionTag"
    exit 1
}

try {
    # 2. Copiar keystore y key.properties
    Write-Host "2. Copiando credenciales de firmado..." -ForegroundColor Cyan
    $srcKeystore = Join-Path $Root "android\berea-release.jks"
    $srcProperties = Join-Path $Root "android\key.properties"
    $destAndroid = Join-Path $WorktreeDir "android"
    
    Copy-Item $srcKeystore (Join-Path $destAndroid "berea-release.jks") -Force
    Copy-Item $srcProperties (Join-Path $destAndroid "key.properties") -Force

    # 3. Modificar build.gradle.kts
    Write-Host "3. Modificando build.gradle.kts para $AppId y signing release..." -ForegroundColor Cyan
    $gradleKts = Join-Path $WorktreeDir "android\app\build.gradle.kts"
    $gradleContent = Get-Content $gradleKts -Raw -Encoding utf8
    
    # Inyectar lectura de key.properties si no esta
    if ($gradleContent -notmatch "keystoreProperties") {
        $header = @"
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

"@
        $gradleContent = $header + $gradleContent
    }
    
    # Inyectar signingConfigs.create("release") si no esta
    if ($gradleContent -notmatch 'create\("release"\)') {
        $signingBlock = @"
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { 
                val f = file(it)
                if (f.exists()) f else rootProject.file(it)
            }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
"@
        $gradleContent = $gradleContent -replace 'android \{', "android {`n$signingBlock"
    }

    # Cambiar namespace y applicationId
    $gradleContent = $gradleContent -replace 'namespace\s*=\s*"[^"]+"', "namespace = `"$AppId`""
    $gradleContent = $gradleContent -replace 'applicationId\s*=\s*"[^"]+"', "applicationId = `"$AppId`""
    
    # Asignar signingConfig release
    $gradleContent = $gradleContent -replace 'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)', 'signingConfig = signingConfigs.getByName("release")'
    
    [System.IO.File]::WriteAllText($gradleKts, $gradleContent, [System.Text.Encoding]::UTF8)

    # 4. Reubicar MainActivity.kt
    Write-Host "4. Reubicando MainActivity.kt al nuevo paquete..." -ForegroundColor Cyan
    $oldKotlinDir = Join-Path $WorktreeDir "android\app\src\main\kotlin\com\example"
    $newKotlinDir = Join-Path $WorktreeDir "android\app\src\main\kotlin\com\netopssolutions\berea_interlineal"
    New-Item -ItemType Directory -Path $newKotlinDir -Force | Out-Null
    
    $oldMainActivity = Join-Path $WorktreeDir "android\app\src\main\kotlin\com\example\logos_k_logos\MainActivity.kt"
    if (Test-Path $oldMainActivity) {
        $ktContent = Get-Content $oldMainActivity -Raw -Encoding utf8
        $ktContent = $ktContent -replace 'package com\.example\.logos_k_logos', "package $AppId"
        $ktContent = $ktContent -replace '"com\.example\.logos_k_logos/updater"', "`"$AppId/updater`""
        $ktContent = $ktContent -replace '"com\.example\.logos_k_logos\.ACTION_OPEN_OTA_UPDATE"', "`"$AppId.ACTION_OPEN_OTA_UPDATE`""
        [System.IO.File]::WriteAllText((Join-Path $newKotlinDir "MainActivity.kt"), $ktContent, [System.Text.Encoding]::UTF8)
        Remove-Item $oldKotlinDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # 5. Actualizar update_service.dart si existe
    $updateDart = Join-Path $WorktreeDir "lib\core\update\update_service.dart"
    if (Test-Path $updateDart) {
        Write-Host "5. Actualizando canal OTA en update_service.dart..." -ForegroundColor Cyan
        $dartContent = Get-Content $updateDart -Raw -Encoding utf8
        $dartContent = $dartContent -replace "MethodChannel\('com\.example\.logos_k_logos/updater'\)", "MethodChannel('$AppId/updater')"
        [System.IO.File]::WriteAllText($updateDart, $dartContent, [System.Text.Encoding]::UTF8)
    }

    # 6. Compilar split APKs y Universal APK
    Write-Host "6. Ejecutando flutter build apk --split-per-abi..." -ForegroundColor Green
    Push-Location $WorktreeDir
    flutter build apk --release --split-per-abi
    if ($LASTEXITCODE -ne 0) { throw "Error al compilar split APKs para $VersionTag" }

    Write-Host "7. Ejecutando flutter build apk --release (universal)..." -ForegroundColor Green
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw "Error al compilar universal APK para $VersionTag" }
    Pop-Location

    # 8. Copiar APKs a release_builds/v$VersionTag/
    Write-Host "8. Copiando artefactos a release_builds/v$VersionTag..." -ForegroundColor Magenta
    $apkOutputs = Join-Path $WorktreeDir "build\app\outputs\flutter-apk"
    $destFolder = Join-Path $Root "release_builds\v$VersionTag"
    if (-not (Test-Path $destFolder)) { New-Item -ItemType Directory -Path $destFolder -Force | Out-Null }

    if ($VersionTag -eq "1.3.0") {
        Copy-Item (Join-Path $apkOutputs "app-arm64-v8a-release.apk") (Join-Path $destFolder "app-arm64-v8a-release.apk") -Force
        Copy-Item (Join-Path $apkOutputs "app-armeabi-v7a-release.apk") (Join-Path $destFolder "app-armeabi-v7a-release.apk") -Force
        Copy-Item (Join-Path $apkOutputs "app-x86_64-release.apk") (Join-Path $destFolder "app-x86_64-release.apk") -Force
        Copy-Item (Join-Path $apkOutputs "app-release.apk") (Join-Path $destFolder "app-release.apk") -Force
        Copy-Item (Join-Path $apkOutputs "app-release.apk") (Join-Path $destFolder "app-universal-release.apk") -Force
    } elseif ($VersionTag -eq "1.3.1") {
        Copy-Item (Join-Path $apkOutputs "app-arm64-v8a-release.apk") (Join-Path $destFolder "logos_k_logos_1.3.1_arm64-v8a.apk") -Force
        Copy-Item (Join-Path $apkOutputs "app-armeabi-v7a-release.apk") (Join-Path $destFolder "logos_k_logos_1.3.1_armeabi-v7a.apk") -Force
        Copy-Item (Join-Path $apkOutputs "app-x86_64-release.apk") (Join-Path $destFolder "logos_k_logos_1.3.1_x86_64.apk") -Force
        Copy-Item (Join-Path $apkOutputs "app-release.apk") (Join-Path $destFolder "logos_k_logos_1.3.1_universal.apk") -Force
    }
    
    Write-Host "[EXITO] Version $VersionTag empaquetada con exito en $destFolder" -ForegroundColor Green
}
finally {
    if (Get-Location -eq $WorktreeDir) { Pop-Location }
    Write-Host "Limpiando worktree temporal..." -ForegroundColor DarkGray
    git worktree remove $WorktreeDir --force -ErrorAction SilentlyContinue
    if (Test-Path $WorktreeDir) { Remove-Item $WorktreeDir -Recurse -Force -ErrorAction SilentlyContinue }
}
