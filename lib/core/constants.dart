import 'package:flutter/material.dart';

const Color kAnaRenk = Color(0xFF6f42c1);
const Color kArkaPlan = Color(0xFFF9F9F9);
const Color kAltBarRengi = Color(0xFF2E1F47);

const String kAdminEmail = "erhan.orakci@hotmail.com";

// --- ROZET TANIMLARI ---
// Bu yapı sayesinde kodun geri kalanında if-else yazmak yerine
// bu listeyi döngüye sokarak kontrol yapacağız.
const Map<String, Map<String, dynamic>> kRozetler = {
  'gurme': {
    'isim': 'Gurme',
    'ikon': Icons.restaurant,
    'renk': 0xFFE57373, // Kırmızımsı
    'aciklama': '5 Restoran yorumu yaptın!',
    'hedef': 5,
    'kategori': 'Restoran',
  },
  'sinefil': {
    'isim': 'Sinefil',
    'ikon': Icons.movie,
    'renk': 0xFFBA68C8, // Morumsu
    'aciklama': '5 Film/Dizi yorumu yaptın!',
    'hedef': 5,
    'kategori': 'Dizi-Film',
  },
  'kahve_uzmani': {
    'isim': 'Kahve Uzmanı',
    'ikon': Icons.coffee,
    'renk': 0xFF795548, // Kahverengi
    'aciklama': '5 Kafe yorumu yaptın!',
    'hedef': 5,
    'kategori': 'Kafe',
  },
  'efsane': {
    'isim': 'Efsane',
    'ikon': Icons.verified,
    'renk': 0xFFFFD700, // Altın
    'aciklama': 'Toplam 20 yorum yaptın!',
    'hedef': 20,
    'kategori': 'Genel', // Özel kontrol
  },
};
