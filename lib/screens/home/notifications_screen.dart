import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';

class BildirimSayfasi extends StatelessWidget {
  const BildirimSayfasi({super.key});

  // Bildirim Detayını Gösteren Pencere
  void _detayGoster(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['baslik'] ?? "Bildirim"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data['resimUrl'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Image.network(data['resimUrl'], fit: BoxFit.cover),
                ),
              Text(data['icerik'] ?? "", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 15),
              if (data['tarih'] != null)
                Text(
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format((data['tarih'] as Timestamp).toDate()),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirimler"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: user == null
          ? const Center(child: Text("Bildirimleri görmek için giriş yapın."))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('kullanicilar')
                  .doc(user.uid)
                  .collection('bildirimlerim')
                  .orderBy('tarih', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text("Bir hata oluştu."));
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Henüz bildirim yok.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        doc.reference.delete();
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: GestureDetector(
                        onTap: () =>
                            _detayGoster(context, data), // Tıklanınca Detay Aç
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            height: 80, // Sabit yükseklik (Kutu büyümesin diye)
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                // İkon veya Resim
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: kAnaRenk.withOpacity(0.1),
                                  backgroundImage: data['resimUrl'] != null
                                      ? NetworkImage(data['resimUrl'])
                                      : null,
                                  child: data['resimUrl'] == null
                                      ? const Icon(
                                          Icons.notifications,
                                          color: kAnaRenk,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 15),

                                // Metin Alanı
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        data['baslik'] ?? "Bildirim",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow
                                            .ellipsis, // Uzarsa ... koy
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['icerik'] ?? "",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow
                                            .ellipsis, // Uzarsa ... koy
                                      ),
                                      const SizedBox(height: 4),
                                      if (data['tarih'] != null)
                                        Text(
                                          DateFormat('dd/MM HH:mm').format(
                                            (data['tarih'] as Timestamp)
                                                .toDate(),
                                          ),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
