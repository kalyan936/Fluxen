import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const _openApi = 'https://open.er-api.com/v6/latest';
const _frank   = 'https://api.frankfurter.app';

class CurrencyService {
  static const currencies = {
    'USD': 'US Dollar',      'EUR': 'Euro',            'GBP': 'British Pound',
    'JPY': 'Japanese Yen',   'INR': 'Indian Rupee',    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar','CHF': 'Swiss Franc',     'CNY': 'Chinese Yuan',
    'SGD': 'Singapore Dollar','HKD': 'Hong Kong Dollar','KRW': 'South Korean Won',
    'MXN': 'Mexican Peso',   'BRL': 'Brazilian Real',  'NOK': 'Norwegian Krone',
    'SEK': 'Swedish Krona',  'NZD': 'New Zealand Dollar','ZAR': 'South African Rand',
    'THB': 'Thai Baht',      'DKK': 'Danish Krone',    'TRY': 'Turkish Lira',
    'AED': 'UAE Dirham',     'SAR': 'Saudi Riyal',     'PKR': 'Pakistani Rupee',
    'MYR': 'Malaysian Ringgit','IDR': 'Indonesian Rupiah',
  };

  static Future<ConversionResult?> convert({
    required String from,
    required String to,
    required double amount,
  }) async {
    if (from == to) {
      return ConversionResult(
        from: from, to: to, amount: amount,
        converted: amount, rate: 1.0,
        date: _today(),
      );
    }

    // Method 1: dart:io HttpClient (bypasses Android permission issues)
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(Uri.parse('$_openApi/$from'));
      request.headers.set('Accept', 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();
      if (response.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        if (data['result'] == 'success') {
          final rate = (data['rates'][to] as num?)?.toDouble();
          if (rate != null) {
            return ConversionResult(
              from: from, to: to, amount: amount,
              converted: rate * amount, rate: rate,
              date: (data['time_last_update_utc'] as String?)?.substring(0, 10) ?? _today(),
            );
          }
        }
      }
    } catch (_) {}

    // Method 2: http package
    try {
      final res = await http
          .get(Uri.parse('$_openApi/$from'), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['result'] == 'success') {
          final rate = (data['rates'][to] as num?)?.toDouble();
          if (rate != null) {
            return ConversionResult(
              from: from, to: to, amount: amount,
              converted: rate * amount, rate: rate,
              date: (data['time_last_update_utc'] as String?)?.substring(0, 10) ?? _today(),
            );
          }
        }
      }
    } catch (_) {}

    // Method 3: Frankfurter via EUR
    try {
      double amountInEur;
      String date = _today();
      if (from == 'EUR') {
        amountInEur = amount;
      } else {
        final r = await http
            .get(Uri.parse('$_frank/latest?from=$from&to=EUR&amount=$amount'))
            .timeout(const Duration(seconds: 15));
        if (r.statusCode != 200) return null;
        final d = jsonDecode(r.body);
        amountInEur = (d['rates']['EUR'] as num).toDouble();
        date = d['date'] as String;
      }
      double converted;
      if (to == 'EUR') {
        converted = amountInEur;
      } else {
        final r2 = await http
            .get(Uri.parse('$_frank/latest?from=EUR&to=$to&amount=$amountInEur'))
            .timeout(const Duration(seconds: 15));
        if (r2.statusCode != 200) return null;
        final d2 = jsonDecode(r2.body);
        converted = (d2['rates'][to] as num).toDouble();
        date = d2['date'] as String;
      }
      return ConversionResult(
        from: from, to: to, amount: amount,
        converted: converted, rate: converted / amount, date: date,
      );
    } catch (_) {}

    return null;
  }

  static Future<HistoryResult?> getHistory({
    required String from,
    required String to,
    required int days,
  }) async {
    try {
      final end = DateTime.now();
      final start = end.subtract(Duration(days: days));
      final s = _fmtDate(start), e = _fmtDate(end);
      List<RatePoint> series;

      if (from == 'EUR' || to == 'EUR') {
        final base = from == 'EUR' ? to : from;
        final r = await http
            .get(Uri.parse('$_frank/$s..$e?from=EUR&to=$base'))
            .timeout(const Duration(seconds: 20));
        if (r.statusCode != 200) return null;
        final rm = jsonDecode(r.body)['rates'] as Map<String, dynamic>;
        final dates = rm.keys.toList()..sort();
        series = dates.map((dt) {
          double v = (rm[dt][base] as num).toDouble();
          if (from != 'EUR') v = 1.0 / v;
          return RatePoint(date: dt, rate: v);
        }).toList();
      } else {
        final rs = await Future.wait([
          http.get(Uri.parse('$_frank/$s..$e?from=$from&to=EUR')).timeout(const Duration(seconds: 20)),
          http.get(Uri.parse('$_frank/$s..$e?from=EUR&to=$to')).timeout(const Duration(seconds: 20)),
        ]);
        if (rs[0].statusCode != 200 || rs[1].statusCode != 200) return null;
        final r1 = jsonDecode(rs[0].body)['rates'] as Map<String, dynamic>;
        final r2 = jsonDecode(rs[1].body)['rates'] as Map<String, dynamic>;
        final common = r1.keys.toSet().intersection(r2.keys.toSet()).toList()..sort();
        series = common.map((dt) {
          final rate = (1.0 / (r1[dt]['EUR'] as num).toDouble()) * (r2[dt][to] as num).toDouble();
          return RatePoint(date: dt, rate: rate);
        }).toList();
      }

      if (series.isEmpty) return null;
      final vals = series.map((p) => p.rate).toList();
      return HistoryResult(
        series: series,
        min: vals.reduce((a, b) => a < b ? a : b),
        max: vals.reduce((a, b) => a > b ? a : b),
        avg: vals.reduce((a, b) => a + b) / vals.length,
        changePct: ((vals.last - vals.first) / vals.first) * 100,
      );
    } catch (_) {
      return null;
    }
  }

  static String _today() => _fmtDate(DateTime.now());
  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}

class ConversionResult {
  final String from, to, date;
  final double amount, converted, rate;
  const ConversionResult({
    required this.from, required this.to, required this.date,
    required this.amount, required this.converted, required this.rate,
  });
}

class HistoryResult {
  final List<RatePoint> series;
  final double min, max, avg, changePct;
  const HistoryResult({
    required this.series, required this.min, required this.max,
    required this.avg, required this.changePct,
  });
}

class RatePoint {
  final String date;
  final double rate;
  const RatePoint({required this.date, required this.rate});
}
