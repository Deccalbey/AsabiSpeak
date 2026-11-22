import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

const String sandboxId = 'asabispeak-2jeeoq';

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
      theme: ThemeData.dark(),
      home: const OdaEkrani(),
    );
  }
}

Future<Map<String, String>> tokenAl(String oda, String isim) async {
  final r = await http.post(
    Uri.parse('https://cloud-api.livekit.io/api/v2/sandbox/connection-details'),
    headers: {
      'X-Sandbox-ID': sandboxId,
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'roomName': oda,
      'room_name': oda,
      'participantName': isim,
      'participant_name': isim,
      'participantIdentity': isim,
      'participant_identity': isim,
    }),
  );
  if (r.statusCode < 200 || r.statusCode >= 300) {
    throw Exception('Token hatası ${r.statusCode}: ${r.body}');
  }
  final j = jsonDecode(r.body);
  return {
    'url': (j['serverUrl'] ?? j['server_url']).toString(),
    'token': (j['participantToken'] ?? j['participant_token']).toString(),
  };
}

class OdaEkrani extends StatefulWidget {
  const OdaEkrani({Key? key}) : super(key: key);

  @override
  State<OdaEkrani> createState() => _OdaEkraniState();
}

class _OdaEkraniState extends State<OdaEkrani> {
  final TextEditingController odaCtrl = TextEditingController(text: 'ekip');
  final TextEditingController isimCtrl = TextEditingController();

  bool overlayAktif = false;
  bool bagli = false;
  bool micAcik = false;
  String durum = 'Bağlı değil';
  Room? room;

  @override
  void initState() {
    super.initState();
    _arkaplanServisiniBaslat();
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event == 'toggle') {
        micToggle();
      }
    });
  }

  @override
  void dispose() {
    room?.disconnect();
    odaCtrl.dispose();
    isimCtrl.dispose();
    super.dispose();
  }

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
      debugPrint("Arka plan servis hatası: $e");
    }
  }

  Future<void> katil() async {
    final isim = isimCtrl.text.trim();
    final oda = odaCtrl.text.trim();
    if (isim.isEmpty || oda.isEmpty) {
      setState(() => durum = 'İsim ve oda adı yaz');
      return;
    }

    final izin = await Permission.microphone.request();
    if (!izin.isGranted) {
      setState(() => durum = 'Mikrofon izni verilmedi');
      return;
    }

    setState(() => durum = 'Bağlanıyor...');
    try {
      final t = await tokenAl(oda, isim);
      final r = Room();
      r.addListener(() {
        if (mounted) setState(() {});
      });
      await r.connect(t['url']!, t['token']!);
      await r.localParticipant?.setMicrophoneEnabled(false);
      room = r;
      setState(() {
        bagli = true;
        micAcik = false;
        durum = 'Bağlandı';
      });
      FlutterOverlayWindow.shareData('mic:off');
    } catch (e) {
      setState(() => durum = 'Hata: $e');
    }
  }

  Future<void> ayril() async {
    await room?.disconnect();
    room = null;
    setState(() {
      bagli = false;
      micAcik = false;
      durum = 'Bağlı değil';
    });
    FlutterOverlayWindow.shareData('mic:off');
  }

  Future<void> micToggle() async {
    if (!bagli || room == null) {
      FlutterOverlayWindow.shareData('mic:off');
      return;
    }
    final yeni = !micAcik;
    await room!.localParticipant?.setMicrophoneEnabled(yeni);
    setState(() => micAcik = yeni);
    FlutterOverlayWindow.shareData(yeni ? 'mic:on' : 'mic:off');
  }

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
      setState(() => overlayAktif = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kisiSayisi = bagli ? (room?.remoteParticipants.length ?? 0) + 1 : 0;
    return Scaffold(
      appBar: AppBar(title: const Text("AsabiSpeak - Ses Kanalı")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: isimCtrl,
              enabled: !bagli,
              decoration: const InputDecoration(labelText: 'İsmin'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: odaCtrl,
              enabled: !bagli,
              decoration: const InputDecoration(labelText: 'Oda adı'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: bagli ? ayril : katil,
              style: ElevatedButton.styleFrom(
                backgroundColor: bagli ? Colors.red : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(bagli ? 'Odadan Ayrıl' : 'Odaya Katıl'),
            ),
            const SizedBox(height: 12),
            Text(
              bagli ? '$durum • Odadaki kişi: $kisiSayisi' : durum,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: bagli ? micToggle : null,
              icon: Icon(micAcik ? Icons.mic : Icons.mic_off),
              label: Text(micAcik ? 'Mikrofon Açık' : 'Mikrofon Kapalı'),
              style: ElevatedButton.styleFrom(
                backgroundColor: micAcik ? Colors.green : Colors.grey.shade800,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _floatingButonuBaslat,
              icon: const Icon(Icons.layers),
              label: Text(overlayAktif ? "Yüzen Buton Aktif" : "Oyun İçi Yüzen Butonu Aç"),
              style: ElevatedButton.styleFrom(
                backgroundColor: overlayAktif ? Colors.green : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
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
  State<YuvarlakMikrofonButonu> createState() => _YuvarlakMikrofonButonuState();
}

class _YuvarlakMikrofonButonuState extends State<YuvarlakMikrofonButonu> {
  bool sesAcik = false;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event == 'mic:on') setState(() => sesAcik = true);
      if (event == 'mic:off') setState(() => sesAcik = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => FlutterOverlayWindow.shareData('toggle'),
        child: Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: sesAcik ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: const [
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
