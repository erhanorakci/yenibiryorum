import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

// ==================================================
// 1. TOP-LEVEL FONKSİYONLAR (SINIFIN DIŞINDA)
// ==================================================

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _bildirimiVeritabaninaKaydet(message);
}

Future<void> _bildirimiVeritabaninaKaydet(RemoteMessage message) async {
  if (message.notification == null) return;
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  String uniqueId =
      message.messageId ??
      "${message.notification?.title}_${message.notification?.body}_${message.sentTime}";

  var sorgu = await FirebaseFirestore.instance
      .collection('kullanicilar')
      .doc(user.uid)
      .collection('bildirimlerim')
      .where('messageId', isEqualTo: uniqueId)
      .get();

  if (sorgu.docs.isNotEmpty) return;

  String baslik = message.notification?.title ?? "Bildirim";
  String icerik = message.notification?.body ?? "";
  String? imageUrl =
      message.notification?.android?.imageUrl ?? message.data['image'];

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
        'mekanId': mekanId,
        'hedefId': hedefId,
        'hedefBaslik': hedefBaslik,
      });
}

// ==================================================
// 2. BİLDİRİM SERVİSİ SINIFI
// ==================================================
class BildirimServisi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'yorum_platformu_channel',
    'Genel Bildirimler',
    description: 'Uygulama bildirimleri',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> baslat() async {
    // 1. İzin İste
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      print('❌ Kullanıcı bildirim iznini reddetti.');
      return;
    }

    // --- ÖNEMLİ DEĞİŞİKLİK: TOPIC ABONELİĞİ ---
    // Uygulamayı açan herkesi "genel" duyuru kanalına ekle
    await _firebaseMessaging.subscribeToTopic("genel");
    print("✅ 'genel' bildirim kanalına abone olundu.");
    // ------------------------------------------

    await _tokeniGuncelle();

    // 2. Yerel Bildirim Kurulumu
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/notification_icon');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotificationsPlugin.initialize(initializationSettings);

    if (Platform.isAndroid) {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        if (Platform.isAndroid) {
          _yerelBildirimGoster(message);
        }
        _bildirimiVeritabaninaKaydet(message);
      }
    });
  }

  Future<void> _yerelBildirimGoster(RemoteMessage message) async {
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

    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@drawable/notification_icon',
          color: const Color(0xFFFF0000),
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: styleInformation,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
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
