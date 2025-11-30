import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Formatlayıcı için gerekli
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';

class KayitEkrani extends StatefulWidget {
  const KayitEkrani({super.key});
  @override
  State<KayitEkrani> createState() => _KayitEkraniState();
}

class _KayitEkraniState extends State<KayitEkrani> {
  final _adC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _telC = TextEditingController();

  bool _load = false;
  bool _kvkkOnay = false;

  // KVKK Metnini Gösteren Fonksiyon
  void _kvkkMetniniGoster() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aydınlatma ve Rıza Metni"),
        content: const SingleChildScrollView(
          child: Text(
            "KVKK Kapsamında Bilgilendirme:\n\n"
            "1. Veri Sorumlusu: Yorum Platformu olarak kişisel verilerinizi işliyoruz.\n\n"
            "2. İşlenen Veriler: Ad, soyad, e-posta, telefon numarası ve yaptığınız yorumlar.\n\n"
            "3. Paylaşım İzni: Yaptığınız yorumların doğruluğunun teyit edilmesi ve şikayetlerin çözümü amacıyla; ad, soyad ve iletişim bilgilerinizin, yorum yaptığınız ilgili firma yetkilileri ile paylaşılmasına izin veriyorsunuz.\n\n"
            "4. Haklarınız: Dilediğiniz zaman bu izni iptal etme veya verilerinizi sildirme hakkına sahipsiniz.",
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kAnaRenk,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() => _kvkkOnay = true);
              Navigator.pop(context);
            },
            child: const Text("Okudum, Onaylıyorum"),
          ),
        ],
      ),
    );
  }

  Future<void> _kayit() async {
    // 1. Genel Validasyonlar
    if (_emailC.text.isEmpty || _passC.text.isEmpty || _adC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    // 2. Telefon Numarası Kontrolü (Uzunluk)
    // Format: 0(5XX) XXX XX XX (Toplam 15 karakter olmalı)
    if (_telC.text.length < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Lütfen geçerli bir telefon numarası girin.\nÖrn: 0(5xx) xxx xx xx",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 3. KVKK Onayı Kontrolü
    if (!_kvkkOnay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Devam etmek için Aydınlatma Metnini onaylamalısınız."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _load = true);

    try {
      // 4. Firebase Auth ile Kullanıcı Oluşturma
      UserCredential uc = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailC.text.trim(),
            password: _passC.text.trim(),
          );

      // 5. İsim Güncelleme
      await uc.user?.updateDisplayName(_adC.text.trim());

      // 6. Firestore'a Ekstra Bilgileri Kaydetme
      await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(uc.user!.uid)
          .set({
            'adSoyad': _adC.text.trim(),
            'email': _emailC.text.trim(),
            'telefon': _telC.text.trim(), // Formatlanmış haliyle kaydedilir
            'kvkkOnay': true,
            'kayitTarihi': FieldValue.serverTimestamp(),
            'rol': 'standart',
          });

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kayıt Başarılı! Giriş yapabilirsiniz."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String mesaj = "Hata oluştu";
        if (e.code == 'email-already-in-use')
          mesaj = "Bu e-posta zaten kullanılıyor.";
        else if (e.code == 'weak-password')
          mesaj = "Şifre çok zayıf.";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mesaj), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Bir hata oluştu.")));
      }
    } finally {
      if (mounted) setState(() => _load = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ol")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            // Ad Soyad
            TextField(
              controller: _adC,
              decoration: const InputDecoration(
                labelText: "Ad Soyad",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // E-posta
            TextField(
              controller: _emailC,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "E-posta",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Telefon (Özel Formatlı)
            TextField(
              controller: _telC,
              keyboardType: TextInputType.number, // Sadece sayı klavyesi
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // Sadece rakam girilsin
                TrPhoneFormatter(), // Özel formatlayıcı
              ],
              decoration: const InputDecoration(
                labelText: "Telefon Numarası",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                hintText: "0(5xx) xxx xx xx",
              ),
            ),
            const SizedBox(height: 20),

            // Şifre
            TextField(
              controller: _passC,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Şifre",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // KVKK Onay Kutusu
            Row(
              children: [
                Checkbox(
                  value: _kvkkOnay,
                  activeColor: kAnaRenk,
                  onChanged: (val) {
                    setState(() => _kvkkOnay = val ?? false);
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _kvkkMetniniGoster,
                    child: RichText(
                      text: const TextSpan(
                        text:
                            "Kişisel verilerimin işlenmesini ve firmalarla paylaşılmasını ",
                        style: TextStyle(color: Colors.black, fontSize: 12),
                        children: [
                          TextSpan(
                            text: "Aydınlatma Metni",
                            style: TextStyle(
                              color: kAnaRenk,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: " kapsamında onaylıyorum."),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Kayıt Butonu
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
                      onPressed: _kayit,
                      child: const Text("KAYIT OL"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// --- ÖZEL TELEFON FORMATLAYICI ---
// Kullanıcı ne yazarsa yazsın 0(5XX) XXX XX XX formatına zorlar
class TrPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Sadece rakamları al (Temizle)
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // 2. Başlangıcı zorla (0 ve 5)
    if (digits.isEmpty) {
      return const TextEditingValue(text: ''); // Tamamen sildiyse boşalt
    }

    // Eğer kullanıcı 5 ile başlarsa başına 0 ekle (532 -> 0532)
    if (digits.startsWith('5')) {
      digits = '0$digits';
    }
    // Eğer kullanıcı 0 ile başlamadıysa (örn: 3...) zorla 05 yap
    else if (!digits.startsWith('0')) {
      digits = '05$digits';
    }
    // Eğer 0 ile başlıyor ama 05 değilse (örn: 0212...), 05'e çevir
    else if (digits.length >= 2 && digits[1] != '5') {
      digits = '05' + digits.substring(2);
    }

    // 3. Maksimum uzunluğu sınırla (05XX XXX XX XX -> 11 rakam)
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    // 4. Maskeyi Uygula: 0(5XX) XXX XX XX
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 0) {
        buffer.write(digits[i]); // 0
        if (digits.length > 1) buffer.write('(');
      } else if (i == 3) {
        buffer.write(digits[i]); // 5XX
        if (digits.length > 4) buffer.write(') ');
      } else if (i == 6) {
        buffer.write(digits[i]); // XXX
        if (digits.length > 7) buffer.write(' ');
      } else if (i == 8) {
        buffer.write(digits[i]); // XX
        if (digits.length > 9) buffer.write(' ');
      } else {
        buffer.write(digits[i]);
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
