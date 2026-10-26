# 📖 Logos K Logos

**Biblia Interlineal de Estudio** — BHS Hebreo · Tischendorf Griego · Reina-Valera 1960  
Con diccionarios Strong griego y hebreo, análisis morfológico, concordancia cruzada y herramientas de estudio personal.

> 📦 Repositorio oficial: [NetOpsSolutions/Logos_K_Logos](https://github.com/NetOpsSolutions/Logos_K_Logos) · **Última versión estable:** [v1.3.1 (Descargar APK)](https://github.com/NetOpsSolutions/Logos_K_Logos/releases/tag/1.3.1) · **Distribución directa vía GitHub Releases (OTA)**

---

## ✨ Características Principales

| Módulo | Descripción |
|---|---|
| 📖 **Biblia Interlineal** | Texto hebreo (BHS) / griego (Tischendorf) con RV1960 alineados versículo a versículo |
| 🔤 **Diccionarios Strong** | 8.674 palabras griegas + 8.674 hebreas con lemma, definición, morfología y ocurrencias |
| 🔍 **Búsqueda Global** | Búsqueda simultánea en texto bíblico y diccionarios Strong |
| 🔗 **Hipervínculos Strong** | Referencias cruzadas entre palabras relacionadas táctiles y navegables |
| 🔖 **Mi Estudio Personal** | Marcadores, notas de versículo, notas Strong e historial con persistencia ACID en SQLite (`logos_user_data.db`) |
| 📚 **Modo Lectura Fluida** | Texto limpio en español con términos Strong subrayados discretamente |
| 🔄 **Actualizador OTA** | Autodetección de arquitectura CPU (`arm64-v8a`, `armeabi-v7a`, `x86_64`), descarga e instalación directa desde GitHub Releases |

---

## 🚀 Historial de Versiones

### Versión 1.3.1 (Actual) — Persistencia Real SQLite ACID + OTA Multi-Arquitectura
- **🗄️ Persistencia Real en SQLite (`logos_user_data.db`)**: Marcadores, notas de versículos, notas léxicas Strong, historial de visitas y respaldo de preferencias de interfaz ahora se almacenan en una base SQLite dedicada con transacciones ACID (`WAL` + `synchronous = FULL`), completamente independiente de la base bíblica de solo lectura.
- **🛡️ Blindaje para Producción (`--release` / R8)**: Reglas ProGuard/R8 reforzadas para `androidx.datastore` y desacoplamiento total entre SQLite y `SharedPreferences`, garantizando persistencia tras cierres forzados o reinicios del dispositivo.
- **🔁 Migrador Automático**: Importación transparente de datos previos desde `SharedPreferences` hacia SQLite sin pérdida de información.
- **🧠 Autodetección Inteligente de CPU en OTA**: Detección nativa del procesador del dispositivo para seleccionar y descargar únicamente el APK compatible (`arm64-v8a`, `armeabi-v7a`, `x86_64` o `universal`).

### Versión 1.3.0 — OTA Updater + Splash
- **🔄 Sistema de Actualización In-App (OTA)**: Detecta, descarga e instala actualizaciones directamente desde GitHub Releases sin necesidad de tiendas externas.
- **🎬 Splash Screen animado**: Logo central con animaciones, lemas de estudio y barra de progreso fluida (~1.6 s).
- **⚡ Accesos directos en Ajustes**: Toca Marcadores, Notas o Historial para abrirlos directamente.
- **🏷️ Filtros en Mi Estudio**: Chips interactivos — Todas / En versículos / En palabras Strong.

### Versión 1.2.0
- Hipervínculos táctiles en códigos Strong derivados `(con 3588)`.
- Sección "Dónde aparece" en acordeón desplegable con resaltado fluorescente.
- Modo oscuro como predeterminado del sistema con persistencia garantizada.

### Versión 1.1.0
- Marcadores de versículos, notas personales por versículo y por Strong.
- Historial de visitas automático, Modo Lectura Fluida, Búsqueda Global Unificada.

---

## 💻 Ejecutar la Aplicación

### Requisitos
- Flutter SDK 3.4+
- Android SDK / Emulador o dispositivo físico

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en emulador Android
flutter run

# Compilar APK optimizado por arquitectura (< 45 MB por ABI)
flutter build apk --split-per-abi --release

# Compilar APK universal
flutter build apk --release

# Empaquetar release multi-ABI con checksums SHA-256
python tools/collect_release.py

# Ejecutar pruebas automatizadas (15 tests)
flutter test

# Análisis estático de código
flutter analyze
```

> 📱 Para saber qué APK instalar en tu dispositivo (Galaxy, Honor, Xiaomi…) consulta [`Archivos_md/GUIA_ARQUITECTURAS_Y_DISPOSITIVOS.md`](Archivos_md/GUIA_ARQUITECTURAS_Y_DISPOSITIVOS.md)

---

## 🔄 Sistema de Actualización OTA (GitHub Releases)

La app se conecta automáticamente al endpoint público:
```
GET https://api.github.com/repos/NetOpsSolutions/Logos_K_Logos/releases/latest
```

**Flujo de actualización:**
1. Al iniciar la app (4 s después del arranque) verifica si hay nueva versión
2. Si existe → SnackBar con botón **"VER NOVEDADES"**
3. Modal elegante con notas de la versión en Markdown y barra de descarga
4. Descarga el `.apk` adjunto en la release a la caché del dispositivo
5. Invoca el instalador nativo de Android (FileProvider)

**Para publicar una nueva versión:**
1. Compila: `flutter build apk --release`
2. En GitHub → **Releases → Draft a new release**
3. Tag: `v1.3.1` · Adjunta el `.apk` generado
4. Publica → los usuarios recibirán la notificación automáticamente

---

## 📚 Dataset y Base de Datos

La base de datos SQLite (`assets/data/logos_k_logos.db`, ~73 MB, vía Git LFS) contiene:
- Todos los versículos interlineales AT/NT
- Diccionarios Strong griego y hebreo completos
- Índices optimizados para búsqueda instantánea

Para reconstruir el dataset desde cero:
```bash
pip install requests beautifulsoup4
python tools/crawl_logosklogos.py --out data/output --delay 0.8
python tools/build_assets.py --in data/output --out assets/data
```

---

## 📋 Hoja de Ruta

Consulta el [Plan de Implementación completo](Archivos_md/PLAN_IMPLEMENTACION.md) para la hoja de ruta detallada con todas las fases.

| Hito | Estado |
|---|---|
| M1: Persistencia SQLite de Usuario (`logos_user_data.db`) | ✅ Completado (v1.3.1) |
| M2: Actualizador In-App GitHub OTA + Autodetección ABI | ✅ Completado (v1.3.1) |
| M3: Depuración final de Assets (APKs por ABI ~36–40 MB) | ✅ Completado |
| M4: Difusión en WhatsApp y Redes | 🔲 Próximo |
| M5: Versículo del Día | 🔲 Pendiente |

---

## 📄 Licencias

Recursos de dominio público y licencias académicas abiertas:
- **BHS**: Biblia Hebraica Stuttgartensia
- **Tischendorf**: Texto griego del NT (dominio público)
- **RV1960**: Reina-Valera 1960
- **Strong**: Concordancia Strong (dominio público)
- **STEPBible**: Datos interlineales

---

*Desarrollado con Flutter 3.47 · Dart 3.13 · SQLite · Git LFS*
