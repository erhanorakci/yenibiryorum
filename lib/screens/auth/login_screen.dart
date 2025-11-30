import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import 'register_screen.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});
  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _load = false;

  Future<void> _giris() async {
    if (_emailC.text.isEmpty || _passC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen alanları doldurun.")),
      );
      return;
    }
    setState(() => _load = true);

    try {
      UserCredential uc = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailC.text.trim(),
            password: _passC.text.trim(),
          );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(uc.user!.uid)
          .get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        if (data['durum'] == 'banli') {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Erişim Engellendi"),
                content: const Text(
                  "Hesabınız topluluk kurallarına uymadığı için askıya alınmıştır.\n\nDestek için: admin@yenibiryorum.com",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tamam"),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String hataMesaji = "Bir hata oluştu.";
      switch (e.code) {
        case 'user-not-found':
          hataMesaji = "Kullanıcı bulunamadı.";
          break;
        case 'wrong-password':
          hataMesaji = "Şifre hatalı.";
          break;
        case 'invalid-credential':
          hataMesaji = "E-posta veya şifre hatalı.";
          break;
        default:
          hataMesaji = "Giriş hatası: ${e.message}";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hataMesaji), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _load = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          // Üstten boşluk (padding) vererek logoyu istediğin kadar yukarı/aşağı taşıyabilirsin.
          // Şimdilik 40 verdim, daha yukarı istersen azalt (örn: 20).
          padding: const EdgeInsets.fromLTRB(30, 40, 30, 30),
          child: Column(
            // Elemanları yukarıdan başlat (Center yerine start)
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // --- LOGO (BOYUT 250) ---
              Image.asset(
                'assets/icon/app_icon.png',
                height: 250,
                width: 250,
                fit: BoxFit.contain,
              ),

              // Bu boşluğu azalttım (Logo ile Başlık arası)
              const SizedBox(height: 5),

              const Text(
                "Giriş Yap",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              // Bu boşluğu azalttım (Başlık ile Kutu arası)
              const SizedBox(height: 15),

              TextField(
                controller: _emailC,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "E-posta",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: _passC,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Şifre",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 25),

              _load
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAnaRenk,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _giris,
                        child: const Text("GİRİŞ YAP"),
                      ),
                    ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const KayitEkrani()),
                ),
                child: const Text("Kayıt Ol"),
              ),

              // Alt boşluk (Klavye açılınca rahat etsin diye)
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
