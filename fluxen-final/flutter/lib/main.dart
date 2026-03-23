import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const FluxenApp());
}

class FluxenApp extends StatefulWidget {
  const FluxenApp({super.key});
  @override
  State<FluxenApp> createState() => _FluxenAppState();
}

class _FluxenAppState extends State<FluxenApp> {
  bool _dark = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluxen',
      debugShowCheckedModeBanner: false,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF09090F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC8F542),
          surface: Color(0xFF13131C),
          onPrimary: Colors.black,
          onSurface: Color(0xFFF0F0F8),
        ),
        textTheme: GoogleFonts.syneTextTheme(ThemeData.dark().textTheme),
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F4F9),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF3D7A00),
          surface: Color(0xFFFFFFFF),
          onPrimary: Colors.white,
          onSurface: Color(0xFF0A0A18),
        ),
        textTheme: GoogleFonts.syneTextTheme(ThemeData.light().textTheme),
      ),
      home: HomeScreen(
        isDark: _dark,
        onToggle: () => setState(() => _dark = !_dark),
      ),
    );
  }
}
