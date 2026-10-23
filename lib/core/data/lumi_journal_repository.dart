import 'package:cloud_firestore/cloud_firestore.dart';

/// Read-only Journal content. No admin credentials are needed in the app.
class LumiJournalRepository {
  LumiJournalRepository._();

  static Future<List<Map<String, dynamic>>> fetchArticles() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('articles')
        .where('isPublished', isEqualTo: true)
        .get();
    final articles = snapshot.docs
        .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
        .where(
          (item) =>
              item['isPublished'] == true || item['status'] == 'published',
        )
        .toList();
    articles.sort((a, b) {
      DateTime dateOf(Map<String, dynamic> item) {
        final value = item['publishedAt'];
        if (value is Timestamp) {
          return value.toDate();
        }
        if (value is DateTime) {
          return value;
        }
        if (value is String) {
          return DateTime.tryParse(value) ?? DateTime(1970);
        }
        return DateTime(1970);
      }

      return dateOf(b).compareTo(dateOf(a));
    });
    return articles;
  }
}
