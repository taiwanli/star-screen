import 'dart:io';
void main() {
  for (final app in ['desktop', 'mobile', 'tv']) {
    final f = File(r'C:\Users\Administrator\Desktop\星映 - 副本\apps\' + app + r'\lib\src\pages\player_page.dart');
    var t = f.readAsStringSync();
    t = t.replaceAll(
      '''                final event = snap.data;
                if (event is DomainPlayerPosition) {
                  _lastPos = event.positionSec;
                  _lastDur = event.durationSec;
                }
                final position = _lastPos;
                final duration = _lastDur;''',
      '''                final st = controller.player.state;
                final position = st.position.inSeconds;
                final duration = st.duration.inSeconds;''',
    );
    t = t.replaceAll(
      '''            final event = snap.data;
            if (event is DomainPlayerPosition) {
              _lastPos = event.positionSec;
              _lastDur = event.durationSec;
            }
            final position = _lastPos;
            final duration = _lastDur;''',
      '''            final st = controller.player.state;
            final position = st.position.inSeconds;
            final duration = st.duration.inSeconds;''',
    );
    // TV uses widget.controller
    t = t.replaceAll(
      '''                final event = snap.data;
                if (event is DomainPlayerPosition) {
                  _lastPos = event.positionSec;
                  _lastDur = event.durationSec;
                }
                final position = _lastPos;
                final duration = _lastDur;''',
      '''                final st = widget.controller.player.state;
                final position = st.position.inSeconds;
                final duration = st.duration.inSeconds;''',
    );
    // remove unused fields
    t = t.replaceAll('  int _lastPos = 0;\n  int _lastDur = 0;\n', '');
    f.writeAsStringSync(t);
    print('pos $app');
  }
}
