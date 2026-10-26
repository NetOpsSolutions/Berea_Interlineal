# Logos K Logos

Biblia interlineal de estudio (BHS Hebreo / Tischendorf Griego / Reina-Valera 1960) con diccionarios Strong griego y hebreo, análisis morfológico detallado, concordancia cruzada y herramientas de estudio personal.

---

## 🚀 Historial de Versiones y Novedades

### Versión 1.3.1 (Actual)
* **Persistencia Real de Datos Personales en SQLite (`logos_user_data.db`)**:
  * Base de datos SQLite dedicada e independiente de `logos_k_logos.db` para almacenar de forma permanente marcadores (`user_bookmarks`), notas de versículos (`user_verse_notes`), notas Strong (`user_strong_notes`), historial (`user_history`) y respaldo de preferencias (`user_settings`).
  * Modo ACID (`WAL` + `synchronous = FULL`), auto-reparación de esquema al abrir conexión y protección ProGuard/R8 para builds `--release`.
  * Migrador automático desde `SharedPreferences` sin pérdida de datos previos.
* **Centro de Actualizaciones In-App OTA Multi-Arquitectura**:
  * Autodetección nativa de procesador (`arm64-v8a`, `armeabi-v7a`, `x86_64`, `universal`) para descargar e instalar directamente desde GitHub Releases el paquete exacto del dispositivo.

---

### Versión 1.3.0
* **Pantalla de bienvenida animada (Splash Screen)**:
  * Presentación elegante con logotipo central iluminado, libro sagrado y caracteres originales en griego ($\text{A} \cdot \Omega$) y hebreo ($\beth$).
  * Lemas oficiales de estudio:
    * *LOGOS K LOGOS*
    * *BIBLIA INTERLINEAL DE ESTUDIO*
    * *Griego • Hebreo • Reina-Valera 1960*
    * *Diccionarios Strong y Análisis Morfológico*
  * Barra de progreso fluida y ágil (~1.6 s) con textos dinámicos de fase (*Cargando manuscritos*, *Inicializando Strong*, etc.).
  * Función de omisión instantánea al tocar la pantalla.
  * Botón en Ajustes para volver a reproducir la animación en cualquier momento (*Ver animación de bienvenida*).
* **Accesos directos accionables en Ajustes ("Mi Estudio Personal")**:
  * Ahora los elementos de *Marcadores guardados*, *Notas en versículos*, *Notas en palabras Strong* e *Historial de visitas* son interactivos.
  * Al tocarlos, abren directamente la información correspondiente con botón de retorno (`←`).
* **Filtros por categoría en notas de "Mi Estudio"**:
  * Chips interactivos para clasificar las notas: **Todas**, **En versículos** y **En palabras Strong**.
  * Pantallas de guía y estados vacíos con instrucciones claras para cada categoría.

---

### Versión 1.2
* **Hipervínculos interactivos en códigos Strong derivados**:
  * Las palabras derivadas o códigos entre paréntesis dentro de las definiciones Strong (por ejemplo: `(con 3588)`, `(de 427)`, `[como 250]`) ahora son enlaces táctiles directos. Al pulsarlos, abren la definición completa de la palabra derivada sin perder el contexto.
* **Sección "Dónde aparece" en formato acordeón desplegable**:
  * Agrupación organizada por libro bíblico con el total de versículos y ocurrencias.
  * Carga perezosa (*lazy load*) por libro al expandir el acordeón.
  * Resaltado visual tipo marcador fluorescente (fondo ámbar/dorado suave) sobre la palabra exacta, manteniendo intacto el color de fuente original del texto.
* **Corrección y sincronización del Modo Oscuro**:
  * Modo oscuro establecido como tema predeterminado del sistema.
  * Persistencia garantizada de la elección del usuario (claro/oscuro) mediante `SharedPreferences`.
  * Sincronización del interruptor (`Switch`) para que refleje el estado real de la interfaz.
* **Corrección de contraste en textos de Ajustes**:
  * Textos de novedades y descripciones con alto contraste y legibilidad óptima tanto en fondo claro como oscuro.

---

### Versión 1.1
* **Marcadores de versículos**:
  * Posibilidad de marcar versículos favoritos con un solo toque para acceso rápido.
* **Notas personales de estudio**:
  * Anotaciones teológicas y personales vinculadas directamente a un versículo bíblico.
  * Anotaciones léxicas asociadas a palabras Strong griegas o hebreas en el diccionario.
* **Historial de visitas**:
  * Registro cronológico automático de los últimos versículos consultados.
* **Modo Lectura Fluida**:
  * Opción para ocultar el bloque interlineal y mostrar únicamente el texto en español para una lectura continua y sin distracciones.
  * Subrayado punteado discreto bajo las palabras que poseen correlación Strong, permitiendo abrir su análisis con un toque.
* **Búsqueda Global Unificada**:
  * Barra de búsqueda única que consulta simultáneamente en el texto bíblico en español y en los diccionarios Strong griego y hebreo.

---

## 💻 Ejecutar la Aplicación

### Requisitos previos
* Flutter SDK (3.4+ o superior)
* Navegador Google Chrome / Edge o dispositivo Android/iOS

### Comandos de ejecución
```bash
# Instalar dependencias
flutter pub get

# Ejecutar en navegador web (modo desarrollo)
flutter run -d chrome

# Compilar para producción web
flutter build web --release

# Ejecutar pruebas automatizadas
flutter test

# Análisis de código y linter
flutter analyze

# Compilar APKs optimizados por arquitectura (< 40 MB)
flutter build apk --split-per-abi --release
```

> 📖 Para saber qué APK instalar en cada teléfono (Galaxy A33, Honor, Xiaomi, etc.), consulta la [Guía de Arquitecturas y Dispositivos](GUIA_ARQUITECTURAS_Y_DISPOSITIVOS.md).

---

## 📚 Dataset y Base de Datos (Opcional)

Para reconstruir o actualizar el conjunto de datos interlineales y léxicos:
```bash
pip install requests beautifulsoup4
python tools/crawl_logosklogos.py --out data/output --delay 0.8
python tools/build_assets.py --in data/output --out assets/data

# Generar archivo SQLite precargado para móvil:
python tools/build_assets.py --in data/output --out assets/data --db logos_k_logos.db
```

> **Nota:** Tras recompilar los datos, borra el almacenamiento local del navegador o de la app para recargar los nuevos assets.
