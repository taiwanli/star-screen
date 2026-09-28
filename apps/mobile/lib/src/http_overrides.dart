import 'dart:io';

class StarHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) => true;
    client.userAgent = 'Mozilla/5.0 StarScreen/0.1';
    return client;
  }
}

void installStarHttpOverrides() {
  HttpOverrides.global = StarHttpOverrides();
}
