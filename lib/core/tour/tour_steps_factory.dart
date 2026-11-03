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
        );
      case '1.4.0':
      default:
        return _buildV140Steps(
          bibleKey: bibleKey,
          dictionaryControlsKey: dictionaryControlsKey,
          studyTabsKey: studyTabsKey,
          bibleVerseKeyResolver: bibleVerseKeyResolver,
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

      // Paso 6: Contraste Visual Accesible WCAG AAA
      TourStepConfig(
        badge: 'ACCESIBILIDAD',
        icon: Icons.contrast_rounded,
        title: 'Legibilidad Óptima en Temas Claro y Oscuro',
        description:
            'Contraste visual accesible WCAG AAA calibrado en todas las pantallas, tarjetas y modos de lectura para proteger tu vista.',
        pointerLabel: '🌗 Tema, modos y escala de letra',
        demoKind: TourDemoKind.readingPreferences,
        tabIndex: 4,
        onPrepareStep: onPrepareSettingsReadingStep,
        targetKeyResolver: () => settingsReadingKeyResolver?.call() ?? settingsKey,
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
  // 🔹 Versión 1.4.0+ (Referencia de Diseño para el Futuro)
  // ───────────────────────────────────────────────────────────────────────────
  static List<TourStepConfig> _buildV140Steps({
    required GlobalKey bibleKey,
    required GlobalKey dictionaryControlsKey,
    required GlobalKey studyTabsKey,
    GlobalKey? Function()? bibleVerseKeyResolver,
  }) {
    return [
      TourStepConfig(
        badge: 'NUEVO MÓDULO',
        isNewFeature: true,
        icon: Icons.auto_stories_rounded,
        title: 'Autor, Destinatarios, Contexto y Aplicación',
        description:
            'Ficha técnica detallada de cada libro antes de leerlo, con contexto histórico, puntos más resaltantes y cómo aplica a tu vida diaria.',
        pointerLabel: '📜 Resumen de los 66 libros',
        demoKind: TourDemoKind.futureModule,
        tabIndex: 0,
        targetKeyResolver: () => bibleVerseKeyResolver?.call() ?? bibleKey,
      ),
      TourStepConfig(
        badge: 'BIOGRAFÍAS',
        isNewFeature: true,
        icon: Icons.person_search_rounded,
        title: 'Vida, Ministerio y Llamamiento de los Escritores',
        description:
            'Conoce el trasfondo histórico de Moisés, David, Isaías, los Apóstoles y profetas con hipervínculos a sus escritos.',
        pointerLabel: '👤 Galería de escritores bíblicos',
        demoKind: TourDemoKind.futureModule,
        tabIndex: 0,
        targetKeyResolver: () => bibleKey,
      ),
      TourStepConfig(
        badge: 'DIFUSIÓN',
        isNewFeature: true,
        icon: Icons.share_rounded,
        title: 'Comparte Versículos en Estados y Chats',
        description:
            'Genera imágenes elegantes de pasajes bíblicos con fondos devocionales en alta resolución para WhatsApp e Instagram con un solo toque.',
        pointerLabel: '📲 Tarjetas gráficas devocionales',
        demoKind: TourDemoKind.futureModule,
        tabIndex: 0,
        targetKeyResolver: () => bibleKey,
      ),
      TourStepConfig(
        badge: 'DEVOCIONAL DIARIO',
        isNewFeature: true,
        icon: Icons.wb_sunny_rounded,
        title: 'Palabra Diaria con Acceso al Interlineal',
        description:
            'Notificación matutina inspiradora y botón directo para estudiar los términos originales del pasaje diario.',
        pointerLabel: '☀️ Versículo del día',
        demoKind: TourDemoKind.futureModule,
        tabIndex: 3,
        targetKeyResolver: () => studyTabsKey,
      ),
      TourStepConfig(
        badge: 'ESTUDIO COMPARATIVO',
        isNewFeature: true,
        icon: Icons.alt_route_rounded,
        title: 'Treasury of Scripture Knowledge Integrado',
        description:
            'Consulta referencias cruzadas TSK en línea vinculadas directamente a cada versículo de estudio.',
        pointerLabel: '🔀 Referencias cruzadas TSK',
        demoKind: TourDemoKind.futureModule,
        tabIndex: 2,
        targetKeyResolver: () => dictionaryControlsKey,
      ),
    ];
  }
}
