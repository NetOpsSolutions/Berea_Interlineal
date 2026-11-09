import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:berea_interlineal/core/tour/interactive_tour_overlay.dart';
import 'package:berea_interlineal/core/tour/tour_steps_factory.dart';
import 'package:berea_interlineal/data/book_catalog.dart';
import 'package:berea_interlineal/data/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('v1.4.0 Model & Tour Specifications', () {
    test('BookSummary and BiblicalAuthor serialization integrity', () {
      const author = BiblicalAuthor(
        authorId: 32,
        nameEs: 'Pablo',
        nameOriginal: 'Παῦλος',
        strongCode: 'G3972',
        era: 'Siglo I d.C.',
        occupation: 'Apóstol a los gentiles',
        callingVerse: 'Hechos 9:1-16',
        biography: 'Saulo de Tarso...',
      );

      final map = author.toMap();
      final fromMap = BiblicalAuthor.fromMap(map);
      expect(fromMap.authorId, equals(32));
      expect(fromMap.nameEs, equals('Pablo'));
      expect(fromMap.strongCode, equals('G3972'));

      const summary = BookSummary(
        bookId: 45,
        bookCode: 'Ro',
        bookName: 'Romanos',
        testament: 'NT',
        category: 'Epístolas Paulinas',
        authorId: 32,
        authorName: 'Pablo',
        authorStrongCode: 'G3972',
        recipients: 'Iglesias en Roma',
        dateWritten: 'c. 57 d.C.',
        historicalContext: 'Redactada desde Corinto...',
        keyThemes: 'Justificación por la fe',
        keyVerseRef: 'Romanos 1:16-17',
        practicalApplication: '1. Vivir por la gracia...',
      );

      final sMap = summary.toMap();
      final sFromMap = BookSummary.fromMap(sMap);
      expect(sFromMap.bookId, equals(45));
      expect(sFromMap.bookCode, equals('Ro'));
      expect(sFromMap.keyVerseRef, equals('Romanos 1:16-17'));
    });

    test('v1.4.0 Interactive Tour Master Sequence conforms strictly to 8-step plan', () {
      final kBible = GlobalKey();
      final kDict = GlobalKey();
      final kStudy = GlobalKey();
      final kSearch = GlobalKey();
      final kSettings = GlobalKey();
      final kDrawer = GlobalKey();
      final kSummary = GlobalKey();
      final kTheological = GlobalKey();
      final kTheme = GlobalKey();

      final steps = TourStepsFactory.getStepsForVersion(
        version: '1.4.0',
        bibleKey: kBible,
        searchBarKey: kSearch,
        dictionaryControlsKey: kDict,
        studyTabsKey: kStudy,
        settingsKey: kSettings,
        tourDrawerButtonKey: kDrawer,
        tourBookSummaryButtonKey: kSummary,
        tourDrawerTheologicalKey: kTheological,
        tourThemeToggleKey: kTheme,
      );

      expect(steps.length, equals(9));

      // Paso 1: BIENVENIDA & LECTURA
      expect(steps[0].badge, equals('BIENVENIDA & LECTURA'));
      expect(steps[0].title, equals('Lector Bíblico Interlineal Continuo'));
      expect(steps[0].tabIndex, equals(0));

      // Paso 2: NUEVA NAVEGACIÓN
      expect(steps[1].badge, equals('NUEVA NAVEGACIÓN'));
      expect(steps[1].title, equals('Nuevo Menú Lateral: Persiana de Estudio (☰)'));
      expect(steps[1].targetKeyResolver(), equals(kDrawer));

      // Paso 3: TEMA RÁPIDO (Alternador Sol/Luna)
      expect(steps[2].badge, equals('TEMA RÁPIDO'));
      expect(steps[2].title, equals('Alternador de Modo Claro y Oscuro (☀️/🌙)'));
      expect(steps[2].targetKeyResolver(), equals(kTheme));

      // Paso 4: NUEVO MÓDULO (Resumen 66 Libros)
      expect(steps[3].badge, equals('NUEVO MÓDULO'));
      expect(steps[3].title, equals('Resumen Bíblico de los 66 Libros'));
      expect(steps[3].targetKeyResolver(), equals(kSummary));

      // Paso 5: NUEVO MÓDULO (Biografías)
      expect(steps[4].badge, equals('NUEVO MÓDULO'));
      expect(steps[4].title, equals('Biografías de Escritores Sagrados'));

      // Paso 6: LÉXICO Y RAÍCES
      expect(steps[5].badge, equals('LÉXICO Y RAÍCES'));
      expect(steps[5].title, equals('Diccionario Strong Griego y Hebreo'));
      expect(steps[5].tabIndex, equals(1));

      // Paso 7: ESTUDIO PERSONAL
      expect(steps[6].badge, equals('ESTUDIO PERSONAL'));
      expect(steps[6].title, equals('Mi Estudio: Notas, Marcadores e Historial'));
      expect(steps[6].tabIndex, equals(2));

      // Paso 8: TEOLOGÍA VISUAL
      expect(steps[7].badge, equals('TEOLOGÍA VISUAL'));
      expect(steps[7].title, equals('5 Resaltadores Teológicos con Filtro Rápido'));
      expect(steps[7].tabIndex, equals(2));

      // Paso 9: AYUDA PERMANENTE
      expect(steps[8].badge, equals('AYUDA PERMANENTE'));
      expect(steps[8].title, equals('Tu Guía Siempre a Mano'));
      expect(steps[8].demoKind, equals(TourDemoKind.replayGuide));
    });

    test('Scripture reference parser accurately resolves canonical books', () {
      final r1 = BookCatalog.parseReference('Éxodo 3:4-10');
      expect(r1, isNotNull);
      expect(r1!.bookId, equals('Ex'));
      expect(r1.chapter, equals(3));
      expect(r1.verse, equals(4));

      final r2 = BookCatalog.parseReference('1 Samuel 16:11-13');
      expect(r2, isNotNull);
      expect(r2!.bookId, equals('1S'));
      expect(r2.chapter, equals(16));
      expect(r2.verse, equals(11));

      final r3 = BookCatalog.parseReference('Habacuc 2:1-4');
      expect(r3, isNotNull);
      expect(r3!.bookId, equals('Hab'));
      expect(r3.chapter, equals(2));
      expect(r3.verse, equals(1));

      // Multi-reference resolution
      final multi = BookCatalog.parseMultiReferences('Hechos 12:12; 1 Pedro 5:13');
      expect(multi.length, equals(2));
      expect(multi[0].bookId, equals('Hch'));
      expect(multi[0].chapter, equals(12));
      expect(multi[0].verse, equals(12));
      expect(multi[1].bookId, equals('1P'));
      expect(multi[1].chapter, equals(5));
      expect(multi[1].verse, equals(13));

      // Inheriting book context (Daniel 1:8; 2:19-23)
      final multiInherit = BookCatalog.parseMultiReferences('Daniel 1:8; 2:19-23');
      expect(multiInherit.length, equals(2));
      expect(multiInherit[0].bookId, equals('Dn'));
      expect(multiInherit[0].chapter, equals(1));
      expect(multiInherit[0].verse, equals(8));
      expect(multiInherit[1].bookId, equals('Dn'));
      expect(multiInherit[1].chapter, equals(2));
      expect(multiInherit[1].verse, equals(19));
    });
  });
}
