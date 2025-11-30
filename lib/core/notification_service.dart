import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Renkler için
import 'package:http/http.dart' as http;
import 'dart:typed_data';

// --- ARKA PLAN İŞLEYİCİSİ (Sadece DB'ye kaydeder, bildirim göstermez - Çift bildirimi engeller) ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Arka planda bildirim gösterme komutu YOK, sadece kayıt var.
  await _bildirimiVeritabaninaKaydet(message);
}

// --- VERİTABANI KAYIT FONKSİYONU (Aynı ID kontrolü ile) ---
Future<void> _bildirimiVeritabaninaKaydet(RemoteMessage message) async {
  if (message.notification == null) return;

  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Benzersiz ID oluştur
  String uniqueId =
      message.messageId ??
      "${message.notification?.title}_${message.notification?.body}_${message.sentTime}";

  // Çift kayıt kontrolü
  var sorgu = await FirebaseFirestore.instance
      .collection('kullanicilar')
      .doc(user.uid)
      .collection('bildirimlerim')
      .where('messageId', isEqualTo: uniqueId)
      .get();

  if (sorgu.docs.isNotEmpty) {
    return; // Zaten varsa kaydetme
  }

  // Kayıt işlemi
  String baslik = message.notification?.title ?? "Bildirim";
  String icerik = message.notification?.body ?? "";
  String? imageUrl =
      message.notification?.android?.imageUrl ?? message.data['image'];

  // Hedef ID verilerini al (Tıklama yönlendirmesi için)
  String? mekanId = message.data['mekanId'];
  String? hedefId = message.data['hedefId'];
  String? hedefBaslik = message.data['hedefBaslik'];

  await FirebaseFirestore.instance
      .collection('kullanicilar')
      .doc(user.uid)
      .collection('bildirimlerim')
      .add({
        'messageId': uniqueId,
        'baslik': baslik,
        'icerik': icerik,
        'tarih': FieldValue.serverTimestamp(),
        'okundu': false,
        'resimUrl': imageUrl,
        // Yönlendirme verilerini de kaydediyoruz
        'mekanId': mekanId,
        'hedefId': hedefId,
        'hedefBaslik': hedefBaslik,
      });
}

class BildirimServisi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Kanal Tanımı
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'yorum_platformu_channel', // Kanal ID'si sabit kalmalı
    'Genel Bildirimler',
    description: 'Uygulama bildirimleri',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> baslat() async {
    // İzin İste
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Token güncelle
    await _tokeniGuncelle();

    // Android Başlatma Ayarları
    // 'notification_icon' adında transparent bir PNG'nin drawable klasöründe olduğundan emin ol.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/notification_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(initializationSettings);

    // Kanalı Oluştur
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Arka Plan Handler'ı Ata
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ÖN PLAN (FOREGROUND) DİNLEYİCİSİ
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Sadece bildirim içeriği varsa işlem yap
      if (message.notification != null) {
        // Ön planda olduğumuz için bildirimi manuel gösteriyoruz
        _yerelBildirimGoster(message);

        // Veritabanına da kaydediyoruz
        _bildirimiVeritabaninaKaydet(message);
      }
    });
  }

  Future<void> _yerelBildirimGoster(RemoteMessage message) async {
    // Resim varsa işle
    String? imageUrl =
        message.notification?.android?.imageUrl ?? message.data['image'];
    ByteArrayAndroidBitmap? bigPicture;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final http.Response response = await http.get(Uri.parse(imageUrl));
        bigPicture = ByteArrayAndroidBitmap(response.bodyBytes);
      } catch (e) {
        print("Resim yükleme hatası: $e");
      }
    }

    // Stil ayarla (Resimli veya Büyük Metinli)
    StyleInformation? styleInformation;
    if (bigPicture != null) {
      styleInformation = BigPictureStyleInformation(
        bigPicture,
        contentTitle: message.notification?.title,
        summaryText: message.notification?.body,
        hideExpandedLargeIcon: true,
      );
    } else {
      styleInformation = BigTextStyleInformation(
        message.notification?.body ?? '',
      );
    }

    // BİLDİRİMİ GÖSTER
    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          // --- İKON AYARLARI BURADA ---
          icon: '@drawable/notification_icon', // Şeffaf PNG olmalı
          // İKON RENGİNİ KIRMIZI YAPIYORUZ
          // Android bu rengi ikonu boyamak için kullanır.
          color: const Color(0xFFFF0000), // Kırmızı (#FF0000)
          // ----------------------------
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: styleInformation,
        ),
      ),
    );
  }

  Future<void> _tokeniGuncelle() async {
    String? token = await _firebaseMessaging.getToken();
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  }
}
