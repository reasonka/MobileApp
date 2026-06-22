import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../cards/add_event_sheet.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shared_app_bar.dart';

class CalendarScreen extends StatefulWidget {
  final String houseId;
  final String currentUserId;
  final String houseName;
  final int avatarIndex;

  const CalendarScreen({
    super.key,
    required this.houseId,
    required this.currentUserId,
    required this.houseName,
    required this.avatarIndex,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  late Stream<List<EventModel>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _eventsStream = _firestoreService.eventsStream(widget.houseId);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _weekRangeLabel {
    final now = DateTime.now();
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
    return List.generate(
      last.day,
      (i) => DateTime(month.year, month.month, i + 1),
    );
  }

  // ── Month navigation ───────────────────────────────────────────────────────

  void _goToPreviousMonth() => setState(() {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      });

  void _goToNextMonth() => setState(() {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
      });

  Future<void> _selectMonthYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFB721A9),
            onPrimary: Colors.white,
            surface: Color(0xFF1D1D35),
            onSurface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF000000),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _focusedDay = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _getDaysInMonth(_focusedDay);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: StreamBuilder<List<EventModel>>(   // ← directly here, no SafeArea
  stream: _eventsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Database Error:\n${snapshot.error}',
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFB721A9)),
              );
            }

            final allEvents = snapshot.data ?? [];
            final selectedEvents = allEvents
                .where((e) => _isSameDay(e.date, _selectedDay))
                .toList();

            // All events sorted by date (past ones will show with strikethrough)
            final upcomingEvents = allEvents.toList()
              ..sort((a, b) => a.date.compareTo(b.date));

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Shared app bar ───────────────────────────────────────
                HouseAppBar(
                  houseId: widget.houseId,
                  currentUserId: widget.currentUserId,
                  weekRangeLabel: _weekRangeLabel,
                ),

                // ── Month selector ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildMonthSelector(),
                ),

                // ── Calendar grid ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 4.0),
                    child: _buildCalendarGrid(daysInMonth, allEvents),
                  ),
                ),

                // ── Event panel ──────────────────────────────────────────
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEventPanel(selectedEvents, upcomingEvents),
                ),
              ],
            );
          },
        ),
      );
  }

  // ── Month selector ─────────────────────────────────────────────────────────

  Widget _buildMonthSelector() {
    final monthName =
        DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white70),
            onPressed: _goToPreviousMonth,
          ),
          GestureDetector(
            onTap: _selectMonthYear,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Text(
                monthName,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white70),
            onPressed: _goToNextMonth,
          ),
        ],
      ),
    );
  }

  // ── Calendar grid ──────────────────────────────────────────────────────────

  Widget _buildCalendarGrid(
      List<DateTime> days, List<EventModel> events) {
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final paddingCount = days.first.weekday - 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays
              .map((d) => Text(
                    d,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF555577),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length + paddingCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            if (index < paddingCount) return const SizedBox.shrink();

            final dayDate = days[index - paddingCount];
            final isSelected = _isSameDay(dayDate, _selectedDay);
            final isToday = _isSameDay(dayDate, DateTime.now());
            final hasEvents =
                events.any((e) => _isSameDay(e.date, dayDate));
            // A day is "past" if it has events and is strictly before today
            final isPast = hasEvents &&
                dayDate.isBefore(DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day));

            return GestureDetector(
              onTap: () => setState(() => _selectedDay = dayDate),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Past event days: no fill, just dimmed
                  // Future event days: magenta tinted fill
                  color: isSelected
                      ? const Color(0xFFB721A9)
                      : (hasEvents && !isPast)
                          ? const Color(0xFF2A0028)
                          : Colors.transparent,
                  border: isToday && !isSelected
                      ? Border.all(
                          color: const Color(0xFFB721A9).withOpacity(0.6),
                          width: 1.5)
                      : (hasEvents && !isSelected && !isPast)
                          ? Border.all(
                              color: const Color(0xFFB721A9).withOpacity(0.5),
                              width: 1)
                          : isPast && !isSelected
                              ? Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                  width: 1)
                              : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  dayDate.day.toString(),
                  style: GoogleFonts.poppins(
                    // Past event days: dimmed grey; future event days: magenta
                    color: isSelected
                        ? Colors.white
                        : isPast
                            ? Colors.white24
                            : hasEvents
                                ? const Color(0xFFB721A9)
                                : isToday
                                    ? const Color(0xFFB721A9)
                                    : Colors.white70,
                    fontSize: 15,
                    fontWeight: isSelected || (hasEvents && !isPast) || isToday
                        ? FontWeight.bold
                        : FontWeight.w500,
                    // Strikethrough on the day number for past events
                    decoration: isPast && !isSelected
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: Colors.white24,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Event panel ────────────────────────────────────────────────────────────

  Widget _buildEventPanel(
      List<EventModel> selectedEvents, List<EventModel> upcomingEvents) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(21, 28, 21, 24),
      // No card background — matches the flat black style of the first code
      color: const Color(0xFF000000),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── New event bubble (pill style from first code) ─────────────
          GestureDetector(
            onTap: () => AddEventSheet.show(
              context,
              widget.houseId,
              widget.currentUserId,
              initialDate: _selectedDay,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color(0x33252B4C),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 31,
                    height: 31,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFB721A9),
                    ),
                    child: const Icon(Icons.add,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 13),
                  Text(
                    'New event',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Upcoming event rows (flat list style from first code) ──────
          if (upcomingEvents.isEmpty)
            Text(
              'No upcoming events',
              style: GoogleFonts.poppins(
                color: const Color(0xFF555577),
                fontSize: 15,
              ),
            )
          else
            ...upcomingEvents.take(5).map(
                  (event) => _buildUpcomingEventRow(event),
                ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Single upcoming event row (matches first code's layout) ───────────────

  Widget _buildUpcomingEventRow(EventModel event) {
    final dateLabel =
        '${event.date.day.toString().padLeft(2, '0')}/${event.date.month.toString().padLeft(2, '0')}';

    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final eventDay = DateTime(event.date.year, event.date.month, event.date.day);
    final isPast = eventDay.isBefore(today);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon circle — greyed out for past events
          Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.only(right: 9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPast
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFF2A0028),
              border: Border.all(
                color: isPast
                    ? Colors.white.withOpacity(0.12)
                    : const Color(0xFFB721A9).withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.event,
              color: isPast ? Colors.white24 : const Color(0xFFB721A9),
              size: 22,
            ),
          ),

          // Date + title stack
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: GoogleFonts.poppins(
                  color: isPast ? Colors.white24 : Colors.white54,
                  fontSize: 14,
                  // Strikethrough the date label too
                  decoration: isPast ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                event.title,
                style: GoogleFonts.poppins(
                  // Dimmed + strikethrough for past events
                  color: isPast ? Colors.white24 : Colors.white,
                  fontSize: 18,
                  decoration: isPast ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.white24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}