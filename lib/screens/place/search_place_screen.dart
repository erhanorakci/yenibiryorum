import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import 'add_place_screen.dart';
import 'place_detail_screen.dart';

class MekanAramaSayfasi extends StatefulWidget {
  final String? baslangicAramasi; // Ana sayfadan gelen kategori
  final List<String>? ozelMekanListesi; // KAMPANYA: Özel mekan ID listesi

  const MekanAramaSayfasi({
    super.key,
    this.baslangicAramasi,
    this.ozelMekanListesi,
  });

  @override
  State<MekanAramaSayfasi> createState() => _MekanAramaSayfasiState();
}

class _MekanAramaSayfasiState extends State<MekanAramaSayfasi> {
  String _aramaKelimesi = "";
  String _secilenKategori = "Hepsi";

  // --- FİLTRE DEĞİŞKENLERİ ---
  double _minPuan = 0.0;
  String _siralama = "yorumSayisi";
  bool _sadeceFotografli = false;

  final List<String> _kategoriler = [
    "Hepsi",
    "Restoran",
    "Kafe",
    "Dizi-Film",
    "Ünlü",
    "Firma",
    "Diğer",
  ];

  @override
  void initState() {
    super.initState();
    // Kampanya listesi yoksa kategoriyi ayarla
    if (widget.ozelMekanListesi == null && widget.baslangicAramasi != null) {
      if (_kategoriler.contains(widget.baslangicAramasi)) {
        _secilenKategori = widget.baslangicAramasi!;
      }
    }
  }

  // --- FİLTRE MENÜSÜ ---
  void _filtrePenceresiniAc() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sıralama ve Filtreleme",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Sıralama Ölçütü",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text("En Popüler"),
                        selected: _siralama == "yorumSayisi",
                        onSelected: (v) =>
                            setStateModal(() => _siralama = "yorumSayisi"),
                      ),
                      ChoiceChip(
                        label: const Text("En Yeni"),
                        selected: _siralama == "tarih",
                        onSelected: (v) =>
                            setStateModal(() => _siralama = "tarih"),
                      ),
                      ChoiceChip(
                        label: const Text("Yüksek Puan"),
                        selected: _siralama == "toplamPuan",
                        onSelected: (v) =>
                            setStateModal(() => _siralama = "toplamPuan"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Minimum Puan",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Slider(
                    value: _minPuan,
                    min: 0.0,
                    max: 5.0,
                    divisions: 5,
                    label: "$_minPuan ve üzeri",
                    activeColor: kAnaRenk,
                    onChanged: (val) => setStateModal(() => _minPuan = val),
                  ),
                  Center(
                    child: Text(
                      "${_minPuan.toInt()}+ Yıldız",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text("Sadece Fotoğraflı Olanlar"),
                    value: _sadeceFotografli,
                    activeColor: kAnaRenk,
                    onChanged: (val) =>
                        setStateModal(() => _sadeceFotografli = val),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAnaRenk,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: const Text("UYGULA"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kampanya modu aktif mi? (Özel liste doluysa)
    bool kampanyaModu =
        widget.ozelMekanListesi != null && widget.ozelMekanListesi!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          kampanyaModu ? "Günün Favorileri" : "Keşfet",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _filtrePenceresiniAc,
            tooltip: "Filtrele",
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve Kategori Seçimi SADECE normal modda görünsün
          if (!kampanyaModu) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Mekan, kişi veya eser ara...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (val) => setState(() => _aramaKelimesi = val),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _kategoriler.map((kategori) {
                  bool isSelected = _secilenKategori == kategori;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(kategori),
                      selected: isSelected,
                      selectedColor: kAnaRenk,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      backgroundColor: Colors.white,
                      onSelected: (bool selected) =>
                          setState(() => _secilenKategori = kategori),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
          ],

          // --- LİSTELEME ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _sorguOlustur(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print("Sorgu Hatası: ${snapshot.error}");
                  return const Center(
                    child: Text(
                      "Sıralama için Index Gerekli (Debug Console'a bak)",
                    ),
                  );
                }
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;

                // --- CLIENT-SIDE FİLTRELEME ---
                var filtrelenmisListe = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  // 1. KAMPANYA FİLTRESİ (Eğer özel liste geldiyse sadece onları göster)
                  if (kampanyaModu) {
                    if (!widget.ozelMekanListesi!.contains(doc.id))
                      return false;
                  }
                  // Normal modda isim araması
                  else if (_aramaKelimesi.isNotEmpty) {
                    String mekanAdi = (data['ad'] ?? "")
                        .toString()
                        .toLowerCase();
                    String aranan = _aramaKelimesi.toLowerCase();
                    if (!mekanAdi.contains(aranan)) return false;
                  }

                  // 2. Fotoğraf Kontrolü
                  if (_sadeceFotografli &&
                      (data['resimUrl'] == null || data['resimUrl'] == ""))
                    return false;

                  // 3. Puan Kontrolü
                  int toplam = data['toplamPuan'] ?? 0;
                  int adet = data['yorumSayisi'] ?? 0;
                  double ortalama = adet > 0 ? toplam / adet : 0.0;
                  if (ortalama < _minPuan) return false;

                  return true;
                }).toList();

                if (filtrelenmisListe.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        const Text("Aradığınız kriterlere uygun sonuç yok."),
                        const SizedBox(height: 20),
                        // "Bu İçeriği Sen Ekle" butonu sadece normal aramada çıksın
                        if (!kampanyaModu && _aramaKelimesi.isNotEmpty)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAnaRenk,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MekanEkleSayfasi(oneriIsim: _aramaKelimesi),
                              ),
                            ),
                            child: const Text("BU İÇERİĞİ SEN EKLE"),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtrelenmisListe.length,
                  itemBuilder: (context, index) {
                    var mekan = filtrelenmisListe[index];
                    var data = mekan.data() as Map<String, dynamic>;

                    int toplamPuan = data['toplamPuan'] ?? 0;
                    int yorumSayisi = data['yorumSayisi'] ?? 0;
                    double ortalama = yorumSayisi > 0
                        ? toplamPuan / yorumSayisi
                        : 0.0;
                    String puanGosterimi = ortalama == 0
                        ? "Yeni"
                        : ortalama.toStringAsFixed(1);

                    // Çoklu görsel varsa ilki, yoksa placeholder
                    List<dynamic> resimler = data['resimUrls'] ?? [];
                    String gorselUrl = resimler.isNotEmpty
                        ? resimler.first
                        : (data['resimUrl'] ??
                              'https://via.placeholder.com/150');

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          gorselUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            width: 60,
                            height: 60,
                            child: const Icon(Icons.image),
                          ),
                        ),
                      ),
                      title: Text(
                        data['ad'] ?? data['baslik'] ?? "İsimsiz",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(
                        children: [
                          Text(data['kategori'] ?? "Genel"),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.orange,
                          ),
                          Text(" $puanGosterimi ($yorumSayisi)"),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetaySayfasi(
                            mekanId: mekan.id,
                            baslik: data['ad'] ?? data['baslik'] ?? "İsimsiz",
                            resimUrl: gorselUrl,
                            kategori: data['kategori'] ?? "Genel",
                            puan: puanGosterimi,
                            altBaslik: data['kategori'] ?? "Genel",
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _sorguOlustur() {
    Query sorgu = FirebaseFirestore.instance.collection('mekanlar');

    // Kampanya modunda tüm mekanları çekip client'ta süzelim
    if (widget.ozelMekanListesi != null &&
        widget.ozelMekanListesi!.isNotEmpty) {
      return sorgu.snapshots();
    }

    // Normal modda kategori filtresi
    if (_secilenKategori != "Hepsi") {
      sorgu = sorgu.where('kategori', isEqualTo: _secilenKategori);
    }

    sorgu = sorgu.orderBy(_siralama, descending: true);
    return sorgu.snapshots();
  }
}
