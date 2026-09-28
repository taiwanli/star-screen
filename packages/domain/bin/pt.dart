import 'dart:io';
import 'package:star_domain/star_domain.dart';

void main(List<String> args) {
  for (final p in args) {
    final raw = File(p).readAsStringSync();
    final nm = p.split(Platform.pathSeparator).last;
    print('===== $nm =====');
    final isSR = StarRuleParser.looksLikeStarRule(raw);
    print('  looksLikeStarRule = $isSR');
    if (isSR) {
      final sr = StarRuleImporter.toParseReport(raw);
      final k = <String,int>{};
      for (final s in sr.sources) { k[s.kind.name]=(k[s.kind.name]??0)+1; }
      print('  [StarRule] sources=${sr.sources.length} lives=${sr.lives.length} kinds=$k');
      for (final i in sr.issues.take(4)) print('    ! $i');
    } else {
      final r = TvBoxConfigParser.parse(raw: raw);
      final k = <String,int>{};
      for (final s in r.sources) { k[s.kind.name]=(k[s.kind.name]??0)+1; }
      print('  [TVBox] sources=${r.sources.length} lives=${r.lives.length} kinds=$k');
      for (final i in r.issues.take(4)) print('    ! $i');
    }
    print('');
  }
}
