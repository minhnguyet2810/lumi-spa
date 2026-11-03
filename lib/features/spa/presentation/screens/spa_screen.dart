import '../../../../core/theme/lumi_adaptive.dart';

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
    LumiAdaptive.depend(context);
    const plum = Color(0xFF542C43);
    const ivory = Color(0xFFFAF6F0);

    return Scaffold(
      backgroundColor: LumiAdaptive.color(ivory, surface: true),
      appBar: AppBar(
        title: Text(LumiAdaptive.text('LUMI SPA')),
        backgroundColor: LumiAdaptive.color(ivory, surface: true),
        foregroundColor: LumiAdaptive.color(plum),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(color: LumiAdaptive.color(plum)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(LumiAdaptive.text('Không thể tải dịch vụ')),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: refresh,
                    child: Text(LumiAdaptive.text('Thử lại')),
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
                Text(
                  LumiAdaptive.text('A moment for yourself'),
                  style: LumiAdaptive.style(
                    TextStyle(
                      fontSize: 28,
                      fontFamily: 'Cormorant Garamond',
                      color: LumiAdaptive.color(plum),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LumiAdaptive.text(
                    'Khám phá những liệu trình chăm sóc dành riêng cho bạn.',
                  ),
                ),
                const SizedBox(height: 24),
                for (final item in services)
                  Card(
                    color: LumiAdaptive.color(Colors.white, surface: true),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LumiAdaptive.text(item['name'] ?? ''),
                            style: LumiAdaptive.style(
                              TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: LumiAdaptive.color(plum),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(LumiAdaptive.text(item['description'] ?? '')),
                          const SizedBox(height: 12),
                          Text(
                            LumiAdaptive.text(
                              '${item['durationMinutes']} phút · ${item['price']}đ',
                            ),
                            style: LumiAdaptive.style(
                              TextStyle(
                                color: LumiAdaptive.color(plum),
                                fontWeight: FontWeight.bold,
                              ),
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
