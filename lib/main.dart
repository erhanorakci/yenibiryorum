import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/constants.dart';
import 'core/notification_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';

void main() {
  // Hataları yakalamak için önce uygulamayı başlatıyoruz
  WidgetsFlutterBinding.ensureInitialized();
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
      // Uygulama açılınca direkt Başlatıcıyı çağırıyoruz
      home: const UygulamaBaslatici(),
    );
  }
}

class UygulamaBaslatici extends StatefulWidget {
  const UygulamaBaslatici({super.key});

  @override
  State<UygulamaBaslatici> createState() => _UygulamaBaslaticiState();
}

class _UygulamaBaslaticiState extends State<UygulamaBaslatici> {
  // Firebase başlatma durumunu yöneten değişken
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  void initState() {
    super.initState();
    // Bildirim servisini başlatmayı deniyoruz (Hata verirse uygulamayı durdurmaz)
    _bildirimleriBaslat();
  }

  Future<void> _bildirimleriBaslat() async {
    try {
      await BildirimServisi().baslat();
    } catch (e) {
      print("Bildirim hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        // 1. Hata Varsa (Gri ekran yerine kırmızı hata ekranı gösterir)
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Başlatma Hatası",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Hata Detayı:\n${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 2. Bağlantı Tamamlandıysa (Ana ekrana yönlendir)
        if (snapshot.connectionState == ConnectionState.done) {
          return const YetkiKontrolu();
        }

        // 3. Bekleniyorsa (Yükleniyor göstergesi)
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Yorum Dünyası Başlatılıyor..."),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Giriş yapmış mı kontrol eden katman
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
        // Kullanıcı giriş yapmışsa veya yapmamışsa Ana Sayfaya atıyoruz.
        // (İstersen snapshot.hasData yoksa GirisEkrani() yapabilirsin)
        return const AnaSayfa();
      },
    );
  }
}
