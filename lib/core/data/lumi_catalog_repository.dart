import 'package:cloud_firestore/cloud_firestore.dart';

class LumiCatalogRepository {
  LumiCatalogRepository._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Map<String, dynamic> _withDemoImage(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final existing = item['imageUrls'];
    final hasImages =
        existing is List &&
        existing.any((v) => v is String && v.trim().isNotEmpty);

    if (hasImages) return item;

    final direct = item['imageUrl'];
    if (direct is String && direct.trim().isNotEmpty) return item;

    const demoImages = <String, String>{
      'spa001': 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=900&auto=format&fit=crop',
      'spa002': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=900&auto=format&fit=crop',
      'spa003': 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=900&auto=format&fit=crop',
      'prd001': 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=900&auto=format&fit=crop',
      'prd002': 'https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8?w=900&auto=format&fit=crop',
    };

    final url = demoImages[id];
    if (url == null) return item;

    return {
      ...item,
      'imageUrl': url,
      'imageUrls': [url],
    };
  }

  static Future<List<Map<String, dynamic>>> fetchServices() async {
    final snapshot = await _db.collection('services').get();
    return snapshot.docs
        .map((doc) {
          return <String, dynamic>{...doc.data(), 'id': doc.id};
        })
        .map(_withDemoImage)
        .where((item) => item['isActive'] != false)
        .toList();
  }

  static Future<List<Map<String, dynamic>>> fetchProducts() async {
    final snapshot = await _db.collection('products').get();
    return snapshot.docs
        .map((doc) {
          return <String, dynamic>{...doc.data(), 'id': doc.id};
        })
        .map(_withDemoImage)
        .where((item) => item['isActive'] != false)
        .toList();
  }
}
