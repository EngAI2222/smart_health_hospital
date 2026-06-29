import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------- Colors ----------
const Color kTeal = Color(0xFF008080);
const Color kNavy = Color(0xFF0A192F);
const Color kWhite = Color(0xFFFFFFFF);
const Color kBgGrey = Color(0xFFF8F9FA);
const Color kCriticalRed = Color(0xFFE74C3C);
const Color kWarningOrange = Color(0xFFF39C12);
const Color kStableGreen = Color(0xFF27AE60);

class HospitalDashboard extends StatefulWidget {
  const HospitalDashboard({super.key});

  @override
  State<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends State<HospitalDashboard> {
  late final SupabaseClient _supabase;
  late final StreamSubscription<List<Map<String, dynamic>>> _ticketsStream;
  final List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _subscribeToTickets();
  }

  void _subscribeToTickets() {
    final stream = _supabase
        .from('tickets')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    _ticketsStream = stream.listen(
      (data) {
        if (!mounted) return;
        setState(() {
      _tickets.clear();
      _tickets.addAll(data);
          _loading = false;
          _error = null;
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'تعذر الاتصال بقاعدة البيانات: $err';
        });
      },
    );
  }

  @override
  void dispose() {
    _ticketsStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBgGrey,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  // ─────────────────────── AppBar ───────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: kNavy,
        statusBarIconBrightness: Brightness.light,
      ),
      backgroundColor: kNavy,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FontAwesomeIcons.hospital, color: kWhite, size: 22),
          const SizedBox(width: 10),
          Text(
            'منظومة المساعد الصحي الذكي',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kWhite,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: kTeal.withOpacity(0.15),
            borderRadius: BorderRadius.circular(30),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kWhite),
            tooltip: 'تحديث',
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _loading = true);
              _ticketsStream.cancel();
              _subscribeToTickets();
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────── Body ───────────────────────
  Widget _buildBody() {
    if (_error != null && _tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FontAwesomeIcons.wifi, size: 48, color: kNavy),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  color: kNavy.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _subscribeToTickets,
                icon: const Icon(Icons.refresh),
                label: Text('إعادة المحاولة',
                    style: GoogleFonts.tajawal(fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  foregroundColor: kWhite,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: kTeal,
      onRefresh: () async {
        setState(() => _loading = true);
        _ticketsStream.cancel();
        _subscribeToTickets();
        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        slivers: [
          // ── Analytics Cards ──
          SliverToBoxAdapter(child: _buildAnalyticsRow()),

          // ── Section Header ──
          SliverToBoxAdapter(child: _buildSectionHeader()),

          // ── Ticket List ──
          if (_loading && _tickets.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: kTeal),
              ),
            )
          else if (_tickets.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildTicketCard(_tickets[i]),
                  childCount: _tickets.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────── Analytics Cards ───────────────────
  Widget _buildAnalyticsRow() {
    final criticalCount =
        _tickets.where((t) => (t['urgency_level'] ?? '').toString().toLowerCase() == 'critical' || (t['urgency_level'] ?? '').toString().toLowerCase() == 'high').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: SizedBox(
        height: 140,
        child: Row(
          children: [
            Expanded(child: _buildAnalyticCard(
              icon: FontAwesomeIcons.heartPulse,
              label: 'الحالات الحرجة',
              value: '$criticalCount',
              color: kCriticalRed,
              glow: true,
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildAnalyticCard(
              icon: FontAwesomeIcons.stethoscope,
              label: 'القسم الأكثر ضغطاً',
              value: 'أمراض الكلى',
              color: kWarningOrange,
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildAnalyticCard(
              icon: FontAwesomeIcons.robot,
              label: 'كفاءة الروبوت',
              value: '98%',
              color: kStableGreen,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool glow = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (glow)
            _GlowingIcon(icon: icon, color: color)
          else
            Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: kNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: kNavy.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── Section Header ───────────────────
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Icon(FontAwesomeIcons.ticket, size: 16, color: kNavy),
          const SizedBox(width: 8),
          Text(
            'التذاكر الطبية الحية',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kNavy,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_tickets.length} تذكرة',
              style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── Empty State ───────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FontAwesomeIcons.inbox, size: 56, color: kNavy.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'لا توجد تذاكر حالياً',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kNavy.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'بإنتظار وصول الحالات الجديدة عبر المنصة...',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                color: kNavy.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── Ticket Card ───────────────────
  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final urgency = (ticket['urgency_level'] ?? 'normal').toString().toLowerCase();
    final isCritical = urgency == 'critical' || urgency == 'high';
    final isWarning = urgency == 'warning' || urgency == 'medium';

    Color borderColor;
    String badgeText;
    Color badgeColor;
    IconData badgeIcon;

    if (isCritical) {
      borderColor = kCriticalRed;
      badgeText = 'حالة حرجة جداً';
      badgeColor = kCriticalRed;
      badgeIcon = FontAwesomeIcons.triangleExclamation;
    } else if (isWarning) {
      borderColor = kWarningOrange;
      badgeText = 'متوسط الخطورة';
      badgeColor = kWarningOrange;
      badgeIcon = FontAwesomeIcons.circleExclamation;
    } else {
      borderColor = kStableGreen;
      badgeText = 'مستقر / عادي';
      badgeColor = kStableGreen;
      badgeIcon = FontAwesomeIcons.circleCheck;
    }

    final name = ticket['patient_name'] ?? ticket['name'] ?? 'غير معروف';
    final symptoms = ticket['symptoms'] ?? '—';
    final createdAt = ticket['created_at'] ?? '';
    final status = ticket['status'] ?? 'جديد';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _openPatientSheet(ticket),
        child: Container(
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
            boxShadow: [
              if (isCritical)
                BoxShadow(
                  color: kCriticalRed.withOpacity(0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: badge + status ──
              Row(
                children: [
                  _buildBadge(badgeText, badgeColor, badgeIcon),
                  const Spacer(),
                  _statusChip(status.toString()),
                ],
              ),
              const SizedBox(height: 10),
              // ── Patient Name ──
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: kNavy.withOpacity(0.08),
                    child: Text(
                      name.toString()[0].toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: kNavy),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name.toString(),
                      style: GoogleFonts.tajawal(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kNavy,
                      ),
                    ),
                  ),
                  if (isCritical)
                    const _PulseDot(),
                ],
              ),
              const SizedBox(height: 8),
              // ── Symptoms preview ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(FontAwesomeIcons.stethoscope,
                      size: 12, color: kNavy.withOpacity(0.4)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      symptoms.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        color: kNavy.withOpacity(0.55),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // ── Time ──
              if (createdAt.isNotEmpty)
                Row(
                  children: [
                    Icon(FontAwesomeIcons.clock,
                        size: 10, color: kNavy.withOpacity(0.3)),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(createdAt.toString()),
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: kNavy.withOpacity(0.35),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'تم توجيه الروبوت للمستقبل':
        chipColor = Colors.blue;
        break;
      case 'تواصل طبي مباشر':
        chipColor = Colors.purple;
        break;
      default:
        chipColor = kNavy.withOpacity(0.3);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.tajawal(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  // ─────────────────── Bottom Sheet ───────────────────
  void _openPatientSheet(Map<String, dynamic> ticket) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatientBottomSheet(
        ticket: ticket,
        onRobotAssign: () => _updateTicketStatus(
          ticket['id'],
          'تم توجيه الروبوت للمستقبل',
        ),
        onStartTelemedicine: () => _updateTicketStatus(
          ticket['id'],
          'تواصل طبي مباشر',
        ),
      ),
    );
  }

  Future<void> _updateTicketStatus(dynamic ticketId, String newStatus) async {
    try {
      await _supabase
          .from('tickets')
          .update({'status': newStatus}).eq('id', ticketId);

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: kWhite, size: 20),
              const SizedBox(width: 12),
              Text(
                newStatus == 'تم توجيه الروبوت للمستقبل'
                    ? '✅ تم توجيه الروبوت بنجاح'
                    : '✅ تم فتح التواصل الطبي المباشر',
                style: GoogleFonts.tajawal(fontSize: 14),
              ),
            ],
          ),
          backgroundColor: kTeal,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ فشل التحديث: $e'),
          backgroundColor: kCriticalRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  Glowing Icon Widget
// ═══════════════════════════════════════════════════════════
class _GlowingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _GlowingIcon({required this.icon, required this.color});

  @override
  State<_GlowingIcon> createState() => _GlowingIconState();
}

class _GlowingIconState extends State<_GlowingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Icon(widget.icon, color: widget.color.withOpacity(_opacity.value), size: 26),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Pulsing Dot Widget (for critical cases)
// ═══════════════════════════════════════════════════════════
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.6, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Container(
        width: 10 * _scale.value,
        height: 10 * _scale.value,
        decoration: const BoxDecoration(
          color: kCriticalRed,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Patient Detail Bottom Sheet
// ═══════════════════════════════════════════════════════════
class _PatientBottomSheet extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onRobotAssign;
  final VoidCallback onStartTelemedicine;

  const _PatientBottomSheet({
    required this.ticket,
    required this.onRobotAssign,
    required this.onStartTelemedicine,
  });

  @override
  Widget build(BuildContext context) {
    final name = ticket['patient_name'] ?? ticket['name'] ?? 'غير معروف';
    final symptoms = ticket['symptoms'] ?? 'غير متوفرة';
    final department = ticket['predicted_department'] ?? 'غير محدد';
    final summary = ticket['summary'] ?? 'لا يوجد ملخص طبي';
    final vitals = ticket['vitals'] ?? <String, dynamic>{};
    final urgency = (ticket['urgency_level'] ?? 'normal').toString().toLowerCase();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // ── Handle ──
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: kNavy.withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              children: [
                // ── Patient Header ──
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: kNavy.withOpacity(0.06),
                      child: Text(
                        name.toString()[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: kNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.toString(),
                            style: GoogleFonts.tajawal(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _urgencyLabel(urgency),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Vitals Row ──
                if (vitals is Map && vitals.isNotEmpty) ...[
                  _sectionTitle('المؤشرات الحيوية'),
                  const SizedBox(height: 8),
                  _buildVitalsRow(vitals),
                  const SizedBox(height: 20),
                ],

                // ── Symptoms ──
                _sectionTitle('الأعراض'),
                const SizedBox(height: 8),
                _infoCard(symptoms.toString()),

                const SizedBox(height: 16),
                // ── Predicted Department ──
                _sectionTitle('القسم المتوقع'),
                const SizedBox(height: 8),
                _infoCard(department.toString()),

                const SizedBox(height: 16),
                // ── Summary ──
                _sectionTitle('الملخص الذكي'),
                const SizedBox(height: 8),
                _infoCard(summary.toString()),

                const SizedBox(height: 28),

                // ── Action Buttons ──
                _buildActionButton(
                  icon: FontAwesomeIcons.robot,
                  label: 'توجيه الروبوت ميدانياً',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    onRobotAssign();
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: FontAwesomeIcons.video,
                  label: 'فتح تواصل طبي مباشر',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    onStartTelemedicine();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.tajawal(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: kNavy.withOpacity(0.5),
      ),
    );
  }

  Widget _infoCard(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBgGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        content,
        style: GoogleFonts.tajawal(
          fontSize: 14,
          color: kNavy,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildVitalsRow(Map vitals) {
    final items = <Widget>[];
    vitals.forEach((key, value) {
      items.add(Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: kBgGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTeal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                key.toString(),
                style: GoogleFonts.tajawal(
                  fontSize: 10,
                  color: kNavy.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ));
      items.add(const SizedBox(width: 8));
    });
    return Row(children: items);
  }

  Widget _urgencyLabel(String urgency) {
    Color c;
    String t;
    if (urgency == 'critical' || urgency == 'high') {
      c = kCriticalRed;
      t = 'حرجة';
    } else if (urgency == 'warning' || urgency == 'medium') {
      c = kWarningOrange;
      t = 'متوسطة';
    } else {
      c = kStableGreen;
      t = 'عادية';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'حالة $t',
        style: GoogleFonts.tajawal(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: kWhite,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          shadowColor: color.withOpacity(0.3),
        ),
      ),
    );
  }
}
