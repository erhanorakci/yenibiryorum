import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Konum için
import 'package:cloud_firestore/cloud_firestore.dart'; // Veri çekmek için
import 'place_detail_screen.dart'; // Detaya gitmek için

class HaritaSayfasi extends StatefulWidget {
  final bool isSelecting; // Seçim modu mu? (Mekan eklerken true olur)

  const HaritaSayfasi({super.key, this.isSelecting = false});
  @override
  State<HaritaSayfasi> createState() => _HaritaSayfasiState();
}

class _HaritaSayfasiState extends State<HaritaSayfasi> {
  GoogleMapController? _controller;
  LatLng? _secilenKonum;
  Set<Marker> _markers = {};

  // İstanbul (Varsayılan Başlangıç)
  static const CameraPosition _baslangicKonumu = CameraPosition(
    target: LatLng(41.0082, 28.9784),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _konumIzniVeMevcutKonum();
    if (!widget.isSelecting) {
      _mekanlariGetir(); // Sadece görüntüleme modundaysa mekanları getir
    }
  }

  // 1. Konum İzni İste ve Oraya Git
  Future<void> _konumIzniVeMevcutKonum() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition();
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }

  // 2. Veritabanındaki Mekanları Haritaya İşle
  Future<void> _mekanlariGetir() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('mekanlar')
        .get();
    Set<Marker> yeniMarkerlar = {};

    for (var doc in snapshot.docs) {
      var data = doc.data();
      // Eğer mekanın konum verisi varsa
      if (data['konum'] != null) {
        GeoPoint pos = data['konum'];
        yeniMarkerlar.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(pos.latitude, pos.longitude),
            infoWindow: InfoWindow(
              title: data['ad'],
              snippet: "${data['kategori']} - Puana Bak",
              onTap: () {
                // Pin'in üzerindeki balona tıklayınca detaya git
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetaySayfasi(
                      mekanId: doc.id,
                      baslik: data['ad'],
                      resimUrl: data['resimUrl'],
                      kategori: data['kategori'],
                      puan: "${data['toplamPuan'] ?? 0}", // Basit gösterim
                      altBaslik: "Haritadan",
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _markers = yeniMarkerlar;
      });
    }
  }

  // 3. Haritaya Tıklama (Sadece Seçim Modunda)
  void _haritayaTiklandi(LatLng pos) {
    if (widget.isSelecting) {
      setState(() {
        _secilenKonum = pos;
        _markers = {
          Marker(
            markerId: const MarkerId("secilen"),
            position: pos,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _baslangicKonumu,
            markers: _markers,
            zoomControlsEnabled: false,
            myLocationEnabled: true, // Mavi nokta (Benim konumum)
            myLocationButtonEnabled: false,
            onMapCreated: (controller) => _controller = controller,
            onTap: _haritayaTiklandi,
          ),

          // Geri Butonu
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back),
              ),
            ),
          ),

          // Konumuma Git Butonu
          Positioned(
            bottom: widget.isSelecting
                ? 100
                : 30, // Buton yeri duruma göre değişsin
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _konumIzniVeMevcutKonum,
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),

          // "BU KONUMU SEÇ" Butonu (Sadece Seçim Modunda Görünür)
          if (widget.isSelecting && _secilenKonum != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  // Seçilen konumu geri gönder
                  Navigator.pop(context, _secilenKonum);
                },
                child: const Text(
                  "BU KONUMU KULLAN",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
