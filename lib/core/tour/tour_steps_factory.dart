import 'package:flutter/material.dart';

import 'interactive_tour_overlay.dart';

/// Fábrica centralizada de pasos de la Guía de Uso Interactiva contextual por versión.
///
/// Garantiza que cada versión instalada o actualizada (v1.3.0, v1.3.1, v1.3.2 y futuras v1.4.0+)
/// despliegue exactamente el recorrido correspondiente a sus propias funcionalidades.
class TourStepsFactory {
  const TourStepsFactory._();

  /// Normaliza cadenas como `"v1.3.2+7"` o `"1.3.1"` a `"1.3.2"` / `"1.3.1"`.
  static String normalizeVersion(String rawVersion) {
    final withoutPrefix = rawVersion.trim().replaceFirst(RegExp(r'^[vV]'), '');
    return withoutPrefix.split(RegExp(r'[+\-]')).first.trim();
  }

  static List<TourStepConfig> getStepsForVersion({
    required String version,
    required GlobalKey bibleKey,
    required GlobalKey searchBarKey,
    required GlobalKey dictionaryControlsKey,
    required GlobalKey studyTabsKey,
    required GlobalKey settingsKey,
    GlobalKey? Function()? bibleVerseKeyResolver,
    GlobalKey? Function()? bibleAppBarKeyResolver,
    GlobalKey? Function()? settingsReadingKeyResolver,
    GlobalKey? Function()? settingsUpdaterKeyResolver,
    GlobalKey? Function()? settingsReplayGuideKeyResolver,
    Future<void> Function()? onPrepareBibleStep,
    Future<void> Function()? onPrepareSettingsReadingStep,
    Future<void> Function()? onPrepareSettingsUpdaterStep,
    Future<void> Function()? onPrepareSettingsReplayStep,
    GlobalKey? tourDrawerButtonKey,
    GlobalKey? tourBottomNavDictionaryKey,
    GlobalKey? tourBottomNavStudyKey,
    GlobalKey? tourBookSummaryButtonKey,
    GlobalKey? tourDrawerTheologicalKey,
    GlobalKey? tourThemeToggleKey,
  }) {
    final cleanVer = normalizeVersion(version);

    switch (cleanVer) {
      case '1.3.0':
        return _buildV130Steps(
          bibleKey: bibleKey,
          searchBarKey: searchBarKey,
          dictionaryControlsKey: dictionaryControlsKey,
          studyTabsKey: studyTabsKey,
          settingsKey: settingsKey,
          bibleVerseKeyResolver: bibleVerseKeyResolver,
          bibleAppBarKeyResolver: bibleAppBarKeyResolver,
          settingsReadingKeyResolver: settingsReadingKeyResolver,
          settingsReplayGuideKeyResolver: settingsReplayGuideKeyResolver,
          onPrepareBibleStep: onPrepareBibleStep,
          onPrepareSettingsReadingStep: onPrepareSettingsReadingStep,
          onPrepareSettingsReplayStep: onPrepareSettingsReplayStep,
        );
      case '1.3.1':
        return _buildV131Steps(
          dictionaryControlsKey: dictionaryControlsKey,
          studyTabsKey: studyTabsKey,
          settingsKey: settingsKey,
          settingsUpdaterKeyResolver: settingsUpdaterKeyResolver,
          settingsReplayGuideKeyResolver: settingsReplayGuideKeyResolver,
          onPrepareSettingsUpdaterStep: onPrepareSettingsUpdaterStep,
          onPrepareSettingsReplayStep: onPrepareSettingsReplayStep,
        );
      case '1.3.2':
        return _buildV132Steps(
          bibleKey: bibleKey,
          studyTabsKey: studyTabsKey,
          settingsKey: settingsKey,
          bibleVerseKeyResolver: bibleVerseKeyResolver,
          bibleAppBarKeyResolver: bibleAppBarKeyResolver,
          settingsReadingKeyResolver: settingsReadingKeyResolver,
          settingsUpdaterKeyResolver: settingsUpdaterKeyResolver,
          settingsReplayGuideKeyResolver: settingsReplayGuideKeyResolver,
          onPrepareBibleStep: onPrepareBibleStep,
          onPrepareSettingsReadingStep: onPrepareSettingsReadingStep,
          onPrepareSettingsUpdaterStep: onPrepareSettingsUpdaterStep,
          onPrepareSettingsReplayStep: onPrepareSettingsReplayStep,
          tourThemeToggleKey: tourThemeToggleKey,
        );
      case '1.3.5':
        return _buildV135Steps(
          bibleKey: bibleKey,
          dictionaryControlsKey: dictionaryControlsKey,
          studyTabsKey: studyTabsKey,
          settingsKey: settingsKey,
          bibleVerseKeyResolver: bibleVerseKeyResolver,
          bibleAppBarKeyResolver: bibleAppBarKeyResolver,
          settingsReadingKeyResolver: settingsReadingKeyResolver,
          settingsUpdaterKeyResolver: settingsUpdaterKeyResolver,
          settingsReplayGuideKeyResolver: settingsReplayGuideKeyResolver,
          onPrepareBibleStep: onPrepareBibleStep,
          onPrepareSettingsReadingStep: onPrepareSettingsReadingStep,
          onPrepareSettingsUpdaterStep: onPrepareSettingsUpdaterStep,
          onPrepareSettingsReplayStep: onPrepareSettingsReplayStep,
          tourThemeToggleKey: tourThemeToggleKey,
        );
      case '1.3.7':
        return _buildV137Steps(
          bibleKey: bibleKey,
          dictionaryControlsKey: dictionaryControlsKey,
          studyTabsKey: studyTabsKey,
          settingsKey: settingsKey,
          bibleVerseKeyResolver: bibleVerseKeyResolver,
          bibleAppBarKeyResolver: bibleAppBarKeyResolver,
          settingsReadingKeyResolver: settingsReadingKeyResolver,
          settingsUpdaterKeyResolver: settingsUpdaterKeyResolver,
          settingsReplayGuideKeyResolver: settingsReplayGuideKeyResolver,
          onPrepareBibleStep: onPrepareBibleStep,
          onPrepareSettingsReadingStep: onPrepareSettingsReadingStep,
          onPrepareSettingsUpdaterStep: onPrepareSettingsUpdaterStep,
          onPrepareSettingsReplayStep: onPrepareSettingsReplayStep,
          tourThemeToggleKey: tourThemeToggleKey,
        );
      case '1.4.0':
      default:
        return _buildV140Steps(
          bibleKey: bibleKey,
          dictionaryControlsKey: dictionaryControlsKey,
          studyTabsKey: studyTabsKey,
          bibleVerseKeyResolver: bibleVerseKeyResolver,
          tourDrawerButtonKey: tourDrawerButtonKey,
          tourBottomNavDictionaryKey: tourBottomNavDictionaryKey,
          tourBottomNavStudyKey: tourBottomNavStudyKey,
          tourBookSummaryButtonKey: tourBookSummaryButtonKey,
          tourDrawerTheologicalKey: tourDrawerTheologicalKey,
          tourThemeToggleKey: tourThemeToggleKey,
          onPrepareBibleStep: onPrepareBibleStep,
        );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 🔹 Versión 1.3.0: Génesis de la Interfaz & Navegación Bíblica (7 pasos)
  // ───────────────────────────────────────────────────────────────────────────
  static List<TourStepConfig> _buildV130Steps({
    required GlobalKey bibleKey,
    required GlobalKey searchBarKey,
    required GlobalKey dictionaryControlsKey,
    required GlobalKey studyTabsKey,
    required GlobalKey settingsKey,
    GlobalKey? Function()? bibleVerseKeyResolver,
    GlobalKey? Function()? bibleAppBarKeyResolver,
    GlobalKey? Function()? settingsReadingKeyResolver,
    GlobalKey? Function()? settingsReplayGuideKeyResolver,
    Future<void> Function()? onPrepareBibleStep,
    Future<void> Function()? onPrepareSettingsReadingStep,
    Future<void> Function()? onPrepareSettingsReplayStep,
  }) {
    return [
      // Paso 1: Animación de Bienvenida y Presentación Oficial (Splash)
      TourStepConfig(
        badge: 'INICIO OFICIAL',
        isNewFeature: true,
        icon: Icons.play_circle_outline,
        title: 'Animación y Reverencia al Texto Sagrado',
        description:
            'Cada inicio presenta la animación oficial con manuscritos bíblicos, caracteres en griego y hebreo, y carga ágil en segundo plano.',
        pointerLabel: '🎬 Bienvenida Berea Interlineal',
        demoKind: TourDemoKind.splashWelcome,
        tabIndex: 0,
        targetKeyResolver: () =>
            bibleAppBarKeyResolver?.call() ??
            bibleVerseKeyResolver?.call() ??
            bibleKey,
      ),

      // Paso 2: Navegación Bíblica Interlineal (Biblia)
      TourStepConfig(
        badge: 'LECTURA BÍBLICA',
        isNewFeature: true,
        icon: Icons.menu_book_rounded,
        title: 'Hebreo, Griego y Español en Armonía',
        description:
            'Visualiza el texto bíblico palabra por palabra con su traducción literal en español, pronunciación fonética y códigos léxicos.',
        pointerLabel: '📖 Texto interlineal palabra a palabra',
        demoKind: TourDemoKind.interlinearWords,
        tabIndex: 0,
        onPrepareStep: onPrepareBibleStep,
        targetKeyResolver: () => bibleVerseKeyResolver?.call() ?? bibleKey,
      ),

      // Paso 3: Búsqueda Global Inmediata
      TourStepConfig(
        badge: 'BÚSQUEDA',
        icon: Icons.search_rounded,
        title: 'Encuentra Pasajes y Números Strong',
        description:
            'Escribe cualquier cita bíblica (ej. Juan 3:16) o una palabra clave para consultar todos los versículos al instante.',
        pointerLabel: '⌨️ Escribe tu búsqueda aquí',
        demoKind: TourDemoKind.typewriterSearch,
        tabIndex: 1,
        targetKeyResolver: () => searchBarKey,
      ),

      // Paso 4: Diccionario Léxico Strong
      TourStepConfig(
        badge: 'DICCIONARIO',
        icon: Icons.translate_rounded,
        title: 'Léxicos Griego y Hebreo Completos',
        description:
            'Explora las raíces morfológicas de cada término original del Antiguo y Nuevo Testamento.',
        pointerLabel: '🔤 Consulta raíces griegas y hebreas',
        demoKind: TourDemoKind.typewriterDictionary,
        tabIndex: 2,
        targetKeyResolver: () => dictionaryControlsKey,
      ),

      // Paso 5: Mi Estudio Personal
      TourStepConfig(
        badge: 'MI ESTUDIO',
        icon: Icons.bookmarks_rounded,
        title: 'Marcadores, Notas y Registro de Historial',
        description:
            'Guarda versículos predilectos y consulta tus reflexiones organizadas con accesos directos e interactivos.',
        pointerLabel: '🔖 Tus colecciones de estudio',
        demoKind: TourDemoKind.studyBasic,
        tabIndex: 3,
        targetKeyResolver: () => studyTabsKey,
      ),

      // Paso 6: Modo Oscuro y Apariencia
      TourStepConfig(
        badge: 'AJUSTES',
        icon: Icons.dark_mode_rounded,
        title: 'Modo Oscuro Predeterminado y Cómodo',
        description:
            'Diseñado para la lectura nocturna y prolongada sin fatiga visual.',
        pointerLabel: '🌙 Alterna tema claro u oscuro',
        demoKind: TourDemoKind.darkModeComfort,
        tabIndex: 4,
        onPrepareStep: onPrepareSettingsReadingStep,
        targetKeyResolver: () => settingsReadingKeyResolver?.call() ?? settingsKey,
      ),

      // Paso 7: Repetir la Guía cuando Desees
      TourStepConfig(
        badge: 'AYUDA SIEMPRE ACTIVA',
        icon: Icons.explore_rounded,
        title: 'Vuelve a Ver esta Guía de Uso',
        description:
            'Puedes repasar este recorrido en cualquier momento desde Ajustes → Ver guía de uso.',
        pointerLabel: '👆 Repetir guía de uso',
        demoKind: TourDemoKind.replayGuide,
        tabIndex: 4,
        onPrepareStep: onPrepareSettingsReplayStep,
        targetKeyResolver: () => settingsReplayGuideKeyResolver?.call() ?? settingsKey,
      ),
    ];
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 🔹 Versión 1.3.1: Persistencia SQLite Real & Motor OTA (6 pasos)
  // ───────────────────────────────────────────────────────────────────────────
  static List<TourStepConfig> _buildV131Steps({
    required GlobalKey dictionaryControlsKey,
    required GlobalKey studyTabsKey,
    required GlobalKey settingsKey,
    GlobalKey? Function()? settingsUpdaterKeyResolver,
    GlobalKey? Function()? settingsReplayGuideKeyResolver,
    Future<void> Function()? onPrepareSettingsUpdaterStep,
    Future<void> Function()? onPrepareSettingsReplayStep,
  }) {
    return [
      // Paso 1: Persistencia Permanente en SQLite (logos_user_data.db)
      TourStepConfig(
        badge: 'NOVEDAD v1.3.1',
        isNewFeature: true,
        icon: Icons.storage_rounded,
        title: 'Tus Notas y Marcadores Nunca se Borran',
        description:
            'Se incorpora una base de datos SQLite independiente con transacciones ACID. Aunque cierres forzosamente o reinicies tu teléfono, tus notas, marcadores e historial se conservan para siempre.',
        pointerLabel: '🗄️ Respaldo SQLite ACID permanente',
        demoKind: TourDemoKind.sqlitePersistence,
        tabIndex: 3,
        targetKeyResolver: () => studyTabsKey,
      ),

      // Paso 2: Migrador Automático sin Pérdida de Datos
      TourStepConfig(
        badge: 'MIGRACIÓN AUTOMÁTICA',
        isNewFeature: true,
        icon: Icons.sync_rounded,
        title: 'Datos Previos Importados al Instante',
        description:
            'Si tenías favoritos en versiones anteriores, el sistema los migra automáticamente a SQLite en el primer segundo de arranque.',
        pointerLabel: '🔄 Migración transparente completada',
        demoKind: TourDemoKind.autoMigration,
        tabIndex: 3,
        targetKeyResolver: () => studyTabsKey,
      ),

      // Paso 3: Hipervínculos Interactivos entre Códigos Strong
      TourStepConfig(
        badge: 'ESTUDIO PROFUNDO',
        isNewFeature: true,
        icon: Icons.link_rounded,
        title: 'Referencias Cruzadas en las Definiciones',
        description:
            'Las palabras derivadas entre paréntesis dentro del diccionario ahora son enlaces táctiles: pulsa cualquier código para saltar a su raíz sin salir del estudio.',
        pointerLabel: '🔗 Pulsa códigos derivados Strong',
        demoKind: TourDemoKind.strongHyperlinks,
        tabIndex: 2,
        targetKeyResolver: () => dictionaryControlsKey,
      ),

      // Paso 4: Acordeón "Dónde Aparece" por Libro Bíblico
      TourStepConfig(
        badge: 'CONCORDANCIA',
        isNewFeature: true,
        icon: Icons.format_list_bulleted_rounded,
        title: 'Ocurrencias Organizadas y Resaltadas',
        description:
            'Consulta en qué libros aparece cada palabra Strong, con carga perezosa rápida y resaltado nítido que no altera el color original del texto.',
        pointerLabel: '📚 Concordancia ágil por libro',
        demoKind: TourDemoKind.concordanceAccordion,
        tabIndex: 2,
        targetKeyResolver: () => dictionaryControlsKey,
      ),

      // Paso 5: Centro de Actualizaciones In-App OTA Multi-Procesador
      TourStepConfig(
        badge: 'ACTUALIZACIONES',
        isNewFeature: true,
        icon: Icons.system_update_rounded,
        title: 'Descarga Automática según tu Procesador',
        description:
            'Detecta si tu dispositivo es de 64 bits (arm64-v8a), 32 bits (armeabi-v7a) o emulador, descargando el paquete óptimo con barra de progreso.',
        pointerLabel: '🛰️ Actualizador inteligente por CPU',
        demoKind: TourDemoKind.otaMultiArch,
        tabIndex: 4,
        onPrepareStep: onPrepareSettingsUpdaterStep,
        targetKeyResolver: () => settingsUpdaterKeyResolver?.call() ?? settingsKey,
      ),

      // Paso 6: Repetición de la Guía
      TourStepConfig(
        badge: 'AYUDA',
        icon: Icons.explore_rounded,
        title: 'Repite el Recorrido desde Ajustes',
        description:
            'Puedes volver a iniciar esta guía de uso en cualquier momento desde Ajustes → Ver guía de uso.',
        pointerLabel: '👆 Repetir guía de uso',
        demoKind: TourDemoKind.replayGuide,
        tabIndex: 4,
        onPrepareStep: onPrepareSettingsReplayStep,
        targetKeyResolver: () => settingsReplayGuideKeyResolver?.call() ?? settingsKey,
      ),
    ];
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 🔹 Versión 1.3.2: Identidad Berea Interlineal, Capítulo Continuo & SIL (7 pasos)
  // ───────────────────────────────────────────────────────────────────────────
  static List<TourStepConfig> _buildV132Steps({
    required GlobalKey bibleKey,
    required GlobalKey studyTabsKey,
    required GlobalKey settingsKey,
    GlobalKey? Function()? bibleVerseKeyResolver,
    GlobalKey? Function()? bibleAppBarKeyResolver,
    GlobalKey? Function()? settingsReadingKeyResolver,
    GlobalKey? Function()? settingsUpdaterKeyResolver,
    GlobalKey? Function()? settingsReplayGuideKeyResolver,
    Future<void> Function()? onPrepareBibleStep,
    Future<void> Function()? onPrepareSettingsReadingStep,
    Future<void> Function()? onPrepareSettingsUpdaterStep,
    Future<void> Function()? onPrepareSettingsReplayStep,
    GlobalKey? tourThemeToggleKey,
  }) {
    return [
      // Paso 1: Nueva Identidad Oficial "Berea Interlineal"
      TourStepConfig(
        badge: 'NUEVA IDENTIDAD',
        isNewFeature: true,
        icon: Icons.verified_rounded,
        title: 'Inspirados en Hechos 17:11',
        description:
            'Nuevo logotipo oficial: la Biblia abierta iluminada y la lupa de aumento exegético sobre Hechos 17:11 («escudriñando cada día las Escrituras»).',
        pointerLabel: '✨ Edición Oficial Berea Interlineal',
        demoKind: TourDemoKind.bereaIdentity,
        tabIndex: 0,
        targetKeyResolver: () =>
            bibleAppBarKeyResolver?.call() ??
            bibleVerseKeyResolver?.call() ??
            bibleKey,
      ),

      // Paso 2: Lectura por Capítulo Completo y Gestos Laterales
      TourStepConfig(
        badge: 'EXPERIENCIA BÍBLICA',
        isNewFeature: true,
        icon: Icons.menu_book_rounded,
        title: 'Lectura Continua y Expansión al Toque',
        description:
            'Lee los capítulos corridos con scroll vertical; pulsa cualquier versículo para desplegar su análisis interlineal en línea sin perder la lectura. Desliza a los lados para cambiar de capítulo.',
        pointerLabel: '👆 Pulsa en un versículo',
        demoKind: TourDemoKind.chapterUnfold,
        tabIndex: 0,
        onPrepareStep: onPrepareBibleStep,
        targetKeyResolver: () => bibleVerseKeyResolver?.call() ?? bibleKey,
      ),

      // Paso 3: Tipografías Académicas SIL OFL Offline
      TourStepConfig(
        badge: 'TIPOGRAFÍA ACADÉMICA',
        isNewFeature: true,
        icon: Icons.text_fields_rounded,
        title: 'Fuentes Ezra SIL, Cardo y Frank Ruhl Libre',
        description:
            'Soporte completo de diacríticos griegos politónicos y cantilaciones hebreas (nikud), con selector de tamaño y fuentes «TT».',
        pointerLabel: '🔤 Vistas y fuentes «TT»',
        demoKind: TourDemoKind.topBarControls,
        tabIndex: 0,
        targetKeyResolver: () => bibleAppBarKeyResolver?.call() ?? bibleKey,
      ),

      // Paso 4: 5 Resaltadores Teológicos
      TourStepConfig(
        badge: 'HERRAMIENTA TEOLÓGICA',
        isNewFeature: true,
        icon: Icons.palette_rounded,
        title: 'Resalta Versículos o Frases Seleccionadas',
        description:
            'Clasifica tus pasajes en Promesas (🟡), Mandamientos (🟢), Atributos de Dios (🔵), Advertencias (🌸) o Profecía (🟣).',
        pointerLabel: '🎨 Tus resaltados teológicos',
        demoKind: TourDemoKind.studyCollections,
        tabIndex: 3,
        targetKeyResolver: () => studyTabsKey,
      ),

      // Paso 5: Notificaciones Nativas en la Bandeja de Android
      TourStepConfig(
        badge: 'ACTUALIZACIONES',
        isNewFeature: true,
        icon: Icons.notifications_active_outlined,
        title: 'Avisos Nativos con Confirmación Explícita',
        description:
            'Android te notifica en la barra del sistema cuando hay una nueva versión, mostrando las novedades y pidiendo confirmación antes de descargar.',
        pointerLabel: '🔔 Centro de actualizaciones OTA',
        demoKind: TourDemoKind.otaNotification,
        tabIndex: 4,
        onPrepareStep: onPrepareSettingsUpdaterStep,
        targetKeyResolver: () => settingsUpdaterKeyResolver?.call() ?? settingsKey,
      ),

      // Paso 6: Alternador Rápido de Tema Sol / Luna (☀️/🌙)
      TourStepConfig(
        badge: 'TEMA RÁPIDO',
        isNewFeature: true,
        icon: Icons.light_mode_rounded,
        title: 'Alternador de Modo Claro y Oscuro (☀️/🌙)',
        description:
            '¡Novedad a partir de la v1.3.2! Cambia al instante entre el modo claro (Pergamino Diurno) y el modo oscuro (Noche Alejandrina) con un solo toque desde la barra superior usando el icono de sol y luna, sin necesidad de ir a Ajustes.',
        pointerLabel: '☀️/🌙 Modo Claro / Oscuro',
        demoKind: TourDemoKind.topBarControls,
        tabIndex: 0,
        targetKeyResolver: () => tourThemeToggleKey ?? bibleKey,
      ),

      // Paso 7: Repetir Guía de Uso
      TourStepConfig(
        badge: 'AYUDA SIEMPRE ACTIVA',
        icon: Icons.explore_rounded,
        title: 'Vuelve a Ver esta Guía de Uso',
        description:
            'Acceso permanente en Ajustes → Ver guía de uso para volver a reproducir este recorrido interactivo bajo demanda.',
        pointerLabel: '👆 Repetir guía de uso',
        demoKind: TourDemoKind.replayGuide,
        tabIndex: 4,
        onPrepareStep: onPrepareSettingsReplayStep,
        targetKeyResolver: () => settingsReplayGuideKeyResolver?.call() ?? settingsKey,
      ),
    ];
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 🔹 Versión 1.3.5: Edición Léxica (8 pasos)
  // ───────────────────────────────────────────────────────────────────────────
  static List<TourStepConfig> _buildV135Steps({
    required GlobalKey bibleKey,
    required GlobalKey dictionaryControlsKey,
    required GlobalKey studyTabsKey,
    required GlobalKey settingsKey,
    GlobalKey? Function()? bibleVerseKeyResolver,
    GlobalKey? Function()? bibleAppBarKeyResolver,
    GlobalKey? Function()? settingsReadingKeyResolver,
    GlobalKey? Function()? settingsUpdaterKeyResolver,
    GlobalKey? Function()? settingsReplayGuideKeyResolver,
    Future<void> Function()? onPrepareBibleStep,
    Future<void> Function()? onPrepareSettingsReadingStep,
    Future<void> Function()? onPrepareSettingsUpdaterStep,
    Future<void> Function()? onPrepareSettingsReplayStep,
    GlobalKey? tourThemeToggleKey,
  }) {
    return [
      // Paso 1: Identidad & Lector Bíblico Interlineal
      TourStepConfig(
        badge: 'IDENTIDAD Y LECTURA',
        icon: Icons.auto_stories_rounded,
        title: 'Berea Interlineal: Texto Original con Máxima Fluidez',
        description:
            'Lectura continua y solemne con textos originales en Hebreo (BHS) y Griego (NA28) alineados palabra por palabra.',
        pointerLabel: '📖 Lector Bíblico Interlineal',
        demoKind: TourDemoKind.bereaIdentity,
        tabIndex: 0,
        onPrepareStep: onPrepareBibleStep,
        targetKeyResolver: () => bibleVerseKeyResolver?.call() ?? bibleKey,
      ),

      // Paso 2: Despliegue de Capítulo Completo
      TourStepConfig(
        badge: 'LECTURA CONTINUA',
        icon: Icons.menu_book_rounded,
        title: 'Despliegue de Capítulo Completo',
        description:
            'Lee el capítulo íntegro de un tirón. Toca cualquier versículo para desplegar al instante sus herramientas de análisis.',
        pointerLabel: '📖 Alterna capítulo / versículo',
        demoKind: TourDemoKind.chapterUnfold,
        tabIndex: 0,
        targetKeyResolver: () => bibleAppBarKeyResolver?.call() ?? bibleKey,
      ),

      // Paso 3: Tipografía Bíblica SIL
      TourStepConfig(
        badge: 'TIPOGRAFÍA SIL',
        icon: Icons.font_download_rounded,
        title: 'Fuentes Académicas Ezra SIL y Gentium Plus',
        description:
            'Puntuación masorética hebrea y acentuación politónica griega nítidas y legibles en cualquier tamaño de pantalla.',
        pointerLabel: '🔤 Selector tipográfico TT',
        demoKind: TourDemoKind.topBarControls,
        tabIndex: 0,
        targetKeyResolver: () => bibleAppBarKeyResolver?.call() ?? bibleKey,
      ),

      // Paso 4: Resaltadores Teológicos
      TourStepConfig(
        badge: 'HERRAMIENTAS',
        icon: Icons.format_paint_rounded,
        title: 'Resalta Versículos o Frases Seleccionadas',
        description:
            '5 colores teológicos (Promesas, Mandamientos, Atributos de Dios, Advertencias, Profecía) con notas y marcadores persistentes.',
        pointerLabel: '🎨 Resaltador y herramientas',
        demoKind: TourDemoKind.studyCollections,
        tabIndex: 0,
        targetKeyResolver: () => bibleVerseKeyResolver?.call() ?? bibleKey,
      ),

      // Paso 5: Diccionario Enriquecido (Novedad v1.3.5)
      TourStepConfig(
        badge: 'NOVEDAD v1.3.5',
        isNewFeature: true,
        icon: Icons.translate_rounded,
        title: '100% Derivaciones y Léxico STEPBible',
        description:
            '¡Gran enriquecimiento léxico! 14.197 términos con etimologías completas, léxico académico Tyndale STEPBible, supresión de guiones vacíos e hipervínculos táctiles entre códigos Strong.',
        pointerLabel: '🏛️ Léxico STEPBible y Raíces',
        demoKind: TourDemoKind.strongHyperlinks,
        tabIndex: 2,
        targetKeyResolver: () => dictionaryControlsKey,
      ),

      // Paso 6: Alternador Rápido de Tema Sol / Luna (☀️/🌙)
      TourStepConfig(
        badge: 'TEMA RÁPIDO',
        isNewFeature: true,
        icon: Icons.light_mode_rounded,
        title: 'Alternador de Modo Claro y Oscuro (☀️/🌙)',
        description:
            'Cambia al instante entre el modo claro (Pergamino Diurno) y el modo oscuro (Noche Alejandrina) con un solo toque desde la barra superior, sin entrar a Ajustes.',
        pointerLabel: '☀️/🌙 Modo Claro / Oscuro',
        demoKind: TourDemoKind.topBarControls,
        tabIndex: 0,
        targetKeyResolver: () => tourThemeToggleKey ?? bibleKey,
      ),

      // Paso 7: Avisos Nativos OTA
      TourStepConfig(
        badge: 'ACTUALIZACIONES',
        icon: Icons.system_update_rounded,
        title: 'Avisos Nativos con Confirmación Explícita',
        description:
            'Notificaciones del sistema cuando hay una nueva versión disponible, mostrando notas de cambios y confirmación previa de descarga.',
        pointerLabel: '🔔 Centro de actualizaciones',
        demoKind: TourDemoKind.otaNotification,
        tabIndex: 4,
        onPrepareStep: onPrepareSettingsUpdaterStep,
        targetKeyResolver: () => settingsUpdaterKeyResolver?.call() ?? settingsKey,
      ),

      // Paso 8: Repetir Guía de Uso
      TourStepConfig(
        badge: 'AYUDA SIEMPRE ACTIVA',
        icon: Icons.explore_rounded,
        title: 'Vuelve a Ver esta Guía de Uso',
        description:
            'Acceso permanente en Ajustes → Ver guía de uso para volver a reproducir este recorrido interactivo bajo demanda.',
        pointerLabel: '👆 Repetir guía de uso',
        demoKind: TourDemoKind.replayGuide,
        tabIndex: 4,
        onPrepareStep: onPrepareSettingsReplayStep,
        targetKeyResolver: () => settingsReplayGuideKeyResolver?.call() ?? settingsKey,
      ),
    ];
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 🔹 Versión 1.3.7: Edición Exegética (10 pasos)
  // ───────────────────────────────────────────────────────────────────────────
  static List<TourStepConfig> _buildV137Steps({
    required GlobalKey bibleKey,
    required GlobalKey dictionaryControlsKey,
    required GlobalKey studyTabsKey,
    required GlobalKey settingsKey,
    GlobalKey? Function()? bibleVerseKeyResolver,
    GlobalKey? Function()? bibleAppBarKeyResolver,
    GlobalKey? Function()? settingsReadingKeyResolver,
    GlobalKey? Function()? settingsUpdaterKeyResolver,
    GlobalKey? Function()? settingsReplayGuideKeyResolver,
    Future<void> Function()? onPrepareBibleStep,
    Future<void> Function()? onPrepareSettingsReadingStep,
    Future<void> Function()? onPrepareSettingsUpdaterStep,
    Future<void> Function()? onPrepareSettingsReplayStep,
    GlobalKey? tourThemeToggleKey,
  }) {
    return [
      // Paso 1: Identidad & Lector Bíblico Interlineal
      TourStepConfig(
        badge: 'IDENTIDAD Y LECTURA',
        icon: Icons.auto_stories_rounded,
        title: 'Berea Interlineal: Texto Original con Máxima Fluidez',
        description:
            'Lectura continua y solemne con textos originales en Hebreo (BHS) y Griego (NA28) alineados palabra por palabra.',
        pointerLabel: '📖 Lector Bíblico Interlineal',
        demoKind: TourDemoKind.bereaIdentity,
        tabIndex: 0,
        onPrepareStep: onPrepareBibleStep,
        targetKeyResolver: () => bibleVerseKeyResolver?.call() ?? bibleKey,
      ),

      // Paso 2: Despliegue de Capítulo Completo
      TourStepConfig(
        badge: 'LECTURA CONTINUA',
        icon: Icons.menu_book_rounded,
        title: 'Despliegue de Capítulo Completo',
        description:
            'Lee el capítulo íntegro de un tirón. Toca cualquier versículo para desplegar al instante sus herramientas de análisis.',
        pointerLabel: '📖 Alterna capítulo / versículo',
        demoKind: TourDemoKind.chapterUnfold,
        tabIndex: 0,
        targetKeyResolver: () => bibleAppBarKeyResolver?.call() ?? bibleKey,
      ),

      // Paso 3: Tipografía Bíblica SIL
      TourStepConfig(
        badge: 'TIPOGRAFÍA SIL',
        icon: Icons.font_download_rounded,
        title: 'Fuentes Académicas Ezra SIL y Gentium Plus',
        description:
            'Puntuación masorética hebrea y acentuación politónica griega nítidas y legibles en cualquier tamaño de pantalla.',
        pointerLabel: '🔤 Selector tipográfico TT',
        demoKind: TourDemoKind.topBarControls,
        tabIndex: 0,
        targetKeyResolver: () => bibleAppBarKeyResolver?.call() ?? bibleKey,
      ),

      // Paso 4: Resaltadores Teológicos
      TourStepConfig(
        badge: 'HERRAMIENTAS',
        icon: Icons.format_paint_rounded,
        title: 'Resalta Versículos o Frases Seleccionadas',
        description:
            '5 colores teológicos (Promesas, Mandamientos, Atributos de Dios, Advertencias, Profecía) con notas y marcadores persistentes.',
        pointerLabel: '🎨 Resaltador y herramientas',
        demoKind: TourDemoKind.studyCollections,
        tabIndex: 0,
        targetKeyResolver: () => bibleVerseKeyResolver?.call() ?? bibleKey,
      ),

      // Paso 5: Diccionario Enriquecido
      TourStepConfig(
        badge: 'LÉXICO ACADÉMICO',
        icon: Icons.translate_rounded,
        title: '100% Derivaciones y Léxico STEPBible',
        description:
            '14.197 términos con etimologías completas, léxico académico Tyndale STEPBible e hipervínculos táctiles entre códigos Strong.',
        pointerLabel: '🏛️ Léxico STEPBible y Raíces',
        demoKind: TourDemoKind.strongHyperlinks,
        tabIndex: 2,
        targetKeyResolver: () => dictionaryControlsKey,
      ),

      // Paso 6: Similitudes y Comparaciones Teológicas (Novedad v1.3.7)
      TourStepConfig(
        badge: 'NOVEDAD v1.3.7',
        isNewFeature: true,
        icon: Icons.compare_arrows_rounded,
        title: 'Similitudes y Comparaciones Teológicas',
        description:
            '¡Análisis exegético profundo! Compara matices entre términos afines: érets (tierra política) vs adamáh (tierra cultivable) vs tebél (el mundo cósmico), bará vs asáh, agapáo vs philéo.',
        pointerLabel: '⚖️ Similitudes Teológicas',
        demoKind: TourDemoKind.typewriterDictionary,
        tabIndex: 2,
        targetKeyResolver: () => dictionaryControlsKey,
      ),

      // Paso 7: Familias de Palabras Derivadas (Novedad v1.3.7)
      TourStepConfig(
        badge: 'NOVEDAD v1.3.7',
        isNewFeature: true,
        icon: Icons.account_tree_rounded,
        title: 'Árbol Léxico y Familias Derivadas',
        description:
            'Visualiza con pastillas doradas táctiles todas las palabras bíblicas que brotan de una misma raíz común, conectadas mediante la tabla relacional SQLite.',
        pointerLabel: '🌿 Familias Derivadas',
        demoKind: TourDemoKind.strongHyperlinks,
        tabIndex: 2,
        targetKeyResolver: () => dictionaryControlsKey,
      ),

      // Paso 8: Alternador Rápido de Tema Sol / Luna (☀️/🌙)
      TourStepConfig(
        badge: 'TEMA RÁPIDO',
        isNewFeature: true,
        icon: Icons.light_mode_rounded,
        title: 'Alternador de Modo Claro y Oscuro (☀️/🌙)',
        description:
            'Cambia al instante entre el modo claro (Pergamino Diurno) y el modo oscuro (Noche Alejandrina) con un solo toque desde la barra superior, sin entrar a Ajustes.',
        pointerLabel: '☀️/🌙 Modo Claro / Oscuro',
        demoKind: TourDemoKind.topBarControls,
        tabIndex: 0,
        targetKeyResolver: () => tourThemeToggleKey ?? bibleKey,
      ),

      // Paso 9: Avisos Nativos OTA
      TourStepConfig(
        badge: 'ACTUALIZACIONES',
        icon: Icons.system_update_rounded,
        title: 'Avisos Nativos con Confirmación Explícita',
        description:
            'Notificaciones del sistema cuando hay una nueva versión disponible, mostrando notas de cambios y confirmación previa de descarga.',
        pointerLabel: '🔔 Centro de actualizaciones',
        demoKind: TourDemoKind.otaNotification,
        tabIndex: 4,
        onPrepareStep: onPrepareSettingsUpdaterStep,
        targetKeyResolver: () => settingsUpdaterKeyResolver?.call() ?? settingsKey,
      ),

      // Paso 10: Repetir Guía de Uso
      TourStepConfig(
        badge: 'AYUDA SIEMPRE ACTIVA',
        icon: Icons.explore_rounded,
        title: 'Vuelve a Ver esta Guía de Uso',
        description:
            'Acceso permanente en Ajustes → Ver guía de uso para volver a reproducir este recorrido interactivo bajo demanda.',
        pointerLabel: '👆 Repetir guía de uso',
        demoKind: TourDemoKind.replayGuide,
        tabIndex: 4,
        onPrepareStep: onPrepareSettingsReplayStep,
        targetKeyResolver: () => settingsReplayGuideKeyResolver?.call() ?? settingsKey,
      ),
    ];
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 🔹 Versión 1.4.0+ (Referencia de Diseño para el Futuro)
  // ───────────────────────────────────────────────────────────────────────────
  static List<TourStepConfig> _buildV140Steps({
    required GlobalKey bibleKey,
    required GlobalKey dictionaryControlsKey,
    required GlobalKey studyTabsKey,
    GlobalKey? Function()? bibleVerseKeyResolver,
    GlobalKey? tourDrawerButtonKey,
    GlobalKey? tourBottomNavDictionaryKey,
    GlobalKey? tourBottomNavStudyKey,
    GlobalKey? tourBookSummaryButtonKey,
    GlobalKey? tourDrawerTheologicalKey,
    GlobalKey? tourThemeToggleKey,
    Future<void> Function()? onPrepareBibleStep,
  }) {
    return [
      // Paso 1: BIENVENIDA & LECTURA
      TourStepConfig(
        badge: 'BIENVENIDA & LECTURA',
        icon: Icons.auto_stories_rounded,
        title: 'Lector Bíblico Interlineal Continuo',
        description:
            'Lee fluidamente las Escrituras en español con su texto original en Hebreo y Griego. Toca cualquier palabra interlineal para ver su análisis gramatical y raíz. (Función consolidada)',
        pointerLabel: '📖 Texto bíblico e interlineal',
        demoKind: TourDemoKind.interlinearWords,
        tabIndex: 0,
        onPrepareStep: onPrepareBibleStep,
        targetKeyResolver: () => bibleVerseKeyResolver?.call() ?? bibleKey,
      ),

      // Paso 2: NUEVA NAVEGACIÓN
      TourStepConfig(
        badge: 'NUEVA NAVEGACIÓN',
        isNewFeature: true,
        icon: Icons.menu_rounded,
        title: 'Nuevo Menú Lateral: Persiana de Estudio (☰)',
        description:
            '¡Gran novedad de la v1.4.0! Toca el icono ☰ o desliza tu dedo desde el borde izquierdo hacia la derecha para desplegar la persiana con todas las herramientas avanzadas.',
        pointerLabel: '☰ Menú persiana lateral',
        demoKind: TourDemoKind.topBarControls,
        tabIndex: 0,
        targetKeyResolver: () => tourDrawerButtonKey ?? bibleKey,
      ),

      // Paso 3: TEMA RÁPIDO
      TourStepConfig(
        badge: 'TEMA RÁPIDO',
        isNewFeature: true,
        icon: Icons.light_mode_rounded,
        title: 'Alternador de Modo Claro y Oscuro (☀️/🌙)',
        description:
            'Cambia al instante entre la lectura en Pergamino Diurno y Noche Alejandrina con un solo toque en el icono de sol y luna en la barra superior, sin entrar a Ajustes.',
        pointerLabel: '☀️/🌙 Modo Claro / Oscuro',
        demoKind: TourDemoKind.topBarControls,
        tabIndex: 0,
        targetKeyResolver: () => tourThemeToggleKey ?? bibleKey,
      ),

      // Paso 4: NUEVO MÓDULO
      TourStepConfig(
        badge: 'NUEVO MÓDULO',
        isNewFeature: true,
        icon: Icons.history_edu_rounded,
        title: 'Resumen Bíblico de los 66 Libros',
        description:
            'Descubre el autor, fecha de redacción, contexto histórico, puntos clave y lecciones prácticas de cada libro. ¡Disponible en la persiana y también con el botón de pergamino en el lector!',
        pointerLabel: '📜 Ficha técnica y resumen',
        demoKind: TourDemoKind.futureModule,
        tabIndex: 0,
        targetKeyResolver: () => tourBookSummaryButtonKey ?? bibleKey,
      ),

      // Paso 5: NUEVO MÓDULO
      TourStepConfig(
        badge: 'NUEVO MÓDULO',
        isNewFeature: true,
        icon: Icons.person_search_rounded,
        title: 'Biografías de Escritores Sagrados',
        description:
            'Conoce la vida, vocación y legado de los hombres inspirados por Dios (Moisés, David, Lucas, Pablo...), con enlaces interactivos a sus nombres en los idiomas originales.',
        pointerLabel: '👤 Escritores inspirados',
        demoKind: TourDemoKind.futureModule,
        tabIndex: 0,
        targetKeyResolver: () => tourDrawerButtonKey ?? bibleKey,
      ),

      // Paso 6: LÉXICO Y RAÍCES
      TourStepConfig(
        badge: 'LÉXICO Y RAÍCES',
        icon: Icons.translate_rounded,
        title: 'Diccionario Strong Griego y Hebreo',
        description:
            'Accesible al instante en la barra inferior. Busca definiciones exhaustivas, concordancia y palabras derivadas con hipervínculos directos. (Función consolidada)',
        pointerLabel: '🔤 Diccionario Strong',
        demoKind: TourDemoKind.typewriterDictionary,
        tabIndex: 1,
        targetKeyResolver: () => tourBottomNavDictionaryKey ?? dictionaryControlsKey,
      ),

      // Paso 7: ESTUDIO PERSONAL
      TourStepConfig(
        badge: 'ESTUDIO PERSONAL',
        icon: Icons.bookmark_added_rounded,
        title: 'Mi Estudio: Notas, Marcadores e Historial',
        description:
            'Todo tu trabajo personal guardado de forma permanente en SQLite: notas devocionales, historial de versículos y marcadores ordenados. (Función consolidada)',
        pointerLabel: '📑 Panel de Mi Estudio',
        demoKind: TourDemoKind.studyCollections,
        tabIndex: 2,
        targetKeyResolver: () => tourBottomNavStudyKey ?? studyTabsKey,
      ),

      // Paso 8: TEOLOGÍA VISUAL
      TourStepConfig(
        badge: 'TEOLOGÍA VISUAL',
        isNewFeature: true,
        icon: Icons.palette_rounded,
        title: '5 Resaltadores Teológicos con Filtro Rápido',
        description:
            'Clasifica versículos por colores doctrinales: 🟡 Promesas, 🟢 Mandamientos, 🔵 Atributos de Dios, 🔴 Advertencias y 🟣 Profecía. ¡Ahora puedes filtrarlos directamente desde el menú lateral!',
        pointerLabel: '🎨 Resaltados teológicos',
        demoKind: TourDemoKind.futureModule,
        tabIndex: 2,
        targetKeyResolver: () => tourDrawerTheologicalKey ?? tourBottomNavStudyKey ?? studyTabsKey,
      ),

      // Paso 9: AYUDA PERMANENTE
      TourStepConfig(
        badge: 'AYUDA PERMANENTE',
        icon: Icons.explore_rounded,
        title: 'Tu Guía Siempre a Mano',
        description:
            'Puedes volver a repasar este recorrido interactivo cuando lo desees desde el menú lateral o desde Ajustes ➔ Ver guía de uso.',
        pointerLabel: '🧭 Guía de uso permanente',
        demoKind: TourDemoKind.replayGuide,
        tabIndex: 0,
        targetKeyResolver: () => tourDrawerButtonKey ?? bibleKey,
      ),
    ];
  }
}
