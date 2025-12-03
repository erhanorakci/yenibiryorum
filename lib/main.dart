import 'dart:async';
import 'dart:io'; // Platform kontrolü (Sadece mobilde çalışır, web'de kIsWeb kullanılır)
import 'package:flutter/foundation.dart'; // kIsWeb için gerekli
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/constants.dart';
import 'core/notification_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';

void main() {
  // Hataları yakalamak için ZoneGuarded yapısı
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const YorumUygulamasi());
    },
    (error, stack) {
      print("🛑 Global Hata: $error");
    },
  );
}

class YorumUygulamasi extends StatefulWidget {
  const YorumUygulamasi({super.key});

  @override
  State<YorumUygulamasi> createState() => _YorumUygulamasiState();
}

class _YorumUygulamasiState extends State<YorumUygulamasi> {
  // Başlangıç durumunu kontrol eden değişkenler
  bool _isInitialized = false;
  String _statusMessage = "Uygulama Başlatılıyor...";
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  Future<void> _baslat() async {
    try {
      // --- 1. FIREBASE BAŞLATMA (PLATFORMA GÖRE AKILLI AYAR) ---

      if (kIsWeb) {
        // *** WEB İÇİN (Firebase Konsolundan aldığın 'const firebaseConfig' bilgileri) ***
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyCm8XhSZD941_YFbEbqNIR24nIPk-U7qWg",
            authDomain: "yenibiryorum-fe0e8.firebaseapp.com",
            projectId: "yenibiryorum-fe0e8",
            storageBucket: "yenibiryorum-fe0e8.firebasestorage.app",
            messagingSenderId: "929852331620",
            appId: "1:929852331620:web:a3f819a280a2a54e2a7171",
          ),
        );
      }
      // *** iOS İÇİN (Manuel Ayar - Zaten vardı, korundu) ***
      else if (Platform.isIOS) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyCr3d9xsVRaS_2njjo2ZG1dj0lKD94smUg", // iOS API Key
            appId: "1:929852331620:ios:eb0ae4d7413f08242a7171", // iOS App ID
            messagingSenderId: "929852331620",
            projectId: "yenibiryorum-fe0e8",
            storageBucket: "yenibiryorum-fe0e8.firebasestorage.app",
            iosBundleId: "com.erhanorakci.yenibiryorum",
          ),
        );
      }
      // *** ANDROID İÇİN (Otomatik - google-services.json'dan okur) ***
      else {
        await Firebase.initializeApp();
      }
      // -----------------------------------------------------------

      setState(() => _statusMessage = "Bildirimler ayarlanıyor...");

      // 2. BİLDİRİM SERVİSİ (Sadece Mobilde çalıştır, Web'de hata verir)
      if (!kIsWeb) {
        try {
          await BildirimServisi().baslat();
        } catch (e) {
          print("Bildirim hatası (Önemsiz): $e");
        }
      }

      // Her şey yolunda
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      // Kritik Hata Durumu
      print("🔥 BAŞLATMA HATASI: $e");
      setState(() {
        _hasError = true;
        _statusMessage = "Hata: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer hata varsa Kırmızı Ekran göster (Beyaz ekranda kalmasın)
    if (_hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    "Başlatılamadı",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Eğer henüz hazır değilse Loading göster
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white, // Veya kAnaRenk
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo varsa buraya Image.asset ekleyebilirsin
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Her şey hazırsa asıl uygulamayı göster
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

// Giriş Kontrolü
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
        // İsteğe bağlı: Giriş zorunlu değilse direkt AnaSayfa
        return const AnaSayfa();
      },
    );
  }
}
