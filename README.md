# 📖 Berea Interlineal

**Biblia Interlineal de Estudio** — BHS Hebreo · Tischendorf Griego · Reina-Valera 1960  
Con diccionarios Strong griego y hebreo, análisis morfológico, concordancia cruzada y herramientas de estudio personal.

> 📦 Repositorio oficial: [NetOpsSolutions/Berea_Interlineal](https://github.com/NetOpsSolutions/Berea_Interlineal) · **Última versión:** [v1.3.2 (Descargar APK)](https://github.com/NetOpsSolutions/Berea_Interlineal/releases/tag/v1.3.2) · **Distribución directa vía GitHub Releases (OTA)**

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
| 🎨 **Resaltadores Teológicos** | Marcado en 5 categorías teológicas (Promesas, Mandamientos, Atributos de Dios, Advertencias, Profecía) |
| 🧭 **Guía Visual Interactiva** | Recorrido guiado que se muestra una sola vez tras actualizar y accesible desde Ajustes |
| 🔄 **Actualizador OTA** | Autodetección de arquitectura CPU (`arm64-v8a`, `armeabi-v7a`, `x86_64`), descarga e instalación directa desde GitHub Releases |

---

## 🚀 Historial de Versiones

### Versión 1.3.2 (Actual) — Berea Interlineal, Guía Visual y Fase 3 UI/UX
- **✨ Transición Oficial de Identidad ("Berea Interlineal")**:
  - Nuevo logotipo oficial inspirado en Hechos 17:11 (Biblia sagrada abierta con lente exegética de aumento iluminada en oro y azul zafiro).
  - Nuevos iconos adaptativos multi-resolución para Android e iOS.
  - Migración limpia de repositorio GitHub con redirección permanente (HTTP 301) para actualizaciones automáticas desde versiones previas.
- **🧭 Guía Visual Interactiva Post-Actualización**:
  - Recorrido interactivo tipo coach-mark guiando paso a paso al usuario por las novedades principales de la aplicación.
  - Se ejecuta automáticamente una sola vez tras actualizar y se puede reiniciar en cualquier momento desde *Ajustes ➔ Ver guía de uso*.
- **📖 Lectura por Capítulo Completo (Fase 3 UI/UX)**:
  - Scroll vertical continuo del capítulo completo con expansión interlineal instantánea al pulsar cualquier versículo.
  - Gestos swipe laterales para navegación fluida entre capítulos.
- **🔤 Tipografías Académicas SIL OFL**:
  - Soporte nativo para Ezra SIL y Frank Ruhl Libre (Hebreo BHS con nikud y cantilaciones) y Cardo / Gentium Plus (Griego Koiné).
- **🎨 Resaltadores Teológicos**:
  - Marcado visual persistente en SQLite en 5 categorías temáticas.
- **🔔 Notificaciones Nativas OTA en Android**:
  - Integración directa con el Centro de Notificaciones del sistema operativo con notas de versión y confirmación interactiva.
- **🍏 Distribución iOS (.ipa)**:
  - Pipeline automatizado de GitHub Actions en runners macOS para empaquetado directo de `Berea_Interlineal_1.3.2.ipa`.

### Versión 1.3.1 — Persistencia Real SQLite ACID + OTA Multi-Arquitectura
- **🗄️ Persistencia Real en SQLite (`logos_user_data.db`)**: Marcadores, notas de versículos, notas léxicas Strong, historial de visitas y preferencias almacenadas de forma permanente.
- **🧠 Autodetección Inteligente de CPU en OTA**: Detección nativa del procesador del dispositivo para seleccionar únicamente el APK compatible.

### Versión 1.3.0 — OTA Updater + Splash
- **🔄 Sistema de Actualización In-App (OTA)**: Detección e instalación directa desde GitHub Releases.
- **🎬 Splash Screen animado**: Animaciones de inicio y barra de progreso.

---

## 💻 Compilación y Ejecución

```bash
# Instalar dependencias
flutter pub get

# Ejecutar pruebas automatizadas (20 tests)
flutter test

# Análisis estático de código
flutter analyze

# Compilar APK optimizado por arquitectura
flutter build apk --split-per-abi --release

# Compilar APK universal
flutter build apk --release

# Empaquetar artefactos para publicación
python tools/collect_release.py
```

---

## 🔄 Sistema de Actualización OTA (GitHub Releases)

La app consulta periódicamente:
```
GET https://api.github.com/repos/NetOpsSolutions/Berea_Interlineal/releases/latest
```
*Los dispositivos que tenían v1.3.0 o v1.3.1 son redirigidos automáticamente por GitHub (HTTP 301).*

---

## 📄 Licencias

Recursos de dominio público y licencias académicas abiertas:
- **BHS**: Biblia Hebraica Stuttgartensia
- **Tischendorf**: Texto griego del NT
- **RV1960**: Reina-Valera 1960
- **Strong**: Concordancia Strong
- **STEPBible**: Datos interlineales
- **Tipografías**: SIL Open Font License (OFL)

---

*Berea Interlineal · Flutter 3.47 · Dart 3.13 · SQLite*
