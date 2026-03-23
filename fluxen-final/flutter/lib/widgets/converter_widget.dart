import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/currency_service.dart';

class ConverterWidget extends StatelessWidget {
  final String from, to;
  final TextEditingController amtCtrl;
  final ConversionResult? result;
  final bool loading;
  final String? error;
  final bool isDark;
  final Color accent, surface, s2, border, muted, text;
  final ValueChanged<String?> onFromChanged, onToChanged;
  final VoidCallback onSwap, onConvert;

  const ConverterWidget({
    super.key,
    required this.from, required this.to, required this.amtCtrl,
    required this.result, required this.loading, required this.error,
    required this.isDark, required this.accent, required this.surface,
    required this.s2, required this.border, required this.muted,
    required this.text, required this.onFromChanged, required this.onToChanged,
    required this.onSwap, required this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(children: [
        // Top accent line
        Container(height: 1, decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.transparent, accent, Colors.transparent]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        )),
        Padding(padding: const EdgeInsets.all(18), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Amount'),
            const SizedBox(height: 6),
            _inputRow(amtCtrl, from, onFromChanged, isAmount: true),
            const SizedBox(height: 10),
            Center(child: GestureDetector(
              onTap: onSwap,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: s2, border: Border.all(color: border), shape: BoxShape.circle,
                ),
                child: Icon(Icons.swap_vert, color: text, size: 18),
              ),
            )),
            const SizedBox(height: 10),
            _label('Convert to'),
            const SizedBox(height: 6),
            _resultRow(),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: loading ? null : onConvert,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : Text('CONVERT', style: GoogleFonts.syne(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: Colors.black, letterSpacing: 1.5)),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6D).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFFFF4D6D).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(error!, style: GoogleFonts.dmMono(fontSize: 12, color: const Color(0xFFFF4D6D))),
              ),
            ],
            if (result != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: s2, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(child: Text(
                        result!.converted.toStringAsFixed(4),
                        style: GoogleFonts.dmMono(
                          fontSize: 30, fontWeight: FontWeight.w500,
                          color: accent, letterSpacing: -1,
                        ),
                      )),
                      const SizedBox(width: 8),
                      Text(result!.to, style: GoogleFonts.syne(
                        fontSize: 16, fontWeight: FontWeight.w700, color: muted,
                      )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('1 ${result!.from} = ${result!.rate.toStringAsFixed(6)} ${result!.to}',
                    style: GoogleFonts.dmMono(fontSize: 12, color: muted)),
                  const SizedBox(height: 2),
                  Text('1 ${result!.to} = ${(1/result!.rate).toStringAsFixed(6)} ${result!.from}',
                    style: GoogleFonts.dmMono(fontSize: 12, color: muted)),
                  const SizedBox(height: 2),
                  Text('Updated: ${result!.date}',
                    style: GoogleFonts.dmMono(fontSize: 11, color: muted)),
                ]),
              ),
            ],
          ],
        )),
      ]),
    );
  }

  Widget _label(String t) => Text(t.toUpperCase(),
    style: GoogleFonts.dmMono(fontSize: 10, letterSpacing: 2, color: muted));

  Widget _inputRow(TextEditingController ctrl, String cur, ValueChanged<String?> onChange, {bool isAmount = false}) {
    return Container(
      decoration: BoxDecoration(
        color: s2, border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Expanded(child: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.dmMono(fontSize: 20, fontWeight: FontWeight.w500, color: text),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        )),
        _dropdown(cur, onChange),
      ]),
    );
  }

  Widget _resultRow() {
    return Container(
      decoration: BoxDecoration(
        color: s2, border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Text(
            result != null ? result!.converted.toStringAsFixed(4) : '—',
            style: GoogleFonts.dmMono(
              fontSize: 20, fontWeight: FontWeight.w500,
              color: result != null ? accent : muted,
            ),
          ),
        )),
        _dropdown(to, onToChanged),
      ]),
    );
  }

  Widget _dropdown(String value, ValueChanged<String?> onChange) {
    final valid = CurrencyService.currencies.containsKey(value);
    return Container(
      decoration: BoxDecoration(border: Border(left: BorderSide(color: border))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valid ? value : null,
          items: CurrencyService.currencies.keys.map((c) => DropdownMenuItem(
            value: c,
            child: Text(c, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: text)),
          )).toList(),
          onChanged: onChange,
          icon: Icon(Icons.keyboard_arrow_down, size: 16, color: muted),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          dropdownColor: isDark ? const Color(0xFF1C1C28) : Colors.white,
        ),
      ),
    );
  }
}
