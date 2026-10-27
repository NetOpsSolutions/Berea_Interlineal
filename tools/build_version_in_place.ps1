param (
    [Parameter(Mandatory=$true)]
    [string]$VersionTag, # "1.3.1" or "1.3.0"
    [string]$AppId = "com.netopssolutions.berea_interlineal"
)

$ErrorActionPreference = "Stop"
$TempBranch = "temp_build_$($VersionTag.Replace('.', ''))"

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host " Compilando Version $VersionTag in-place con ID: $AppId" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

# Asegurar volver a master en caso de error
try {
    # 1. Crear y pasar a la rama temporal desde el tag
    Write-Host "1. Creando rama temporal $TempBranch desde tag $VersionTag..." -ForegroundColor Cyan
    git checkout -B $TempBranch $VersionTag
    if ($LASTEXITCODE -ne 0) { throw "Error al hacer checkout a $VersionTag" }

    # 2. Configurar android/app/build.gradle.kts
    Write-Host "2. Configurando build.gradle.kts con signing release y AppId $AppId..." -ForegroundColor Cyan
    $gradleKts = "android\app\build.gradle.kts"
    $gradleContent = Get-Content $gradleKts -Raw -Encoding utf8

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

    $gradleContent = $gradleContent -replace 'namespace\s*=\s*"[^"]+"', "namespace = `"$AppId`""
    $gradleContent = $gradleContent -replace 'applicationId\s*=\s*"[^"]+"', "applicationId = `"$AppId`""
    $gradleContent = $gradleContent -replace 'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)', 'signingConfig = signingConfigs.getByName("release")'

    [System.IO.File]::WriteAllText($gradleKts, $gradleContent, [System.Text.Encoding]::UTF8)

    # 3. Reubicar MainActivity.kt
    Write-Host "3. Reubicando MainActivity.kt al paquete $AppId..." -ForegroundColor Cyan
    $newKotlinDir = "android\app\src\main\kotlin\com\netopssolutions\berea_interlineal"
    New-Item -ItemType Directory -Path $newKotlinDir -Force | Out-Null
    
    $oldMainActivity = "android\app\src\main\kotlin\com\example\logos_k_logos\MainActivity.kt"
    if (Test-Path $oldMainActivity) {
        $ktContent = Get-Content $oldMainActivity -Raw -Encoding utf8
        $ktContent = $ktContent -replace 'package com\.example\.logos_k_logos', "package $AppId"
        $ktContent = $ktContent -replace '"com\.example\.logos_k_logos/updater"', "`"$AppId/updater`""
        $ktContent = $ktContent -replace '"logos_ota_updates"', '"berea_ota_updates"'
        $ktContent = $ktContent -replace '"com\.example\.logos_k_logos\.ACTION_OPEN_OTA_UPDATE"', "`"$AppId.ACTION_OPEN_OTA_UPDATE`""
        [System.IO.File]::WriteAllText((Join-Path $newKotlinDir "MainActivity.kt"), $ktContent, [System.Text.Encoding]::UTF8)
        Remove-Item "android\app\src\main\kotlin\com\example" -Recurse -Force -ErrorAction SilentlyContinue
    }

    # 4. Actualizar canal OTA en update_service.dart si existe
    $updateDart = "lib\core\update\update_service.dart"
    if (Test-Path $updateDart) {
        Write-Host "4. Actualizando canal en update_service.dart..." -ForegroundColor Cyan
        $dartContent = Get-Content $updateDart -Raw -Encoding utf8
        $dartContent = $dartContent -replace "MethodChannel\('com\.example\.logos_k_logos/updater'\)", "MethodChannel('$AppId/updater')"
        [System.IO.File]::WriteAllText($updateDart, $dartContent, [System.Text.Encoding]::UTF8)
    }

    # 5. Compilar split APKs y Universal
    Write-Host "5. Compilando split APKs para $VersionTag..." -ForegroundColor Green
    flutter build apk --release --split-per-abi
    if ($LASTEXITCODE -ne 0) { throw "Fallo flutter build split-per-abi para $VersionTag" }

    Write-Host "6. Compilando universal APK para $VersionTag..." -ForegroundColor Green
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw "Fallo flutter build release universal para $VersionTag" }

    # 7. Copiar a release_builds/v$VersionTag/
    Write-Host "7. Copiando artefactos a release_builds/v$VersionTag..." -ForegroundColor Magenta
    $apkOutputs = "build\app\outputs\flutter-apk"
    $destFolder = "release_builds\v$VersionTag"
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

    Write-Host "[EXITO] Compilacion de $VersionTag completada con exito!" -ForegroundColor Green
}
finally {
    Write-Host "8. Regresando a la rama master..." -ForegroundColor DarkGray
    git checkout -f master
    git branch -D $TempBranch
}
