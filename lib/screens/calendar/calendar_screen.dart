import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../cards/add_event_sheet.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shared_app_bar.dart';
import '../../cards/event_card.dart';

class CalendarScreen extends StatefulWidget {
  final String houseId;
  final String currentUserId;
  final String houseName;
  final int avatarIndex;

  const CalendarScreen({
    super.key,
    required this.houseId,
    required this.currentUserId,
    this.houseName = '',
    this.avatarIndex = 0,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late Stream<List<EventModel>> _eventsStream;

  // ── colours ────────────────────────────────────────────────────────────────
  static const _pink    = Color(0xFFB721A9);
  static const _bg      = Color(0xFF000000);
  static const _dimText = Color(0xFF555577);

  @override
  void initState() {
    super.initState();
    _eventsStream = _firestoreService.eventsStream(widget.houseId);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String get _weekRangeLabel {
    final now    = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return '(${fmt(monday)}-${fmt(sunday)})';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> _getDaysInMonth(DateTime month) {
    final last = DateTime(month.year, month.month + 1, 0);
    return List.generate(last.day,
        (i) => DateTime(month.year, month.month, i + 1));
  }

  /// Nearest → furthest for events that haven't happened yet,
  /// then done events at the bottom (most recently done first).
   List<EventModel> _sortEventsForList(List<EventModel> events) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // FIXED: Nearest -> Furthest for upcoming
    final upcoming = events
        .where((e) =>
            !DateTime(e.date.year, e.date.month, e.date.day).isBefore(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // FIXED: Done events at the bottom (most recently done first)
    final done = events
        .where((e) =>
            DateTime(e.date.year, e.date.month, e.date.day).isBefore(today))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return [...upcoming, ...done];
  }


  void _prevMonth() => setState(() {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      });

  void _nextMonth() => setState(() {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
      });

  Future<void> _pickMonthYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _pink,
            onPrimary: Colors.white,
            surface: Color(0xFF1D1D35),
            onSurface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF0D0D1A)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _focusedDay = DateTime(picked.year, picked.month, 1));
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_focusedDay);

    return Scaffold(
      backgroundColor: _bg,
      body: StreamBuilder<List<EventModel>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent)));
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _pink));
          }

          final allEvents = snapshot.data ?? [];
          final selectedEvents = allEvents
              .where((e) => _isSameDay(e.date, _selectedDay))
              .toList();
          final sortedAllEvents = _sortEventsForList(allEvents);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── app bar ────────────────────────────────────────────
              HouseAppBar(
                houseId: widget.houseId,
                currentUserId: widget.currentUserId,
                weekRangeLabel: _weekRangeLabel,
              ),

              // ── month selector ─────────────────────────────────────
              SliverToBoxAdapter(child: _buildMonthHeader()),

              // ── weekday labels ─────────────────────────────────────
              SliverToBoxAdapter(child: _buildWeekdayRow()),

              // ── day grid ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDayGrid(days, allEvents),
                ),
              ),

              // ── divider ────────────────────────────────────────────
              const SliverToBoxAdapter(
                child: Divider(
                    color: Color(0xFF1A1A2E), thickness: 1, height: 24),
              ),

              // ── event panel: bounded + internally scrollable ───────
              SliverFillRemaining(
                hasScrollBody: true,
                child: _buildEventPanel(selectedEvents, sortedAllEvents),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── month header ───────────────────────────────────────────────────────────

  Widget _buildMonthHeader() {
    final label = DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 28),
            onPressed: _prevMonth,
          ),
          GestureDetector(
            onTap: _pickMonthYear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF111122),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right,
                color: Colors.white70, size: 28),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  // ── weekday row ────────────────────────────────────────────────────────────

  Widget _buildWeekdayRow() {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map((d) => SizedBox(
                  width: 36,
                  child: Text(d,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: _dimText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      )),
                ))
            .toList(),
      ),
    );
  }

  // ── day grid ───────────────────────────────────────────────────────────────

  Widget _buildDayGrid(List<DateTime> days, List<EventModel> events) {
    final paddingCount = days.first.weekday - 1;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length + paddingCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        mainAxisSpacing: 4,
        crossAxisSpacing: 0,
      ),
      itemBuilder: (context, index) {
        if (index < paddingCount) return const SizedBox.shrink();

        final day = days[index - paddingCount];
        final isSelected = _isSameDay(day, _selectedDay);
        final hasEvents = events.any((e) => _isSameDay(e.date, day));
        final isPast = day.isBefore(today);

        // FIXED Logic: 
        // 1. Selection = Pink Circle with NO fill (Border)
        // 2. Event = Pink Circle WITH fill
        return GestureDetector(
          onTap: () => setState(() => _selectedDay = day),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Filled if upcoming event
              color: (hasEvents && !isPast) ? _pink : Colors.transparent,
              // Pink ring if selected
              border: isSelected 
                  ? Border.all(color: _pink, width: 2) 
                  : (isPast && hasEvents ? Border.all(color: Colors.white10) : null),
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: GoogleFonts.poppins(
                color: isPast ? Colors.white24 : Colors.white,
                fontSize: 14,
                fontWeight: (hasEvents || isSelected) ? FontWeight.bold : FontWeight.normal,
                decoration: (isPast && hasEvents) ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── event panel ────────────────────────────────────────────────────────────

  Widget _buildEventPanel(
      List<EventModel> selectedEvents, List<EventModel> upcomingEvents) {
    final selectedLabel = DateFormat('d MMM yyyy').format(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── fixed top section (button, selected-day events) ─────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => AddEventSheet.show(
                  context,
                  widget.houseId,
                  widget.currentUserId,
                  initialDate: _selectedDay,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: const Color(0x33252B4C),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: _pink),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'New event',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                selectedEvents.isEmpty
                    ? 'No events on $selectedLabel'
                    : 'Events on $selectedLabel',
                style: GoogleFonts.poppins(color: _dimText, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (selectedEvents.isNotEmpty)
                ...selectedEvents.map((e) => EventCard(
                      event: e,
                      houseId: widget.houseId,
                      currentUserId: widget.currentUserId,
                    )),
              const SizedBox(height: 16),
              Text(
                'All events',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),

        // ── bounded, independently scrollable list ───────────────────
        Expanded(
          child: upcomingEvents.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('No events yet',
                      style:
                          GoogleFonts.poppins(color: _dimText, fontSize: 14)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: upcomingEvents.length,
                  itemBuilder: (context, i) => EventCard(
                    event: upcomingEvents[i],
                    houseId: widget.houseId,
                    currentUserId: widget.currentUserId,
                  ),
                ),
        ),
      ],
    );
  }
}