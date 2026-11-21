import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "AsabiSpeak Aktif",
    notificationText: "Ekip sesli sohbet arka planda çalışıyor.",
    notificationIcon: AndroidResource(name: 'drawable_name', defType: 'drawable'),
  );
  await FlutterBackground.initialize(androidConfig: androidConfig);
  await FlutterBackground.enableBackgroundExecution();
  runApp(const AsabiSpeakApp());
}

class AsabiSpeakApp extends StatelessWidget {
  const AsabiSpeakApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: OdaEkrani(),
    );
  }
}

class OdaEkrani extends StatefulWidget {
  @override
  _OdaEkraniState createState() => _OdaEkraniState();
}

class _OdaEkraniState extends State<OdaEkrani> {
  bool overlayAktif = false;
  void _floatingButonuBaslat() async {
    bool? res = await FlutterOverlayWindow.requestPermission();
    if (res == true) {
      await FlutterOverlayWindow.showOverlay(
        height: 100,
        width: 100,
        alignment: OverlayAlignment.centerRight,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
      );
      setState(() { overlayAktif = true; });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AsabiSpeak - Ses Kanalı")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Ekip Ses Odası Hazır!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _floatingButonuBaslat,
              icon: Icon(Icons.layers),
              label: Text(overlayAktif ? "Yüzen Buton Aktif" : "Oyun İçi Yüzen Butonu Aç"),
            ),
          ],
        ),
      ),
    );
  }
}
