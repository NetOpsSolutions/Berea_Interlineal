# 📖 Berea Interlineal

**Biblia Interlineal de Estudio** — BHS Hebreo · Tischendorf Griego · Reina-Valera 1960  
Con diccionarios Strong griego y hebreo, análisis morfológico, concordancia cruzada y herramientas de estudio personal.

> 📦 Repositorio oficial: [NetOpsSolutions/Berea_Interlineal](https://github.com/NetOpsSolutions/Berea_Interlineal) · **Última versión oficial:** [v1.3.1 (Descargar APK)](https://github.com/NetOpsSolutions/Berea_Interlineal/releases/tag/1.3.1) · **Distribución directa vía GitHub Releases (OTA)**

---

## ✨ Características Principales

| Módulo | Descripción |
|---|---|
| 📖 **Biblia Interlineal** | Texto hebreo (BHS) / griego (Tischendorf) con RV1960 alineados versículo a versículo con morfología y fonética |
| 🔤 **Diccionarios Strong** | 8.674 palabras griegas + 8.674 hebreas con lemma, definición, pronunciación, morfología y ocurrencias |
| 🔍 **Búsqueda Global** | Búsqueda simultánea y en tiempo real en texto bíblico y diccionarios Strong |
| 🔗 **Hipervínculos Strong** | Referencias cruzadas entre palabras relacionadas táctiles y navegables directamente |
| 📜 **Pergamino Alejandrino** | Entorno visual solemne inspirado en códices antiguos (#F5EEDB en Modo Claro, #181412 en Modo Oscuro) |
| 🔖 **Mi Estudio Personal** | Marcadores, notas de versículo, notas Strong e historial con persistencia ACID en SQLite (`logos_user_data.db`) |
| 📚 **Modo Lectura Fluida** | Texto limpio en español con términos Strong subrayados discretamente |
| 🎨 **Resaltadores Teológicos** | Marcado en 5 categorías teológicas (Promesas, Mandamientos, Atributos de Dios, Advertencias, Profecía) |
| 🧭 **Guía Visual Interactiva** | Recorrido guiado que se muestra una sola vez tras actualizar y accesible bajo demanda desde Ajustes |
| 🔄 **Actualizador OTA Híbrido** | Detección automática de procesador (`arm64-v8a`, `armeabi-v7a`, `x86_64`, `universal`), soporte ETag (HTTP 304) y descarga directa desde GitHub Releases |

---

## 🚀 Historial de Versiones

### Versión 1.3.1 (Actual / Producción) — Edición Manuscrito Alejandrino, Persistencia SQLite y OTA Híbrido
- **📜 Entorno Visual Pergamino Alejandrino**:
  - Reemplazo del blanco digital plano por un tono cálido de papiro y arena marfil (`#F5EEDB`) en Modo Claro, y códice en penumbra (`#181412`) en Modo Oscuro.
  - Cero líneas de libreta y cero tramas artificiales; lectura limpia que reduce drásticamente la fatiga visual.
- **🎬 SplashScreen Cinematográfica Solemne (3s)**:
  - Presentación majestuosa con textura de cuero antiguo, iluminación celestial y barra de carga en oro ámbar.
  - Lema oficial de Berea: *«...escudriñando cada día las Escrituras»* (**Hechos 17:11**).
- **🗄️ Persistencia Real Permanente en SQLite (`logos_user_data.db`)**:
  - Arquitectura atómica ACID en tablas nativas dedicadas para Marcadores, Notas de versículo, Notas en palabras Strong, Historial de lectura y Preferencias de usuario.
  - Migrador automático y transparente desde versiones anteriores (`SharedPreferences`).
- **🔄 Actualizador In-App OTA Inteligente (Estrategia Híbrida 4 en 1)**:
  - **Arranque Suave**: Pausa inicial de 15 segundos al abrir la app para no competir con la inicialización de la interfaz ni la base de datos SQLite.
  - **Detección Reactiva de Red**: Al volver a la aplicación desde segundo plano (`WidgetsBindingObserver.resumed`) o recuperar conexión, verifica de inmediato.
  - **Ventana de Enfriamiento de Seguridad**: *Cooldown* mínimo de 5 minutos que protege contra parpadeos de señal Wi-Fi o redes móviles.
  - **Ciclo Periódico Prudente**: Sondeo silencioso y relajado cada 15 minutos en segundo plano durante sesiones de lectura prolongada.
  - **Soporte de Cabecera Condicional HTTP ETag (`304 Not Modified`)**: GitHub responde con consumo 0 del límite de tasa (60 req/h), blindando la app contra bloqueos de IP.
  - **Autodetección Nativa de CPU**: Descarga exclusivamente el paquete compatible con la arquitectura del procesador (`arm64-v8a`, `armeabi-v7a`, `x86_64`, `universal`).
- **🔗 Navegación Léxica Mejorada**:
  - Hipervínculos interactivos entre códigos Strong derivados dentro de las definiciones léxicas.
  - Acordeón de ocurrencias por libro con selector interactivo y conteo de apariciones sin perder el contexto.
- **👁️ Accesibilidad y Contraste WCAG AAA**:
  - Paleta con alto contraste en avisos emergentes (`SnackBar`), diálogos modales y botones tanto en modo claro como en modo oscuro.

### Versión 1.3.0 — Motor OTA, Base Bíblica Precompilada y Arranque Rápido
- **⚡ Base Bíblica SQLite Preconstruida (`logos_k_logos.db`)**:
  - Reducción del tiempo de primer inicio de 10 minutos a menos de 3 segundos mediante desempaquetado directo de asset indexado.
- **📖 Lectura Bíblica Interlineal Palabra por Palabra**:
  - Alineación de texto Hebreo (BHS) y Griego (Tischendorf) con RV1960 versículo a versículo, incluyendo lemas, fonética y morfología.
- **🔍 Búsqueda Global y Léxicos Strong**:
  - Motor de búsqueda instantánea para palabras clave, citas bíblicas y códigos Strong AT y NT.
- **🧭 Guía Interactiva Base**:
  - Recorrido guiado inicial animado de bienvenida presentando las funciones fundamentales de la app.
- **🔄 Sistema de Actualización In-App (OTA)**:
  - Verificación y descarga directa de APKs oficiales desde GitHub Releases con confirmación de usuario.

### Versión 1.3.2 (Próxima Publicación / En Desarrollo) — Identidad Oficial Berea, Guía Visual y Fase 3 UI/UX
- **✨ Transición Oficial de Identidad ("Berea Interlineal")**:
  - Nuevo logotipo oficial inspirado en Hechos 17:11 (Biblia sagrada abierta con lente exegética de aumento iluminada en oro y azul zafiro).
  - Nuevos iconos adaptativos multi-resolución para Android (`mipmap-*`, v26) e iOS (`AppIcon`).
- **🧭 Guía Visual Interactiva Contextual (Tour v1.3.2)**:
  - Recorrido interactivo tipo coach-mark guiando paso a paso por las 7 innovaciones clave de la versión.
- **📖 Lectura por Capítulo Completo (Fase 3 UI/UX)**:
  - Scroll vertical continuo de capítulos completos con expansión interlineal instantánea al pulsar cualquier versículo.
  - Gestos swipe laterales para navegación fluida entre capítulos.
- **🔤 Tipografías Académicas SIL OFL**:
  - Fuentes nativas offline: Ezra SIL y Frank Ruhl Libre (Hebreo con nikud/cantilaciones) y Cardo / Gentium Plus (Griego Koiné politónico).
- **🎨 Resaltadores Teológicos**:
  - Clasificación visual persistente en SQLite en 5 categorías temáticas (Promesas, Mandamientos, Atributos de Dios, Advertencias, Profecía).
- **🍏 Distribución iOS (.ipa)**:
  - Paquete instalador oficial `Berea_Interlineal_1.3.2.ipa` preparado para instalación vía AltStore, Sideloadly o TrollStore.

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
GET https://api.github.com/repos/NetOpsSolutions/Berea_Interlineal/releases?per_page=5
```
*Los dispositivos que tenían v1.3.0 son actualizados directamente a v1.3.1 vía OTA con autoselección de arquitectura CPU.*

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
