import 'dart:io';
void main() {
  final files = [
    r'C:\Users\Administrator\Desktop\星映 - 副本\packages\ui_kit\lib\star_ui_kit.dart',
    r'C:\Users\Administrator\Desktop\星映 - 副本\apps\desktop\lib\src\pages\detail_page.dart',
    r'C:\Users\Administrator\Desktop\星映 - 副本\apps\desktop\lib\src\pages\search_page.dart',
    r'C:\Users\Administrator\Desktop\星映 - 副本\apps\mobile\lib\src\pages\search_page.dart',
    r'C:\Users\Administrator\Desktop\星映 - 副本\apps\tv\lib\src\pages\detail_page.dart',
    r'C:\Users\Administrator\Desktop\星映 - 副本\apps\tv\lib\src\widgets\focus_widgets.dart',
    r'C:\Users\Administrator\Desktop\星映 - 副本\packages\ui_kit\lib\src\library_ui.dart',
  ];
  for (final p in files) {
    final f = File(p);
    if (!f.existsSync()) continue;
    var t = f.readAsStringSync();
    t = t.replaceAll("                    'Referer': 'https://',\n", "");
    f.writeAsStringSync(t);
  }
  print('referer cleaned');
}
