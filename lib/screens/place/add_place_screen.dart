import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // LatLng için
import '../../core/constants.dart';
import 'place_detail_screen.dart';
import 'map_screen.dart'; // Harita sayfasını çağıracağız

class MekanEkleSayfasi extends StatefulWidget {
  final String oneriIsim;
  const MekanEkleSayfasi({super.key, required this.oneriIsim});
  @override
  State<MekanEkleSayfasi> createState() => _MekanEkleSayfasiState();
}

class _MekanEkleSayfasiState extends State<MekanEkleSayfasi> {
  final _adC = TextEditingController();
  String _kategori = "Firma";
  File? _secilenResim;
  bool _yukleniyor = false;

  // KONUM DEĞİŞKENİ
  LatLng? _secilenKoordinat;

  @override
  void initState() {
    super.initState();
    _adC.text = widget.oneriIsim;
  }

  Future<void> _resimSec() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _secilenResim = File(image.path));
  }

  // HARİTADAN KONUM SEÇME FONKSİYONU
  Future<void> _konumSec() async {
    // Harita sayfasını "Seçim Modu"nda (isSelecting: true) açıyoruz
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HaritaSayfasi(isSelecting: true),
      ),
    );

    // Eğer kullanıcı bir yer seçip döndüyse
    if (result != null && result is LatLng) {
      setState(() {
        _secilenKoordinat = result;
      });
    }
  }

  IconData _kategoriyeGoreIkon() {
    switch (_kategori) {
      case "Restoran":
        return Icons.restaurant;
      case "Kafe":
        return Icons.local_cafe;
      case "Dizi-Film":
        return Icons.movie;
      case "Ünlü":
        return Icons.star;
      case "Diğer":
        return Icons.category;
      default:
        return Icons.business;
    }
  }

  Future<void> _mekaniKaydet() async {
    if (_adC.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lütfen isim girin.")));
      return;
    }

    // Eğer mekan fiziksel bir yerse (Restoran, Kafe) konum zorunlu olsun
    // Ama Dizi-Film veya Ünlü ise konum zorunlu olmasın.
    if ((_kategori == "Restoran" ||
            _kategori == "Kafe" ||
            _kategori == "Firma") &&
        _secilenKoordinat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen haritadan konum seçin.")),
      );
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      String? resimUrl;
      if (_secilenResim != null) {
        final ref = FirebaseStorage.instance.ref().child(
          'mekanlar/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await ref.putFile(_secilenResim!);
        resimUrl = await ref.getDownloadURL();
      }

      DocumentReference ref = await FirebaseFirestore.instance
          .collection('mekanlar')
          .add({
            'ad': _adC.text,
            'kategori': _kategori,
            'resimUrl': resimUrl,
            'tarih': FieldValue.serverTimestamp(),
            'ekleyen': FirebaseAuth.instance.currentUser?.uid,
            'yorumSayisi': 0,
            'toplamPuan': 0,
            // KONUM KAYDI (Varsa)
            'konum': _secilenKoordinat != null
                ? GeoPoint(
                    _secilenKoordinat!.latitude,
                    _secilenKoordinat!.longitude,
                  )
                : null,
          });

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetaySayfasi(
              mekanId: ref.id,
              baslik: _adC.text,
              resimUrl: resimUrl ?? 'https://via.placeholder.com/300',
              puan: "Yeni",
              altBaslik: _kategori,
              kategori: _kategori,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Hata oluştu")));
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ekle ve Yorumla")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            GestureDetector(
              onTap: _resimSec,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: _secilenResim != null
                    ? FileImage(_secilenResim!)
                    : null,
                child: _secilenResim == null
                    ? const Icon(
                        Icons.add_a_photo,
                        size: 30,
                        color: Colors.grey,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Fotoğraf Ekle ($_kategori)",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            DropdownButtonFormField(
              value: _kategori,
              items: [
                "Firma",
                "Restoran",
                "Kafe",
                "Dizi-Film",
                "Ünlü",
                "Diğer",
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() {
                _kategori = v!;
                _secilenKoordinat = null;
              }), // Kategori değişince konumu sıfırla
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Kategori Seçin",
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _adC,
              decoration: InputDecoration(
                labelText: _kategori == "Ünlü"
                    ? "Kişi Adı Soyadı"
                    : (_kategori == "Dizi-Film"
                          ? "Film/Dizi Adı"
                          : "Mekan/Firma Adı"),
                border: const OutlineInputBorder(),
                prefixIcon: Icon(_kategoriyeGoreIkon()),
              ),
            ),

            const SizedBox(height: 20),

            // --- KONUM SEÇME ALANI (Sadece Mekanlar İçin Görünür) ---
            if (_kategori == "Restoran" ||
                _kategori == "Kafe" ||
                _kategori == "Firma")
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  children: [
                    if (_secilenKoordinat != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 10),
                          Text(
                            "Konum Seçildi ✅",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        "Haritadan Konum Seçin",
                        style: TextStyle(color: Colors.grey),
                      ),

                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _konumSec,
                      icon: const Icon(Icons.map),
                      label: Text(
                        _secilenKoordinat != null
                            ? "Konumu Değiştir"
                            : "Haritayı Aç",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

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
                      onPressed: _mekaniKaydet,
                      child: const Text("KAYDET VE BAŞLAT"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
