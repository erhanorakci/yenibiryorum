import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants.dart';
import 'core/notification_service.dart';
import 'screens/home/home_screen.dart'; // <--- İŞTE BU EKSİKTİ!

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Bildirim Servisini Başlat
  await BildirimServisi().baslat();

  runApp(const YorumUygulamasi());
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
