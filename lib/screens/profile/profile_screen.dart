import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../place/place_detail_screen.dart';

class ProfilSayfasi extends StatefulWidget {
  const ProfilSayfasi({super.key});
  @override
  State<ProfilSayfasi> createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi> {
  User? user = FirebaseAuth.instance.currentUser;
  final _adC = TextEditingController();
  final _ilC = TextEditingController();
  final _dogumC = TextEditingController();
  final _sifreC = TextEditingController();

  File? _profilResmi;
  List<dynamic> _kazanilanRozetler = [];

  @override
  void initState() {
    super.initState();
    _adC.text = user?.displayName ?? "";
    _kullaniciBilgileriniGetir();
  }

  Future<void> _kullaniciBilgileriniGetir() async {
    if (user == null) return;
    var doc = await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(user!.uid)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        _kazanilanRozetler = doc.data()?['rozetler'] ?? [];
      });
    }
  }

  void _cikisYap() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Çıkış yapıldı.")));
    }
  }

  Future<void> _resimSec() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);
      try {
        String path = 'profil_fotolari/${user!.uid}.jpg';
        var ref = FirebaseStorage.instance.ref().child(path);
        await ref.putFile(file);
        String url = await ref.getDownloadURL();
        await user!.updatePhotoURL(url);
        await user!.reload();
        if (mounted) {
          setState(() => user = FirebaseAuth.instance.currentUser);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profil fotoğrafı güncellendi!")),
          );
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Hata oluştu")));
      }
    }
  }

  void _iletisimDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("İletişim & Destek"),
        content: const SingleChildScrollView(
          child: SelectableText(
            "Her türlü soru, görüş, şikayet veya reklam işbirliği için bize ulaşabilirsiniz.\n\nE-posta:\ndestek@yenibiryorum.com\n\nTelefon:\n0501 333 23 13",
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  void _profiliDuzenle() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Profili Düzenle",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _adC,
                decoration: const InputDecoration(
                  labelText: "Ad Soyad",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _ilC,
                decoration: const InputDecoration(
                  labelText: "İl",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _dogumC,
                decoration: const InputDecoration(
                  labelText: "Doğum Tarihi",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _sifreC,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Yeni Şifre (Opsiyonel)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAnaRenk,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (_adC.text.isNotEmpty) {
                      await user?.updateDisplayName(_adC.text);
                      await user?.reload();
                      if (_sifreC.text.isNotEmpty)
                        await user?.updatePassword(_sifreC.text);
                      if (mounted)
                        setState(
                          () => user = FirebaseAuth.instance.currentUser,
                        );
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Profil güncellendi!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text("KAYDET"),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- ROZET GERİ ALMA MANTIĞI EKLENMİŞ SİLME FONKSİYONU ---
  void _yorumSil(String docId, String? mekanKategorisi) async {
    try {
      // 1. Yorumu veritabanından sil
      var yorumDoc = await FirebaseFirestore.instance
          .collection('yorumlar')
          .doc(docId)
          .get();
      if (!yorumDoc.exists) return;

      String? mekanId = yorumDoc.data()?['mekanId'];
      int puan = (yorumDoc.data()?['puan'] ?? 0).toInt();

      await FirebaseFirestore.instance
          .collection('yorumlar')
          .doc(docId)
          .delete();

      // 2. Mekan puanını düşür
      if (mekanId != null) {
        await FirebaseFirestore.instance
            .collection('mekanlar')
            .doc(mekanId)
            .update({
              'yorumSayisi': FieldValue.increment(-1),
              'toplamPuan': FieldValue.increment(-puan),
            });
      }

      // 3. ROZET KONTROLÜ (GERİ ALMA)
      if (user != null) {
        String uid = user!.uid;

        // Güncel yorum sayılarını çek
        var genelYorumlar = await FirebaseFirestore.instance
            .collection('yorumlar')
            .where('yazarId', isEqualTo: uid)
            .count()
            .get();
        int guncelToplam = genelYorumlar.count ?? 0;

        int guncelKategori = 0;
        if (mekanKategorisi != null) {
          var katYorumlar = await FirebaseFirestore.instance
              .collection('yorumlar')
              .where('yazarId', isEqualTo: uid)
              .where('mekanKategorisi', isEqualTo: mekanKategorisi)
              .count()
              .get();
          guncelKategori = katYorumlar.count ?? 0;
        }

        // Hak edilmeyen rozetleri bul
        List<String> silinecekRozetler = [];
        kRozetler.forEach((key, value) {
          if (_kazanilanRozetler.contains(key)) {
            bool hakEdiyor = false;
            if (value['kategori'] == 'Genel') {
              if (guncelToplam >= value['hedef']) hakEdiyor = true;
            } else if (value['kategori'] == mekanKategorisi) {
              if (guncelKategori >= value['hedef']) hakEdiyor = true;
            } else {
              // Bu rozet silinen kategoriyle alakasızsa dokunma
              hakEdiyor = true;
            }

            if (!hakEdiyor) silinecekRozetler.add(key);
          }
        });

        // Rozetleri sil
        if (silinecekRozetler.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('kullanicilar')
              .doc(uid)
              .update({'rozetler': FieldValue.arrayRemove(silinecekRozetler)});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Bazı rozetler geri alındı.")),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Yorum silindi.")));
        _kullaniciBilgileriniGetir(); // Ekranı güncelle
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Bir hata oluştu.")));
    }
  }

  void _yorumDuzenle(
    String docId,
    String eskiBaslik,
    String eskiIcerik,
    int eskiPuan,
    String? mekanId,
  ) {
    // ... (Bu kısım değişmediği için aynı kaldı)
    final baslikC = TextEditingController(text: eskiBaslik);
    final icerikC = TextEditingController(text: eskiIcerik);
    int yeniPuan = eskiPuan;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yorumu Düzenle"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: baslikC,
                decoration: const InputDecoration(labelText: "Başlık"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: icerikC,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Yorum"),
              ),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (context, setState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (i) => IconButton(
                        onPressed: () => setState(() => yeniPuan = i + 1),
                        icon: Icon(
                          i < yeniPuan ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('yorumlar')
                  .doc(docId)
                  .update({
                    'baslik': baslikC.text,
                    'icerik': icerikC.text,
                    'puan': yeniPuan,
                  });
              if (mekanId != null && yeniPuan != eskiPuan) {
                int fark = yeniPuan - eskiPuan;
                await FirebaseFirestore.instance
                    .collection('mekanlar')
                    .doc(mekanId)
                    .update({'toplamPuan': FieldValue.increment(fark)});
              }
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Yorum güncellendi!")),
                );
            },
            child: const Text("KAYDET"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? bgImage;
    if (user?.photoURL != null) {
      bgImage = NetworkImage(user!.photoURL!);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Profilim"),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
          actions: [
            IconButton(
              icon: const Icon(Icons.support_agent, color: kAnaRenk),
              tooltip: "İletişim & Destek",
              onPressed: _iletisimDialog,
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: _profiliDuzenle,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: "Çıkış Yap",
              onPressed: _cikisYap,
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _resimSec,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: bgImage,
                    child: bgImage == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: kAnaRenk,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              user?.displayName ?? user?.email ?? "Kullanıcı",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            if (_kazanilanRozetler.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: _kazanilanRozetler.length,
                    itemBuilder: (context, index) {
                      String rozetKodu = _kazanilanRozetler[index];
                      var rozetBilgi = kRozetler[rozetKodu];
                      if (rozetBilgi == null) return const SizedBox();
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Color(rozetBilgi['renk']).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Color(rozetBilgi['renk'])),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              rozetBilgi['ikon'],
                              size: 16,
                              color: Color(rozetBilgi['renk']),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              rozetBilgi['isim'],
                              style: TextStyle(
                                color: Color(rozetBilgi['renk']),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 10),
            const TabBar(
              labelColor: kAnaRenk,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kAnaRenk,
              tabs: [
                Tab(icon: Icon(Icons.comment), text: "Yorumlarım"),
                Tab(icon: Icon(Icons.favorite), text: "Favorilerim"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('yorumlar')
                        .where('yazarId', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      if (snapshot.data!.docs.isEmpty)
                        return const Center(child: Text("Henüz yorumun yok."));
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var doc = snapshot.data!.docs[index];
                          var veri = doc.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 5,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: kAnaRenk.withOpacity(0.2),
                                child: const Icon(
                                  Icons.comment,
                                  color: kAnaRenk,
                                ),
                              ),
                              title: Text(
                                veri['baslik'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                veri['icerik'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _yorumDuzenle(
                                      doc.id,
                                      veri['baslik'],
                                      veri['icerik'],
                                      (veri['puan'] ?? 5).toInt(),
                                      veri['mekanId'],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _yorumSil(
                                      doc.id,
                                      // --- MEKAN KATEGORİSİ GÖNDERİLİYOR ---
                                      veri['mekanKategorisi'],
                                      // -------------------------------------
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  // Favoriler Sekmesi (Aynı Kaldı)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('kullanicilar')
                        .doc(user?.uid)
                        .collection('favoriler')
                        .orderBy('eklemeTarihi', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      if (snapshot.data!.docs.isEmpty)
                        return const Center(child: Text("Henüz favorin yok."));
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var veri =
                              snapshot.data!.docs[index].data()
                                  as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetaySayfasi(
                                  mekanId: veri['mekanId'],
                                  baslik: veri['baslik'],
                                  resimUrl: veri['resimUrl'],
                                  kategori: veri['kategori'],
                                  puan: "Favori",
                                  altBaslik: "Kaydedilenler",
                                ),
                              ),
                            ),
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 5,
                              ),
                              child: ListTile(
                                leading: Image.network(
                                  veri['resimUrl'] ?? '',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image),
                                ),
                                title: Text(
                                  veri['baslik'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(veri['kategori'] ?? ''),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
