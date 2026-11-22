import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AsabiSpeakApp());
}

class AsabiSpeakApp extends StatelessWidget {
  const AsabiSpeakApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Pil tasarrufu için koyu tema
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

  @override
  void initState() {
    super.initState();
    _arkaplanServisiniBaslat();
  }

  // Uygulama açıldıktan sonra arka plan servisini güvenli bir şekilde başlatır
  void _arkaplanServisiniBaslat() async {
    try {
      const androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: "AsabiSpeak Aktif",
        notificationText: "Ekip sesli sohbet arka planda çalışıyor.",
        notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
      );
      
      await FlutterBackground.initialize(androidConfig: androidConfig);
      await FlutterBackground.enableBackgroundExecution();
    } catch (e) {
      print("Arka plan servis hatası: $e");
    }
  }

  // Yüzen pencereyi (Floating Button) ekranda başlatma fonksiyonu
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
      setState(() {
        overlayAktif = true;
      });
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
            Text(
              "Ekip Ses Odası Hazır!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _floatingButonuBaslat,
              icon: Icon(Icons.layers),
              label: Text(overlayAktif ? "Yüzen Buton Aktif" : "Oyun İçi Yüzen Butonu Aç"),
              style: ElevatedButton.styleFrom(
                backgroundColor: overlayAktif ? Colors.green : Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// OYUN EKRANININ ÜZERİNDEKİ YUVARLAK MİKROFON BUTONU
// ==========================================
@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: YuvarlakMikrofonButonu(),
    ),
  );
}

class YuvarlakMikrofonButonu extends StatefulWidget {
  const YuvarlakMikrofonButonu({Key? key}) : super(key: key);

  @override
  _YuvarlakMikrofonButonuState createState() => _YuvarlakMikrofonButonuState();
}

class _YuvarlakMikrofonButonuState extends State<YuvarlakMikrofonButonu> {
  bool sesAcik = false; // Başlangıçta kapalı (kırmızı)

  void _micToggleEt() {
    setState(() {
      sesAcik = !sesAcik;
      // Buraya ses açma/kapama tetikleyicisi gelecek
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _micToggleEt,
        child: Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: sesAcik ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 6, spreadRadius: 2),
            ],
          ),
          child: Icon(
            sesAcik ? Icons.mic : Icons.mic_off,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
