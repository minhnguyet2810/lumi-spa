
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SpaScreen extends StatefulWidget {
  const SpaScreen({super.key});

  @override
  State<SpaScreen> createState() => _SpaScreenState();
}

class _SpaScreenState extends State<SpaScreen> {
  static const apiUrl = 'http://10.0.2.2:3000/api/services';

  late Future<List<dynamic>> servicesFuture;

  @override
  void initState() {
    super.initState();
    servicesFuture = fetchServices();
  }

  Future<List<dynamic>> fetchServices() async {
    final response = await http
        .get(Uri.parse(apiUrl))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Không thể tải dịch vụ');
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));

    if (json['success'] != true) {
      throw Exception('API trả về lỗi');
    }

    return json['data'] as List<dynamic>;
  }

  void refresh() {
    setState(() {
      servicesFuture = fetchServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    const plum = Color(0xFF542C43);
    const ivory = Color(0xFFFAF6F0);

    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        title: const Text('LUMI SPA'),
        backgroundColor: ivory,
        foregroundColor: plum,
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: plum),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không thể tải dịch vụ'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: refresh,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final services = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              refresh();
              await servicesFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'A moment for yourself',
                  style: TextStyle(
                    fontSize: 28,
                    fontFamily: 'Cormorant Garamond',
                    color: plum,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Khám phá những liệu trình chăm sóc dành riêng cho bạn.',
                ),
                const SizedBox(height: 24),
                for (final item in services)
                  Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: plum,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(item['description'] ?? ''),
                          const SizedBox(height: 12),
                          Text(
                            '${item['durationMinutes']} phút · ${item['price']}đ',
                            style: const TextStyle(
                              color: plum,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
