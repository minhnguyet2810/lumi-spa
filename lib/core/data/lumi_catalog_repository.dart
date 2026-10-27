import 'package:cloud_firestore/cloud_firestore.dart';

class LumiCatalogRepository {
  LumiCatalogRepository._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Map<String, String> _demoImages = <String, String>{
    // Spa Services
    'spa001': 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=900&auto=format&fit=crop',
    'spa002': 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=900&auto=format&fit=crop',
    'spa003': 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=900&auto=format&fit=crop',
    'prd001': 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=900&auto=format&fit=crop',
    'prd002': 'https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8?w=900&auto=format&fit=crop',

    // Làm sạch & Cân bằng (lumi-001 to lumi-010)
    'lumi-001': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=900&auto=format&fit=crop',
    'lumi-002': 'https://images.unsplash.com/photo-1608248597359-00f7243c2c19?w=900&auto=format&fit=crop',
    'lumi-003': 'https://images.unsplash.com/photo-1556228722-d0b5de75d776?w=900&auto=format&fit=crop',
    'lumi-004': 'https://images.unsplash.com/photo-1567928815116-24ba00508dc2?w=900&auto=format&fit=crop',
    'lumi-005': 'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=900&auto=format&fit=crop',
    'lumi-006': 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=900&auto=format&fit=crop',
    'lumi-007': 'https://images.unsplash.com/photo-1617897903246-719242758050?w=900&auto=format&fit=crop',
    'lumi-008': 'https://images.unsplash.com/photo-1601049541289-9b1b7bbbfe19?w=900&auto=format&fit=crop',
    'lumi-009': 'https://images.unsplash.com/photo-1616683693504-3ea7e9ad6fec?w=900&auto=format&fit=crop',
    'lumi-010': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=900&auto=format&fit=crop',

    // Tinh chất đặc trị & Tế bào gốc (lumi-011 to lumi-020)
    'lumi-011': 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=900&auto=format&fit=crop',
    'lumi-012': 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=900&auto=format&fit=crop',
    'lumi-013': 'https://images.unsplash.com/photo-1617897903246-719242758050?w=900&auto=format&fit=crop',
    'lumi-014': 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=900&auto=format&fit=crop',
    'lumi-015': 'https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8?w=900&auto=format&fit=crop',
    'lumi-016': 'https://images.unsplash.com/photo-1601049541289-9b1b7bbbfe19?w=900&auto=format&fit=crop',
    'lumi-017': 'https://images.unsplash.com/photo-1608248597359-00f7243c2c19?w=900&auto=format&fit=crop',
    'lumi-018': 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=900&auto=format&fit=crop',
    'lumi-019': 'https://images.unsplash.com/photo-1616683693504-3ea7e9ad6fec?w=900&auto=format&fit=crop',
    'lumi-020': 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=900&auto=format&fit=crop',

    // Dưỡng ẩm & Khóa dưỡng (lumi-021 to lumi-030)
    'lumi-021': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=900&auto=format&fit=crop',
    'lumi-022': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=900&auto=format&fit=crop',
    'lumi-023': 'https://images.unsplash.com/photo-1556228722-d0b5de75d776?w=900&auto=format&fit=crop',
    'lumi-024': 'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=900&auto=format&fit=crop',
    'lumi-025': 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=900&auto=format&fit=crop',
    'lumi-026': 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=900&auto=format&fit=crop',
    'lumi-027': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=900&auto=format&fit=crop',
    'lumi-028': 'https://images.unsplash.com/photo-1608248597359-00f7243c2c19?w=900&auto=format&fit=crop',
    'lumi-029': 'https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8?w=900&auto=format&fit=crop',
    'lumi-030': 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=900&auto=format&fit=crop',

    // Mặt nạ chăm sóc chuyên sâu (lumi-031 to lumi-035)
    'lumi-031': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=900&auto=format&fit=crop',
    'lumi-032': 'https://images.unsplash.com/photo-1567928815116-24ba00508dc2?w=900&auto=format&fit=crop',
    'lumi-033': 'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=900&auto=format&fit=crop',
    'lumi-034': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=900&auto=format&fit=crop',
    'lumi-035': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=900&auto=format&fit=crop',

    // Chống nắng & Bảo vệ quang học (lumi-036 to lumi-040)
    'lumi-036': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=900&auto=format&fit=crop',
    'lumi-037': 'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=900&auto=format&fit=crop',
    'lumi-038': 'https://images.unsplash.com/photo-1617897903246-719242758050?w=900&auto=format&fit=crop',
    'lumi-039': 'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=900&auto=format&fit=crop',
    'lumi-040': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=900&auto=format&fit=crop',

    // Chăm sóc cơ thể & Dưỡng sinh (lumi-041 to lumi-050)
    'lumi-041': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=900&auto=format&fit=crop',
    'lumi-042': 'https://images.unsplash.com/photo-1556228722-d0b5de75d776?w=900&auto=format&fit=crop',
    'lumi-043': 'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=900&auto=format&fit=crop',
    'lumi-044': 'https://images.unsplash.com/photo-1608248597359-00f7243c2c19?w=900&auto=format&fit=crop',
    'lumi-045': 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=900&auto=format&fit=crop',
    'lumi-046': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=900&auto=format&fit=crop',
    'lumi-047': 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=900&auto=format&fit=crop',
    'lumi-048': 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=900&auto=format&fit=crop',
    'lumi-049': 'https://images.unsplash.com/photo-1556229010-6c3f2c9ca5f8?w=900&auto=format&fit=crop',
    'lumi-050': 'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=900&auto=format&fit=crop',
  };

  static const Map<String, String> _categoryFallbackImages = <String, String>{
    'Làm sạch & Cân bằng':
        'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=900&auto=format&fit=crop',
    'Tinh chất đặc trị & Tế bào gốc':
        'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=900&auto=format&fit=crop',
    'Dưỡng ẩm & Khóa dưỡng':
        'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=900&auto=format&fit=crop',
    'Mặt nạ chăm sóc chuyên sâu':
        'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=900&auto=format&fit=crop',
    'Chống nắng & Bảo vệ quang học':
        'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=900&auto=format&fit=crop',
    'Chăm sóc cơ thể & Dưỡng sinh':
        'https://images.unsplash.com/photo-1556228722-d0b5de75d776?w=900&auto=format&fit=crop',
  };

  static const String _defaultProductImage =
      'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=900&auto=format&fit=crop';

  static Map<String, dynamic> _withDemoImage(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final existing = item['imageUrls'];
    final hasImages =
        existing is List &&
        existing.any((v) => v is String && v.trim().isNotEmpty);

    if (hasImages) {
      final first = existing.firstWhere(
        (v) => v is String && v.trim().isNotEmpty,
        orElse: () => null,
      );
      if (first != null && (item['imageUrl'] == null || item['imageUrl'].toString().isEmpty)) {
        return {
          ...item,
          'imageUrl': first,
        };
      }
      return item;
    }

    final direct = item['imageUrl'];
    if (direct is String && direct.trim().isNotEmpty) {
      return {
        ...item,
        'imageUrls': [direct.trim()],
      };
    }

    // Tra cứu theo ID
    String? url = _demoImages[id];

    // Tra cứu fallback theo Category
    if (url == null) {
      final category = item['category']?.toString();
      if (category != null && _categoryFallbackImages.containsKey(category)) {
        url = _categoryFallbackImages[category];
      }
    }

    // Fallback mặc định
    url ??= _defaultProductImage;

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
