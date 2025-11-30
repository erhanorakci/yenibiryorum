import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../core/notification_service.dart';
import '../auth/login_screen.dart';
import '../place/search_place_screen.dart';
import '../place/map_screen.dart';
import '../profile/profile_screen.dart';
import '../place/place_detail_screen.dart';
import 'notifications_screen.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});
  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  User? _kullanici;

  @override
  void initState() {
    super.initState();
    _verileriGuncelle();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) setState(() => _kullanici = user);
    });
    FirebaseAuth.instance.userChanges().listen((User? user) {
      if (mounted) setState(() => _kullanici = user);
    });
  }

  Future<void> _verileriGuncelle() async {
    if (!mounted) return;
    await FirebaseAuth.instance.currentUser?.reload();
    await BildirimServisi().baslat();
    if (mounted) setState(() => _kullanici = FirebaseAuth.instance.currentUser);
  }

  void _girisKontrolu() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Lütfen giriş yapın."),
        backgroundColor: kAnaRenk,
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GirisEkrani()),
    ).then((_) => _verileriGuncelle());
  }

  void _cikisYap() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Çıkış yapıldı.")));
      _verileriGuncelle();
    }
  }

  void _mekanAraVeyaEkle() {
    if (_kullanici == null) {
      _girisKontrolu();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MekanAramaSayfasi()),
      ).then((_) => _verileriGuncelle());
    }
  }

  void _profilSayfasinaGit() {
    if (_kullanici != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilSayfasi()),
      ).then((_) => _verileriGuncelle());
    } else {
      _girisKontrolu();
    }
  }

  void _mekaniPaylas(String baslik, String kategori) {
    String paylasimMetni =
        "Harika bir yer keşfettim: $baslik!\nKategori: $kategori\nSen de 'Yorum Platformu'nu indir ve incele! 🚀";
    Share.share(paylasimMetni);
  }

  // --- YÖNLENDİRME FONKSİYONU (GÜNCELLENDİ) ---
  // Banner ve Hikaye tıklamalarını yönetir
  void _yonlendir(BuildContext context, Map<String, dynamic> data) async {
    // 1. KAMPANYA (ÇOKLU MEKAN LİSTESİ)
    if (data['hedefTipi'] == 'mekanlar' && data['hedefDeger'] is List) {
      List<String> mekanIds = List<String>.from(data['hedefDeger']);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MekanAramaSayfasi(ozelMekanListesi: mekanIds),
        ),
      );
      return;
    }

    // 2. KATEGORİ
    if (data['hedefTipi'] == 'kategori' || data['kategori'] != null) {
      String kategori = data['hedefDeger'] ?? data['kategori'] ?? "Genel";
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MekanAramaSayfasi(baslangicAramasi: kategori),
        ),
      );
      return;
    }

    // 3. TEKİL MEKAN (Eski sistemden kalan veya özel durumlar için)
    String? mekanId = data['hedefMekanId'];
    if (mekanId != null) {
      var doc = await FirebaseFirestore.instance
          .collection('mekanlar')
          .doc(mekanId)
          .get();
      if (doc.exists && context.mounted) {
        var mData = doc.data() as Map<String, dynamic>;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetaySayfasi(
              baslik: mData['ad'],
              resimUrl: mData['resimUrl'],
              puan: "Öneri",
              altBaslik: mData['kategori'],
              mekanId: doc.id,
              kategori: mData['kategori'],
            ),
          ),
        );
      }
    }
  }
  // ----------------------------------------------

  @override
  Widget build(BuildContext context) {
    String hamIsim = _kullanici?.displayName ?? _kullanici?.email ?? "Misafir";
    String gorunenIsim = _kullanici != null ? ismiGizle(hamIsim) : hamIsim;
    ImageProvider? profilResmi = _kullanici?.photoURL != null
        ? NetworkImage(_kullanici!.photoURL!)
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst Şerit
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _profilSayfasinaGit,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: profilResmi,
                            child: profilResmi == null
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Hoş Geldiniz,",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                gorunenIsim,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.notifications_none,
                        color: kAnaRenk,
                        size: 28,
                      ),
                      onPressed: () {
                        if (_kullanici != null)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BildirimSayfasi(),
                            ),
                          );
                        else
                          _girisKontrolu();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Arama
                GestureDetector(
                  onTap: _mekanAraVeyaEkle,
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: kAnaRenk.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: kAnaRenk.withOpacity(0.6),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Mekan, film veya firma ara...",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: kAnaRenk, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Hikayeler
                const Text(
                  "Önerilenler",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 110,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('hikayeler')
                        .where('hedefVitrin', isEqualTo: 'Ust')
                        .orderBy('sira', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var veri =
                              snapshot.data!.docs[index].data()
                                  as Map<String, dynamic>;
                          return _hikaye(context, veri);
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
                _adminYonetimliBannerListesi("Orta", "Sizin İçin Seçtik"),
                const SizedBox(height: 20),
                _baslikOlustur("Günün Vitrini", "En çok konuşulanlar"),
                _otomatikMekanListesi(
                  FirebaseFirestore.instance
                      .collection('mekanlar')
                      .orderBy('yorumSayisi', descending: true)
                      .limit(5),
                ),
                const SizedBox(height: 20),
                _adminYonetimliBannerListesi("Alt", "Kaçırılmayacak Fırsatlar"),
                const SizedBox(height: 20),
                _baslikOlustur("Yeni Keşifler", "Henüz eklendi"),
                _otomatikMekanListesi(
                  FirebaseFirestore.instance
                      .collection('mekanlar')
                      .orderBy('tarih', descending: true)
                      .limit(5),
                ),
              ],
            ),
          ),

          // Alt Navigasyon
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: kAltBarRengi,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HaritaSayfasi(),
                      ),
                    ),
                    icon: const Icon(
                      Icons.map_outlined,
                      color: Colors.white54,
                      size: 30,
                    ),
                  ),
                  GestureDetector(
                    onTap: _mekanAraVeyaEkle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: kAnaRenk),
                          SizedBox(width: 5),
                          Text(
                            "YORUM",
                            style: TextStyle(
                              color: kAnaRenk,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _profilSayfasinaGit,
                    icon: const Icon(
                      Icons.person_outline,
                      color: Colors.white54,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _baslikOlustur(String anaBaslik, String altBaslik) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        anaBaslik,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 5),
      Text(altBaslik, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 15),
    ],
  );

  Widget _adminYonetimliBannerListesi(String vitrinKodu, String baslik) =>
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hikayeler')
            .where('hedefVitrin', isEqualTo: vitrinKodu)
            .orderBy('sira')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const SizedBox();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _baslikOlustur(baslik, "Özel içerikler"),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    return _ozelBanner(context, data);
                  },
                ),
              ),
            ],
          );
        },
      );

  Widget _otomatikMekanListesi(Query query) => SizedBox(
    height: 220,
    child: StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var mekan = snapshot.data!.docs[index];
            return _mekanBanner(context, mekan);
          },
        );
      },
    ),
  );

  Widget _guvenliResim(
    String? url, {
    double width = 100,
    double height = 100,
    double radius = 0,
  }) {
    bool urlGecerli = url != null && url.isNotEmpty && url.startsWith('http');
    if (!urlGecerli)
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(radius),
        ),
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error, color: Colors.red),
        ),
      ),
    );
  }

  Widget _hikaye(BuildContext context, Map<String, dynamic> data) =>
      GestureDetector(
        onTap: () => _yonlendir(context, data),
        child: Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.orange],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    child: _guvenliResim(
                      data['resimUrl'],
                      width: 60,
                      height: 60,
                      radius: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                data['baslik'] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _ozelBanner(BuildContext context, Map<String, dynamic> data) =>
      GestureDetector(
        onTap: () => _yonlendir(context, data),
        child: Container(
          width: 280,
          margin: const EdgeInsets.only(right: 20),
          child: Stack(
            children: [
              _guvenliResim(
                data['resimUrl'],
                width: double.infinity,
                height: double.infinity,
                radius: 25,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: Text(
                  data['baslik'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _mekanBanner(BuildContext context, DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    double ortalama = (data['yorumSayisi'] ?? 0) > 0
        ? (data['toplamPuan'] ?? 0) / data['yorumSayisi']
        : 0.0;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetaySayfasi(
            baslik: data['ad'],
            resimUrl: data['resimUrl'],
            puan: ortalama == 0 ? "Yeni" : ortalama.toStringAsFixed(1),
            altBaslik: data['kategori'],
            mekanId: doc.id,
            kategori: data['kategori'],
          ),
        ),
      ),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 20),
        child: Stack(
          children: [
            _guvenliResim(
              data['resimUrl'],
              width: double.infinity,
              height: double.infinity,
              radius: 25,
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['ad'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${ortalama == 0 ? "Yeni" : ortalama.toStringAsFixed(1)} • ${data['yorumSayisi'] ?? 0} Yorum",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
