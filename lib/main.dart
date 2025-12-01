import 'dart:io'; // Platform kontrolü için gerekli
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/constants.dart';
import 'core/notification_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // BURASI ÇOK ÖNEMLİ: iOS ise ayarları elle veriyoruz, Android ise otomatiktir.
    if (Platform.isIOS) {
      await Firebase.initializeApp(
        name: "YorumPlatformuIOS", // Özel bir isim veriyoruz çakışmasın diye
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCr3d9xsVRaS_2njjo2ZG1dj0lKD94smUg',
          appId: '1:929852331620:ios:eb0ae4d7413f08242a7171',
          messagingSenderId: '929852331620',
          projectId: 'yenibiryorum-fe0e8',
          storageBucket: 'yenibiryorum-fe0e8.firebasestorage.app',
          iosBundleId: 'com.erhanorakci.yenibiryorum',
        ),
      );
    } else {
      // Android için standart başlatma (google-services.json'dan okur)
      await Firebase.initializeApp();
    }

    // Bildirim servisini başlat (Hata verirse uygulamayı durdurmasın)
    try {
      await BildirimServisi().baslat();
    } catch (e) {
      print("Bildirim servisi hatası: $e");
    }

    runApp(const YorumUygulamasi());
  } catch (e) {
    // Hata durumunda Kırmızı Ekranı göster
    runApp(BaslatmaHatasiUygulamasi(hataMesaji: e.toString()));
  }
}

// --- BAŞARILI DURUM UYGULAMASI ---
class YorumUygulamasi extends StatelessWidget {
  const YorumUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yorum Platformu',
      theme: ThemeData(
        scaffoldBackgroundColor: kArkaPlan,
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(seedColor: kAnaRenk),
      ),
      home: const YetkiKontrolu(),
    );
  }
}

// --- GİRİŞ KONTROLÜ ---
class YetkiKontrolu extends StatelessWidget {
  const YetkiKontrolu({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const AnaSayfa();
      },
    );
  }
}

// --- HATA DURUMU UYGULAMASI ---
class BaslatmaHatasiUygulamasi extends StatelessWidget {
  final String hataMesaji;
  const BaslatmaHatasiUygulamasi({super.key, required this.hataMesaji});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 80),
                const SizedBox(height: 20),
                const Text(
                  "Uygulama Başlatılamadı",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    hataMesaji,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
