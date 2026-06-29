import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart'; // 💡 تم إضافة هذه المكتبة للتحقق من بيئة الـ Web
import 'hospital_dashboard.dart';

// ---------- Supabase Credentials (Connected Successfully) ----------
// تم دمج بيانات مشروعك الحية هنا للربط المباشر مع تطبيق المرضى
const String _supabaseUrl = 'https://xwpjwoazzccoxtpdjfkj.supabase.co';
const String _supabaseAnonKey =
    'sb_publishable_Ei40yu86mRJevAzcjeEpXA_4ldcUbrI';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Supabase بالبيانات الحية مع إضافة خيارات الحماية المتوافقة مع الويب
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // 💡 الحل الجذري: تعيين لون شريط الحالة يتم فقط إذا كان التطبيق يعمل على الجوال (وليس الويب)
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0A192F),
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  runApp(const SmartHealthApp());
}

class SmartHealthApp extends StatelessWidget {
  const SmartHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المساعد الصحي الذكي - لوحة المستشفى',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008080),
          primary: const Color(0xFF008080),
          secondary: const Color(0xFF0A192F),
          surface: const Color(0xFFF8F9FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: GoogleFonts.tajawal().fontFamily,
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A192F),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(
              0xFF008080,
            ), // تأكيد ثيم الفيروزي للأزرار
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: const HospitalDashboard(),
    );
  }
}