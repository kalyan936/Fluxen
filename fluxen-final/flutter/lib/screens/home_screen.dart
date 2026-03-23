import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/currency_service.dart';
import '../widgets/converter_widget.dart';
import '../widgets/chart_widget.dart';
import '../widgets/stats_widget.dart';

class HomeScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;
  const HomeScreen({super.key, required this.isDark, required this.onToggle});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _from = 'USD';
  String _to   = 'INR';
  double _amount = 1.0;
  ConversionResult? _result;
  HistoryResult?    _history;
  bool _loading = false;
  bool _loadingChart = false;
  String? _error;
  int _days = 30;

  final _amtCtrl = TextEditingController(text: '1');

  Color get _accent => widget.isDark ? const Color(0xFFC8F542) : const Color(0xFF3D7A00);
  Color get _bg     => widget.isDark ? const Color(0xFF09090F) : const Color(0xFFF4F4F9);
  Color get _surface=> widget.isDark ? const Color(0xFF13131C) : Colors.white;
  Color get _s2     => widget.isDark ? const Color(0xFF1C1C28) : const Color(0xFFEBEBF5);
  Color get _border => widget.isDark ? const Color(0xFF222232) : const Color(0xFFDDDDEE);
  Color get _muted  => widget.isDark ? const Color(0xFF5A5A72) : const Color(0xFF888899);
  Color get _text   => widget.isDark ? const Color(0xFFF0F0F8) : const Color(0xFF0A0A18);

  @override
  void dispose() { _amtCtrl.dispose(); super.dispose(); }

  Future<void> _convert() async {
    final amt = double.tryParse(_amtCtrl.text);
    if (amt == null || amt <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    setState(() { _loading = true; _error = null; _amount = amt; });
    HapticFeedback.lightImpact();
    final r = await CurrencyService.convert(from: _from, to: _to, amount: amt);
    if (!mounted) return;
    setState(() {
      _result = r;
      _loading = false;
      _error = r == null ? 'Conversion failed. Check internet.' : null;
    });
    if (r != null) _loadChart();
  }

  Future<void> _loadChart() async {
    setState(() => _loadingChart = true);
    final h = await CurrencyService.getHistory(from: _from, to: _to, days: _days);
    if (!mounted) return;
    setState(() { _history = h; _loadingChart = false; });
  }

  void _swap() {
    setState(() {
      final tmp = _from; _from = _to; _to = tmp;
      _result = null; _history = null;
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: _bg,
              elevation: 0,
              title: RichText(
                text: TextSpan(
                  style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: _text),
                  children: [
                    const TextSpan(text: 'Flu'),
                    TextSpan(text: 'xen', style: TextStyle(color: _accent)),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    widget.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: _muted, size: 20,
                  ),
                  onPressed: widget.onToggle,
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  Text('Currency\nIntelligence',
                    style: GoogleFonts.syne(
                      fontSize: 34, fontWeight: FontWeight.w800,
                      color: _text, height: 1.05, letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Live rates · No fees · Open API',
                    style: GoogleFonts.dmMono(fontSize: 12, color: _muted),
                  ),
                  const SizedBox(height: 20),
                  ConverterWidget(
                    from: _from, to: _to,
                    amtCtrl: _amtCtrl,
                    result: _result,
                    loading: _loading,
                    error: _error,
                    isDark: widget.isDark,
                    accent: _accent, surface: _surface, s2: _s2,
                    border: _border, muted: _muted, text: _text,
                    onFromChanged: (v) => setState(() { _from = v!; _result = null; _history = null; }),
                    onToChanged:   (v) => setState(() { _to   = v!; _result = null; _history = null; }),
                    onSwap: _swap,
                    onConvert: _convert,
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 14),
                    StatsWidget(
                      history: _history,
                      isDark: widget.isDark,
                      surface: _surface, border: _border,
                      muted: _muted, text: _text, accent: _accent,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [7,30,90,180,365].map((d) {
                          final lbl = {7:'7D',30:'1M',90:'3M',180:'6M',365:'1Y'}[d]!;
                          final active = d == _days;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () { setState(() => _days = d); _loadChart(); },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: active ? _accent : _surface,
                                  border: Border.all(color: active ? _accent : _border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(lbl, style: GoogleFonts.dmMono(
                                  fontSize: 11, fontWeight: FontWeight.w500,
                                  color: active ? Colors.black : _muted,
                                )),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ChartWidget(
                      history: _history, loading: _loadingChart,
                      from: _from, to: _to,
                      isDark: widget.isDark,
                      accent: _accent, surface: _surface,
                      border: _border, muted: _muted, text: _text,
                    ),
                  ],
                  const SizedBox(height: 32),
                  Center(child: Text('Fluxen · open.er-api.com · Free forever',
                    style: GoogleFonts.dmMono(fontSize: 11, color: _muted),
                  )),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
