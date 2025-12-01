import 'dart:async'; // Hata yakalama için gerekli
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants.dart';
import 'core/notification_service.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  // Hataları global olarak yakalamak için ZoneGuarded kullanıyoruz
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        // Firebase'i başlatmayı dene
        await Firebase.initializeApp();
        print("✅ Firebase başarıyla başlatıldı.");
      } catch (e) {
        // Hata verirse konsola yaz ama uygulamayı DURDURMA
        print("⚠️ Firebase başlatma hatası: $e");
      }

      try {
        // Bildirim servisini başlatmayı dene
        await BildirimServisi().baslat();
        print("✅ Bildirim servisi başlatıldı.");
      } catch (e) {
        // Hata verirse konsola yaz ama devam et
        print("⚠️ Bildirim servisi hatası: $e");
      }

      runApp(const YorumUygulamasi());
    },
    (error, stack) {
      // Beklenmedik diğer tüm hataları burada yakala
      print("🛑 Kritik Uygulama Hatası: $error");
    },
  );
}

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
      // Artık mor ekran değil, direkt Ana Sayfa açılacak
      home: const AnaSayfa(),
    );
  }
}
