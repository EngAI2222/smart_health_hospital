import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://xwpjwoazzccoxtpdjfkj.supabase.co',
      anonKey: 'sb_publishable_Ei40yu86mRJevAzcjeEpXA_4ldcUbrI',
    );
  }
}
