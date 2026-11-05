import 'package:intl/intl.dart';

class FinancialSummary {
  final int totalRevenue;
  final int retailRevenue;
  final int serviceRevenue;
  final int totalCogs;
  final int retailCogs;
  final int serviceCogs;
  final int grossProfit;
  final double grossMarginPercent;
  final double retailRatio;
  final double serviceRatio;
  final int ordersCount;
  final int bookingsCount;
  final int averageOrderValue;
  final int averageBookingValue;

  const FinancialSummary({
    this.totalRevenue = 0,
    this.retailRevenue = 0,
    this.serviceRevenue = 0,
    this.totalCogs = 0,
    this.retailCogs = 0,
    this.serviceCogs = 0,
    this.grossProfit = 0,
    this.grossMarginPercent = 0.0,
    this.retailRatio = 0.0,
    this.serviceRatio = 0.0,
    this.ordersCount = 0,
    this.bookingsCount = 0,
    this.averageOrderValue = 0,
    this.averageBookingValue = 0,
  });

  String get totalRevenueFormatted => formatCurrency(totalRevenue);
  String get retailRevenueFormatted => formatCurrency(retailRevenue);
  String get serviceRevenueFormatted => formatCurrency(serviceRevenue);
  String get totalCogsFormatted => formatCurrency(totalCogs);
  String get grossProfitFormatted => formatCurrency(grossProfit);
  String get averageOrderValueFormatted => formatCurrency(averageOrderValue);
  String get averageBookingValueFormatted => formatCurrency(averageBookingValue);

  static String formatCurrency(num amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      totalRevenue: (json['totalRevenue'] as num?)?.toInt() ?? 0,
      retailRevenue: (json['retailRevenue'] as num?)?.toInt() ?? 0,
      serviceRevenue: (json['serviceRevenue'] as num?)?.toInt() ?? 0,
      totalCogs: (json['totalCogs'] as num?)?.toInt() ?? 0,
      retailCogs: (json['retailCogs'] as num?)?.toInt() ?? 0,
      serviceCogs: (json['serviceCogs'] as num?)?.toInt() ?? 0,
      grossProfit: (json['grossProfit'] as num?)?.toInt() ?? 0,
      grossMarginPercent: (json['grossMarginPercent'] as num?)?.toDouble() ?? 0.0,
      retailRatio: (json['retailRatio'] as num?)?.toDouble() ?? 0.0,
      serviceRatio: (json['serviceRatio'] as num?)?.toDouble() ?? 0.0,
      ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
      bookingsCount: (json['bookingsCount'] as num?)?.toInt() ?? 0,
      averageOrderValue: (json['averageOrderValue'] as num?)?.toInt() ?? 0,
      averageBookingValue: (json['averageBookingValue'] as num?)?.toInt() ?? 0,
    );
  }
}

class DailyFinancialTrend {
  final String date;
  final int retailRevenue;
  final int serviceRevenue;
  final int totalRevenue;
  final int retailCogs;
  final int serviceCogs;
  final int totalCogs;
  final int grossProfit;
  final int ordersCount;
  final int bookingsCount;

  const DailyFinancialTrend({
    required this.date,
    this.retailRevenue = 0,
    this.serviceRevenue = 0,
    this.totalRevenue = 0,
    this.retailCogs = 0,
    this.serviceCogs = 0,
    this.totalCogs = 0,
    this.grossProfit = 0,
    this.ordersCount = 0,
    this.bookingsCount = 0,
  });

  String get shortDate {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}';
      }
    } catch (_) {}
    return date;
  }

  factory DailyFinancialTrend.fromJson(Map<String, dynamic> json) {
    return DailyFinancialTrend(
      date: json['date']?.toString() ?? '',
      retailRevenue: (json['retailRevenue'] as num?)?.toInt() ?? 0,
      serviceRevenue: (json['serviceRevenue'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toInt() ?? 0,
      retailCogs: (json['retailCogs'] as num?)?.toInt() ?? 0,
      serviceCogs: (json['serviceCogs'] as num?)?.toInt() ?? 0,
      totalCogs: (json['totalCogs'] as num?)?.toInt() ?? 0,
      grossProfit: (json['grossProfit'] as num?)?.toInt() ?? 0,
      ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
      bookingsCount: (json['bookingsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class TopPerformerItem {
  final String name;
  final int revenue;
  final int? unitsSold;
  final int? sessionsCount;
  final int cogs;

  const TopPerformerItem({
    required this.name,
    required this.revenue,
    this.unitsSold,
    this.sessionsCount,
    this.cogs = 0,
  });

  int get grossProfit => revenue - cogs;
  double get marginPercent => revenue > 0 ? (grossProfit / revenue) * 100 : 0.0;

  String get revenueFormatted => FinancialSummary.formatCurrency(revenue);
  String get profitFormatted => FinancialSummary.formatCurrency(grossProfit);

  factory TopPerformerItem.fromJson(Map<String, dynamic> json) {
    return TopPerformerItem(
      name: json['name']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
      unitsSold: (json['unitsSold'] as num?)?.toInt(),
      sessionsCount: (json['sessionsCount'] as num?)?.toInt(),
      cogs: (json['cogs'] as num?)?.toInt() ?? 0,
    );
  }
}

class FinancialReportData {
  final FinancialSummary summary;
  final List<DailyFinancialTrend> dailyTrend;
  final List<TopPerformerItem> topProducts;
  final List<TopPerformerItem> topServices;

  const FinancialReportData({
    required this.summary,
    this.dailyTrend = const [],
    this.topProducts = const [],
    this.topServices = const [],
  });

  factory FinancialReportData.fromJson(Map<String, dynamic> json) {
    return FinancialReportData(
      summary: json['summary'] != null
          ? FinancialSummary.fromJson(Map<String, dynamic>.from(json['summary']))
          : const FinancialSummary(),
      dailyTrend: (json['dailyTrend'] as List<dynamic>?)
              ?.map((e) => DailyFinancialTrend.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      topProducts: (json['topProducts'] as List<dynamic>?)
              ?.map((e) => TopPerformerItem.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      topServices: (json['topServices'] as List<dynamic>?)
              ?.map((e) => TopPerformerItem.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }
}
