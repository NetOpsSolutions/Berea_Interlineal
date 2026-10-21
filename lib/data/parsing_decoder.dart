class ParsingDecoder {
  // Un codigo morfolologico 'compacto' del sitio/semilla esta en MAYUSCULAS
  // (SUBS.F.SG.A, N-NSF, VERBO.QAL.PERF.P3.M.SG, PREP, ART, CONJ...).
  // Cualquier cosa con minusculas/acentos/espacios es morfologia legible en
  // espanol ('preposicion', 'Sustantivo-Dativo-Singular-Femenino') y se muestra
  // tal cual (los guiones sin espacios se vuelven comas para legibilidad).
  static final RegExp _compact = RegExp(r'^[A-Z0-9.\-]+$');
  static final RegExp _dashList = RegExp(r'^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9ªº]+(?:-[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9ªº]+)+$');

  static bool _isCompact(String c) => _compact.hasMatch(c);

  static String decode(String code, String language) {
    final c = code.trim();
    if (c.isEmpty) return 'Sin análisis morfológico';

    if (!_isCompact(c)) {
      // Morfologia legible del sitio.
      if (_dashList.hasMatch(c)) {
        return c.split('-').map((p) => p.trim()).where((p) => p.isNotEmpty).join(', ');
      }
      return c[0].toUpperCase() + c.substring(1);
    }

    // Codigo compacto -> decodificar (semilla / formatos legacy).
    final up = c.toUpperCase();
    return language == 'hebrew' ? _he(up) : _gr(up);
  }

  static String _he(String code) =>
      code.split('.').map(_heTag).where((t) => t.isNotEmpty).join(', ');
  static String _heTag(String t) {
    switch (t) {
      case 'SUBS': return 'Sustantivo';
      case 'VERBO': return 'Verbo';
      case 'ADJ': case 'ADJETIVO': return 'Adjetivo';
      case 'ADV': case 'ADVERBIO': return 'Adverbio';
      case 'PRON': case 'PRONOMBRE': return 'Pronombre';
      case 'PREP': return 'Preposición';
      case 'CONJ': return 'Conjunción';
      case 'ART': return 'Artículo';
      case 'NUM': case 'NUMERAL': return 'Numeral';
      case 'INTERJ': return 'Interjección';
      case 'M': case 'MASC': return 'masculino';
      case 'F': case 'FEM': return 'femenino';
      case 'U': case 'COMUN': return 'común';
      case 'S': case 'SG': case 'SING': return 'singular';
      case 'P': case 'PL': case 'PLUR': return 'plural';
      case 'D': case 'DU': case 'DUAL': return 'dual';
      case 'A': case 'ABS': return 'absoluto';
      case 'C': case 'CONSTR': return 'constructo';
      case 'PERF': return 'perfecto';
      case 'IMPF': return 'imperfecto';
      case 'IMPV': return 'imperativo';
      case 'INF': return 'infinitivo';
      case 'PART': return 'participio';
      case 'QAL': return 'Qal';
      case 'NIPHAL': return 'Niphal';
      case 'PIEL': return 'Piel';
      case 'PUAL': return 'Pual';
      case 'HIFIL': return 'Hifil';
      case 'HOPHAL': return 'Hophal';
      case 'HITPAEL': return 'Hitpael';
      case 'P1': return '1ª persona';
      case 'P2': return '2ª persona';
      case 'P3': return '3ª persona';
      default: return t;
    }
  }
  static String _gr(String code) {
    final p = code.split('-');
    final r = <String>[];
    if (p.isEmpty) return code;
    r.add(_grType(p.first));
    if (p.length > 1) {
      final s = p[1];
      if (s == 'PRI') { r.add('nombre propio'); }
      else if (s.length == 3 && !s.contains('AI')) {
        r.add(_grCase(s[0])); r.add(_grNum(s[1])); r.add(_grGen(s[2]));
      } else { r.add(_grVerb(s)); }
    }
    if (p.length > 2) r.add(_grPerson(p[2]));
    return r.where((x) => x.isNotEmpty).join(', ');
  }
  static String _grType(String t) {
    switch (t) {
      case 'N': return 'Sustantivo';
      case 'V': return 'Verbo';
      case 'ADJ': return 'Adjetivo';
      case 'ADV': return 'Adverbio';
      case 'PRON': return 'Pronombre';
      case 'PREP': return 'Preposición';
      case 'CONJ': return 'Conjunción';
      case 'ART': return 'Artículo';
      case 'NUM': return 'Numeral';
      case 'PTCP': return 'Participio';
      default: return t;
    }
  }
  static String _grCase(String t) {
    switch (t) {
      case 'N': return 'nominativo';
      case 'G': return 'genitivo';
      case 'D': return 'dativo';
      case 'A': return 'acusativo';
      case 'V': return 'vocativo';
      default: return t;
    }
  }
  static String _grNum(String t) {
    switch (t) {
      case 'S': return 'singular';
      case 'P': return 'plural';
      case 'D': return 'dual';
      default: return t;
    }
  }
  static String _grGen(String t) {
    switch (t) {
      case 'M': return 'masculino';
      case 'F': return 'femenino';
      case 'N': return 'neutro';
      case 'U': return 'común';
      default: return t;
    }
  }
  static String _grVerb(String t) {
    final o = <String>[];
    if (t.contains('P')) o.add('presente');
    if (t.contains('I')) o.add('imperfecto');
    if (t.contains('A')) o.add('aoristo');
    if (t.contains('F')) o.add('futuro');
    if (t.contains('R')) o.add('perfecto');
    if (t.contains('L')) o.add('pluscuamperfecto');
    if (t.endsWith('I')) o.add('indicativo');
    if (t.endsWith('S')) o.add('subjuntivo');
    if (t.endsWith('O')) o.add('optativo');
    if (t.endsWith('M')) o.add('imperativo');
    if (t.endsWith('N')) o.add('infinitivo');
    return o.isEmpty ? t : o.join(', ');
  }
  static String _grPerson(String t) {
    if (t.isEmpty) return '';
    String per = t.startsWith('1') ? '1ª persona' : t.startsWith('2') ? '2ª persona' : t.startsWith('3') ? '3ª persona' : '';
    String num = t.endsWith('S') ? 'singular' : t.endsWith('P') ? 'plural' : t.endsWith('D') ? 'dual' : '';
    return [per, num].where((x) => x.isNotEmpty).join(', ');
  }
}
