// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:js' as js;

/// Web CMS: short beep + optional system notification (uses OS sound when allowed).
Future<void> playAdminNotificationAlert({String? title, String? body}) async {
  _playBeep();
  final t = title?.trim();
  if (t == null || t.isEmpty) return;
  if (html.Notification.supported != true) return;
  try {
    html.Notification(
      t,
      body: body?.trim() ?? '',
      icon: '/icons/Icon-192.png',
    );
  } catch (_) {
    // Permission may be denied even after FCM requestPermission.
  }
}

void _playBeep() {
  try {
    js.context.callMethod('eval', <Object?>[
      '''
(function(){
  try {
    var AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    var ctx = new AC();
    var osc = ctx.createOscillator();
    var gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.value = 880;
    gain.gain.setValueAtTime(0.18, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.22);
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.22);
  } catch (e) {}
})();
''',
    ]);
  } catch (_) {}
}
