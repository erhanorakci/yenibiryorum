import 'dart:math'; // Matematik işlemleri için eklendi
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants.dart';
import '../../core/utils.dart';
import '../comment/add_comment_screen.dart';

class DetaySayfasi extends StatefulWidget {
  final String mekanId;
  final String baslik;
  final String? resimUrl;
  final String kategori;
  final String puan;
  final String altBaslik;

  const DetaySayfasi({
    super.key,
    required this.mekanId,
    required this.baslik,
    this.resimUrl,
    required this.kategori,
    required this.puan,
    required this.altBaslik,
  });

  @override
  State<DetaySayfasi> createState() => _DetaySayfasiState();
}

class _DetaySayfasiState extends State<DetaySayfasi>
    with TickerProviderStateMixin {
  bool _isFavori = false;
  User? _user;
  bool get _isYetkili => _user?.email == "erhan.orakci@hotmail.com";

  late Future<DocumentSnapshot> _mekanVerisiFuture;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _favoriKontrol();
    _mekanVerisiFuture = FirebaseFirestore.instance
        .collection('mekanlar')
        .doc(widget.mekanId)
        .get();
  }

  Future<void> _favoriKontrol() async {
    if (_user == null) return;
    var doc = await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(_user!.uid)
        .collection('favoriler')
        .doc(widget.mekanId)
        .get();
    if (mounted) setState(() => _isFavori = doc.exists);
  }

  Future<void> _favoriIslemi() async {
    if (_user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Giriş yapmalısınız.")));
      return;
    }
    setState(() => _isFavori = !_isFavori);
    final favRef = FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(_user!.uid)
        .collection('favoriler')
        .doc(widget.mekanId);

    if (_isFavori) {
      await favRef.set({
        'mekanId': widget.mekanId,
        'baslik': widget.baslik,
        'resimUrl': widget.resimUrl,
        'kategori': widget.kategori,
        'eklemeTarihi': FieldValue.serverTimestamp(),
      });
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Favorilere eklendi ❤️")));
    } else {
      await favRef.delete();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Favorilerden çıkarıldı.")),
        );
    }
  }

  void _mekaniPaylas() {
    String paylasimMetni =
        "Harika bir yer keşfettim: ${widget.baslik}!\n"
        "Kategori: ${widget.kategori}\n"
        "Puanı: ${widget.puan}\n\n"
        "Sen de 'Yorum Platformu'nu indir ve incele! 🚀";
    Share.share(paylasimMetni);
  }

  Future<void> _yorumuBegen(String docId, List<dynamic> begenenler) async {
    if (_user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Giriş yapmalısınız.")));
      return;
    }
    String uid = _user!.uid;
    if (begenenler.contains(uid)) {
      await FirebaseFirestore.instance.collection('yorumlar').doc(docId).update(
        {
          'likes': FieldValue.arrayRemove([uid]),
          'begeniSayisi': FieldValue.increment(-1),
        },
      );
    } else {
      await FirebaseFirestore.instance.collection('yorumlar').doc(docId).update(
        {
          'likes': FieldValue.arrayUnion([uid]),
          'begeniSayisi': FieldValue.increment(1),
        },
      );
    }
  }

  void _cevapVerDialog(String yorumId, String mevcutCevap) {
    final cevapC = TextEditingController(text: mevcutCevap);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Firma Cevabı Yaz"),
        content: TextField(
          controller: cevapC,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Yanıtınız...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (cevapC.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('yorumlar')
                    .doc(yorumId)
                    .update({
                      'firmaCevabi': cevapC.text,
                      'cevapTarihi': FieldValue.serverTimestamp(),
                    });
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cevap Yayınlandı ✅")),
                  );
              }
            },
            child: const Text("YAYINLA"),
          ),
        ],
      ),
    );
  }

  void _sikayetEtDialog(String hedefId, String tur, String hedefBaslik) {
    if (_user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Giriş yapmalısınız.")));
      return;
    }
    String? secilenSebep;
    final List<String> sebepler = [
      "Uygunsuz İçerik",
      "Spam",
      "Hakaret",
      "Diğer",
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$tur Bildir"),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: sebepler
                .map(
                  (sebep) => RadioListTile<String>(
                    title: Text(sebep),
                    value: sebep,
                    groupValue: secilenSebep,
                    onChanged: (val) => setState(() => secilenSebep = val),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (secilenSebep == null) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Bildiriminiz alındı."),
                  backgroundColor: Colors.green,
                ),
              );
              await FirebaseFirestore.instance.collection('sikayetler').add({
                'hedefId': hedefId,
                'hedefBaslik': hedefBaslik,
                'tur': tur,
                'sebep': secilenSebep,
                'sikayetEdenId': _user!.uid,
                'sikayetEdenEmail': _user!.email,
                'tarih': FieldValue.serverTimestamp(),
                'durum': 'beklemede',
              });
            },
            child: const Text("BİLDİR"),
          ),
        ],
      ),
    );
  }

  void _isletmeSahiplenDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("İşletme Sahibi misiniz?"),
        content: const Text(
          "Bu işletmenin sahibi sizseniz, bizimle iletişime geçin:\n\n📩 destek@yenibiryorum.com",
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

  Widget _guvenliResim(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (url == null || url.isEmpty || !url.startsWith('http')) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.error, color: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool konumVarMi = !["Ünlü", "Dizi-Film"].contains(widget.kategori);

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              leading: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.blue),
                    onPressed: _mekaniPaylas,
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(
                      _isFavori ? Icons.favorite : Icons.favorite_border,
                      color: _isFavori ? Colors.red : Colors.grey,
                    ),
                    onPressed: _favoriIslemi,
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    onSelected: (value) {
                      if (value == 'sikayet')
                        _sikayetEtDialog(
                          widget.mekanId,
                          "Mekan",
                          widget.baslik,
                        );
                      if (value == 'sahiplen') _isletmeSahiplenDialog();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'sahiplen',
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_user,
                              color: Colors.blue,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text("Bu İşletme Benim"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'sikayet',
                        child: Row(
                          children: [
                            Icon(Icons.flag, color: Colors.red, size: 20),
                            SizedBox(width: 10),
                            Text("Mekanı Bildir"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: FutureBuilder<DocumentSnapshot>(
                  future: _mekanVerisiFuture,
                  builder: (context, snapshot) {
                    Widget defaultImg = _guvenliResim(
                      widget.resimUrl,
                      width: double.infinity,
                      height: double.infinity,
                    );

                    if (snapshot.hasData && snapshot.data!.exists) {
                      var data = snapshot.data!.data() as Map<String, dynamic>;
                      List<dynamic> resimListesi = data['resimUrls'] ?? [];

                      if (resimListesi.isEmpty && data['resimUrl'] != null) {
                        resimListesi.add(data['resimUrl']);
                      }

                      if (resimListesi.length > 1) {
                        return CarouselSlider(
                          options: CarouselOptions(
                            height: double.infinity,
                            viewportFraction: 1.0,
                            autoPlay: true,
                            enableInfiniteScroll: true,
                          ),
                          items: resimListesi.map((url) {
                            return _guvenliResim(
                              url.toString(),
                              width: double.infinity,
                              height: double.infinity,
                            );
                          }).toList(),
                        );
                      } else if (resimListesi.isNotEmpty) {
                        return _guvenliResim(
                          resimListesi.first,
                          width: double.infinity,
                          height: double.infinity,
                        );
                      }
                    }
                    return defaultImg;
                  },
                ),
              ),
            ),
          ];
        },
        body: FutureBuilder<DocumentSnapshot>(
          future: _mekanVerisiFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

            // --- GÜVENLİ HESAPLAMA (Negatif Değer Koruması) ---
            int toplam = (data['toplamPuan'] ?? 0);
            if (toplam < 0) toplam = 0;

            int adet = (data['yorumSayisi'] ?? 0);
            if (adet < 0) adet = 0;
            // --------------------------------------------------

            double ortalama = adet > 0 ? toplam / adet : 0.0;
            String gosterilenPuan = ortalama == 0
                ? "Yeni"
                : ortalama.toStringAsFixed(1);
            GeoPoint? konum = data['konum'];
            bool haritaGoster = konumVarMi && konum != null;

            return DefaultTabController(
              length: haritaGoster ? 3 : 2,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: kAnaRenk,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: kAnaRenk,
                      tabs: [
                        const Tab(text: "Hakkında"),
                        const Tab(text: "Yorumlar"),
                        if (haritaGoster) const Tab(text: "Konum"),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 1. HAKKINDA
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.baslik,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kAnaRenk.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      widget.kategori,
                                      style: const TextStyle(
                                        color: kAnaRenk,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  Text(
                                    " $gosterilenPuan Puan",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Detaylar",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                data['aciklama'] ??
                                    "Bu içerik hakkında henüz detaylı bir açıklama girilmemiş.",
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _istatistikKutu(
                                    Icons.comment,
                                    "$adet",
                                    "Yorum",
                                  ),
                                  _istatistikKutu(
                                    Icons.star_half,
                                    gosterilenPuan,
                                    "Ortalama Puan",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 2. YORUMLAR
                        Column(
                          children: [
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('yorumlar')
                                    .where('mekanId', isEqualTo: widget.mekanId)
                                    .orderBy('begeniSayisi', descending: true)
                                    .orderBy('tarih', descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError)
                                    return const Center(
                                      child: Text(
                                        "Yorumlar yüklenemedi (Index?)",
                                      ),
                                    );
                                  if (!snapshot.hasData)
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  if (snapshot.data!.docs.isEmpty)
                                    return const Center(
                                      child: Text(
                                        "Henüz yorum yok. İlk sen yaz!",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    );

                                  return ListView.builder(
                                    padding: const EdgeInsets.all(15),
                                    itemCount: snapshot.data!.docs.length,
                                    itemBuilder: (context, index) {
                                      var doc = snapshot.data!.docs[index];
                                      var yorum =
                                          doc.data() as Map<String, dynamic>;
                                      List<dynamic> begenenler =
                                          yorum['likes'] ?? [];
                                      bool begendimMi =
                                          _user != null &&
                                          begenenler.contains(_user!.uid);
                                      int begeniSayisi =
                                          yorum['begeniSayisi'] ?? 0;
                                      String? firmaCevabi =
                                          yorum['firmaCevabi'];
                                      Timestamp? cevapTarihi =
                                          yorum['cevapTarihi'];
                                      String? yazarResim = yorum['yazarResim'];
                                      int verilenPuan = yorum['puan'] ?? 5;
                                      String? resimUrl = yorum['resimUrl'];
                                      bool resimVar =
                                          resimUrl != null &&
                                          resimUrl.isNotEmpty;

                                      return _ExpandableYorumKarti(
                                        yorum: yorum,
                                        docId: doc.id,
                                        yazarResim: yazarResim,
                                        verilenPuan: verilenPuan,
                                        resimUrl: resimUrl,
                                        resimVar: resimVar,
                                        begeniSayisi: begeniSayisi,
                                        begendimMi: begendimMi,
                                        firmaCevabi: firmaCevabi,
                                        cevapTarihi: cevapTarihi,
                                        isYetkili: _isYetkili,
                                        onBegen: () =>
                                            _yorumuBegen(doc.id, begenenler),
                                        onCevap: () => _cevapVerDialog(
                                          doc.id,
                                          firmaCevabi ?? "",
                                        ),
                                        onSikayet: () => _sikayetEtDialog(
                                          doc.id,
                                          "Yorum",
                                          yorum['icerik'] ?? "",
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (FirebaseAuth.instance.currentUser ==
                                        null)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Giriş yapmalısın"),
                                        ),
                                      );
                                    else
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              YorumEkleSayfasi(
                                                otomatikBaslik: widget.baslik,
                                                mekanId: widget.mekanId,
                                                mekanKategorisi:
                                                    widget.kategori,
                                              ),
                                        ),
                                      );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kAnaRenk,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                  ),
                                  child: const Text("YORUM YAP"),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 3. KONUM
                        if (haritaGoster)
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                data['konum'].latitude,
                                data['konum'].longitude,
                              ),
                              zoom: 15,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('mekan'),
                                position: LatLng(
                                  data['konum'].latitude,
                                  data['konum'].longitude,
                                ),
                                infoWindow: InfoWindow(title: widget.baslik),
                              ),
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _istatistikKutu(IconData icon, String sayi, String etiket) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 30),
        const SizedBox(height: 5),
        Text(
          sayi,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(etiket, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _ExpandableYorumKarti extends StatefulWidget {
  final Map<String, dynamic> yorum;
  final String docId;
  final String? yazarResim;
  final int verilenPuan;
  final String? resimUrl;
  final bool resimVar;
  final int begeniSayisi;
  final bool begendimMi;
  final String? firmaCevabi;
  final Timestamp? cevapTarihi;
  final bool isYetkili;
  final VoidCallback onBegen;
  final VoidCallback onCevap;
  final VoidCallback onSikayet;

  const _ExpandableYorumKarti({
    required this.yorum,
    required this.docId,
    this.yazarResim,
    required this.verilenPuan,
    this.resimUrl,
    required this.resimVar,
    required this.begeniSayisi,
    required this.begendimMi,
    this.firmaCevabi,
    this.cevapTarihi,
    required this.isYetkili,
    required this.onBegen,
    required this.onCevap,
    required this.onSikayet,
  });

  @override
  State<_ExpandableYorumKarti> createState() => _ExpandableYorumKartiState();
}

class _ExpandableYorumKartiState extends State<_ExpandableYorumKarti> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    backgroundImage: widget.yazarResim != null
                        ? NetworkImage(widget.yazarResim!)
                        : null,
                    child: widget.yazarResim == null
                        ? Text(
                            (widget.yorum['yazar'] ?? "A")[0].toUpperCase(),
                            style: const TextStyle(
                              color: kAnaRenk,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ismiGizle(widget.yorum['yazar'] ?? 'Anonim'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.firmaCevabi != null)
                              const Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "${widget.verilenPuan}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.resimVar && !_expanded)
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.photo, color: Colors.grey, size: 20),
                    ),
                  GestureDetector(
                    onTap: widget.onBegen,
                    child: Row(
                      children: [
                        Icon(
                          widget.begendimMi
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.begendimMi ? Colors.red : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${widget.begeniSayisi}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: widget.onSikayet,
                    child: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.yorum['icerik'] ?? "",
                maxLines: _expanded ? null : 2,
                overflow: _expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              if (_expanded && widget.resimVar)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.resimUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (widget.firmaCevabi != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified, size: 14, color: Colors.blue),
                            SizedBox(width: 5),
                            Text(
                              "Firma Yetkilisi",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.firmaCevabi!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              if (widget.isYetkili)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: GestureDetector(
                    onTap: widget.onCevap,
                    child: const Text(
                      "Yanıtla",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
