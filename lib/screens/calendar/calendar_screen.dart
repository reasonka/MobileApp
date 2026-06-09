import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../cards/event_card.dart';
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
            primary: Color(0xFFE040FB),
            onPrimary: Colors.white,
            surface: Color(0xFF1D1D35),
            onSurface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF14142A),
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
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: StreamBuilder<List<EventModel>>(
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
                child: CircularProgressIndicator(
                    color: Color(0xFFE040FB)),
              );
            }

            final allEvents = snapshot.data ?? [];
            final selectedEvents = allEvents
                .where((e) => _isSameDay(e.date, _selectedDay))
                .toList();

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
                  child: _buildEventPanel(selectedEvents),
                ),
              ],
            );
          },
        ),
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
                color: const Color(0xFF1D1D35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withOpacity(0.05)),
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
                      color: const Color(0xFF6B6892),
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
            final hasEvents =
                events.any((e) => _isSameDay(e.date, dayDate));
            final isToday = _isSameDay(dayDate, DateTime.now());

            return GestureDetector(
              onTap: () => setState(() => _selectedDay = dayDate),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFFE040FB)
                      : hasEvents
                          ? const Color(0xFF3E3054)
                          : Colors.transparent,
                  border: isToday && !isSelected
                      ? Border.all(
                          color: const Color(0xFFE040FB).withOpacity(0.6),
                          width: 1.5)
                      : hasEvents && !isSelected
                          ? Border.all(
                              color: const Color(0xFFE040FB)
                                  .withOpacity(0.5),
                              width: 1)
                          : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  dayDate.day.toString(),
                  style: GoogleFonts.poppins(
                    color: isSelected
                        ? Colors.white
                        : hasEvents
                            ? const Color(0xFFE040FB)
                            : isToday
                                ? const Color(0xFFE040FB)
                                : Colors.white70,
                    fontSize: 15,
                    fontWeight: isSelected || hasEvents || isToday
                        ? FontWeight.bold
                        : FontWeight.w500,
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

  Widget _buildEventPanel(List<EventModel> selectedEvents) {
    final formattedDate =
        DateFormat('EEEE, d MMMM').format(_selectedDay);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date label
          Text(
            formattedDate,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            selectedEvents.isEmpty
                ? 'No events scheduled'
                : '${selectedEvents.length} event${selectedEvents.length == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B6892),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Event list
          if (selectedEvents.isNotEmpty)
            ...selectedEvents.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EventCard(
                  event: event,
                  houseId: widget.houseId,
                  currentUserId: widget.currentUserId,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // New event button
          GestureDetector(
            onTap: () => AddEventSheet.show(
              context,
              widget.houseId,
              widget.currentUserId,
              initialDate: _selectedDay,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1D35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_circle,
                      color: Color(0xFFE040FB)),
                  const SizedBox(width: 12),
                  Text(
                    'New event',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}