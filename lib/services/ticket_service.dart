import 'package:supabase_flutter/supabase_flutter.dart';

class TicketService {
  final SupabaseClient _client = Supabase.instance.client;

  /// جلب جميع التذاكر
  Future<List<Map<String, dynamic>>> getTickets() async {
    final response = await _client
        .from('tickets')
        .select()
        .order('createdAt', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
