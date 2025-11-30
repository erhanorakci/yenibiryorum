import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants.dart';

class YorumEkleSayfasi extends StatefulWidget {
  final String? otomatikBaslik;
  final String? mekanId;
  final String? mekanKategorisi;

  const YorumEkleSayfasi({
    super.key,
    this.otomatikBaslik,
    this.mekanId,
    this.mekanKategorisi,
  });

  @override
  State<YorumEkleSayfasi> createState() => _YorumEkleSayfasiState();
}

class _YorumEkleSayfasiState extends State<YorumEkleSayfasi> {
  final _icerikC = TextEditingController();
  int _yildiz = 0;
  bool _yukleniyor = false;

  // TEKLİ RESİM DEĞİŞKENİ
  File? _secilenResim;

  Future<void> _resimSec() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _secilenResim = File(image.path);
      });
    }
  }

  void _resimSil() {
    setState(() {
      _secilenResim = null;
    });
  }

  // --- ROZET KONTROLÜ (DÜZELTİLDİ) ---
  Future<void> _rozetKontrolu(String uid, BuildContext dialogContext) async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(uid)
          .get();
      List<dynamic> mevcutRozetler = userDoc.data()?['rozetler'] ?? [];

      var genelYorumlar = await FirebaseFirestore.instance
          .collection('yorumlar')
          .where('yazarId', isEqualTo: uid)
          .count()
          .get();
      int toplamYorumSayisi = genelYorumlar.count ?? 0;

      int kategoriYorumSayisi = 0;
      if (widget.mekanKategorisi != null) {
        var katYorumlar = await FirebaseFirestore.instance
            .collection('yorumlar')
            .where('yazarId', isEqualTo: uid)
            .where('mekanKategorisi', isEqualTo: widget.mekanKategorisi)
            .count()
            .get();
        kategoriYorumSayisi = katYorumlar.count ?? 0;
      }

      List<String> kazanilanYeniRozetler = [];

      kRozetler.forEach((key, value) {
        if (mevcutRozetler.contains(key)) return;

        bool kazandi = false;
        if (value['kategori'] == 'Genel' &&
            toplamYorumSayisi >= value['hedef']) {
          kazandi = true;
        } else if (value['kategori'] == widget.mekanKategorisi &&
            kategoriYorumSayisi >= value['hedef']) {
          kazandi = true;
        }

        if (kazandi) kazanilanYeniRozetler.add(key);
      });

      if (kazanilanYeniRozetler.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(uid)
            .update({'rozetler': FieldValue.arrayUnion(kazanilanYeniRozetler)});

        // Dialog gösterme (Düzeltildi)
        if (dialogContext.mounted) {
          var ilkRozetBilgisi = kRozetler[kazanilanYeniRozetler.first];
          await showDialog(
            context: dialogContext,
            barrierDismissible: false, // Kullanıcı butona basmak zorunda kalsın
            builder: (ctx) => AlertDialog(
              title: const Text("TEBRİKLER! 🎉", textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Yeni bir rozet kazandın!"),
                  const SizedBox(height: 20),
                  Icon(
                    ilkRozetBilgisi?['ikon'],
                    size: 60,
                    color: Color(ilkRozetBilgisi?['renk']),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ilkRozetBilgisi?['isim'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(ilkRozetBilgisi?['renk']),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("HARİKA"),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print("Rozet hatası: $e");
    }
  }

  Future<void> _yorumuKaydet() async {
    if (_icerikC.text.isEmpty || _yildiz == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen puan ve yorum yazın.")),
      );
      return;
    }
    setState(() => _yukleniyor = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;

      // TEKLİ RESİM YÜKLEME
      String? yuklenenResimLink;

      if (_secilenResim != null) {
        String dosyaAdi = "${DateTime.now().millisecondsSinceEpoch}.jpg";
        final ref = FirebaseStorage.instance.ref().child('yorumlar/$dosyaAdi');
        await ref.putFile(_secilenResim!);
        yuklenenResimLink = await ref.getDownloadURL();
      }

      // Yorumu Ekle
      await FirebaseFirestore.instance.collection('yorumlar').add({
        'mekanId': widget.mekanId,
        'mekanKategorisi': widget.mekanKategorisi,
        'baslik': widget.otomatikBaslik,
        'icerik': _icerikC.text,
        'puan': _yildiz,
        'resimUrl': yuklenenResimLink, // Tek resim
        // 'resimUrls' alanını artık kullanmıyoruz/boş geçiyoruz
        'yazar': user?.displayName ?? user?.email,
        'yazarResim': user?.photoURL,
        'yazarId': user?.uid,
        'tarih': FieldValue.serverTimestamp(),
        'likes': [],
        'begeniSayisi': 0,
      });

      // Puan Güncelleme
      if (widget.mekanId != null) {
        var mekanDoc = await FirebaseFirestore.instance
            .collection('mekanlar')
            .doc(widget.mekanId)
            .get();
        if (mekanDoc.exists) {
          var data = mekanDoc.data() as Map<String, dynamic>;
          int eskiYorumSayisi = (data['yorumSayisi'] ?? 0).toInt();
          int eskiToplamPuan = (data['toplamPuan'] ?? 0).toInt();
          int yeniYorumSayisi = eskiYorumSayisi + 1;
          int yeniToplamPuan = eskiToplamPuan + _yildiz;

          await FirebaseFirestore.instance
              .collection('mekanlar')
              .doc(widget.mekanId)
              .update({
                'yorumSayisi': yeniYorumSayisi,
                'toplamPuan': yeniToplamPuan,
              });
        }
      }

      // 4. Rozet Kontrolü (BURADA BEKLETİYORUZ)
      if (user != null) {
        // Context'i kaybetmemek için burada gönderiyoruz
        await _rozetKontrolu(user.uid, context);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Yorumunuz yayınlandı!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Hata oluştu"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otomatikBaslik ?? "Yorum Yap")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Text(
              "Puanın Kaç?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => IconButton(
                  onPressed: () => setState(() => _yildiz = i + 1),
                  icon: Icon(
                    i < _yildiz ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: TextEditingController(text: widget.otomatikBaslik),
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Mekan",
                filled: true,
                fillColor: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _icerikC,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Yorumun",
              ),
            ),
            const SizedBox(height: 20),

            // --- FOTOĞRAF SEÇME ALANI (TEKLİ) ---
            GestureDetector(
              onTap: _resimSec,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
                    Text(
                      _secilenResim == null
                          ? "Fotoğraf Ekle"
                          : "Fotoğraf Seçildi (Değiştirmek için tıkla)",
                    ),
                  ],
                ),
              ),
            ),

            // Seçilen Resmin Önizlemesi
            if (_secilenResim != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: FileImage(_secilenResim!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _resimSil,
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // -----------------------------------------
            const SizedBox(height: 30),
            _yukleniyor
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAnaRenk,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _yorumuKaydet,
                      child: const Text("GÖNDER"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
