import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:berea_interlineal/data/models.dart';
import 'package:berea_interlineal/features/dictionary/widgets/linked_strong_text.dart';

void main() {
  test('StrongEntry serialization with exegesis fields', () {
    const entry = StrongEntry(
      language: 'hebrew',
      code: 776,
      lemma: 'אֶרֶץ',
      pronunciation: 'érets',
      derivation: 'de una raíz que no se usa que prob. sign. ser firme',
      definition: 'tierra',
      rvDefinition: 'campo, tierra, país',
      stepbible: 'tierra: territorio, suelo, país',
      similarities: '⚖️ Distinción del concepto Tierra: #H776 vs #H127',
      compareCodes: '127,8398',
      derivedCodes: '772,777',
    );

    final map = entry.toMap();
    expect(map['language'], equals('hebrew'));
    expect(map['code'], equals(776));
    expect(map['similarities'], contains('#H776'));
    expect(map['compare_codes'], equals('127,8398'));
    expect(map['derived_codes'], equals('772,777'));

    final fromMap = StrongEntry.fromMap(map);
    expect(fromMap.similarities, equals(entry.similarities));
    expect(fromMap.compareCodes, equals('127,8398'));
    expect(fromMap.derivedCodes, equals('772,777'));
  });

  test('StrongRelationItem models relations correctly', () {
    const item = StrongRelationItem(
      language: 'greek',
      code: 5368,
      lemma: 'φιλέω',
      pronunciation: 'philéo',
      relationType: 'compares_with',
    );

    expect(item.relationType, equals('compares_with'));
    expect(item.code, equals(5368));
  });

  testWidgets('LinkedStrongText suppresses empty dashes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LinkedStrongText(
            text: '',
            currentLanguage: 'hebrew',
          ),
        ),
      ),
    );

    expect(find.text('—'), findsNothing);
  });
}
