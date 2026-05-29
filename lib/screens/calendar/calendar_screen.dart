import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added for month/year formatting
import '../../models/event_model.dart';
import '../../cards/event_card.dart';
import '../../cards/add_event_sheet.dart';
import '../../services/firestore_service.dart';

class CalendarScreen extends StatefulWidget {
  final String houseId;
  final String currentUserId;

  const CalendarScreen({
    Key? key,
    required this.houseId,
    required this.currentUserId,
  }) : super(key: key);

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

  // Helper method to clear hours/minutes comparisons
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Generates complete listing of days inside targeting monthly window
  List<DateTime> _getDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    return List.generate(
      last.day,
      (index) => DateTime(month.year, month.month, index + 1),
    );
  }

  // ── Month Navigation Controls ──────────────────────────────────────────────
  void _goToPreviousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    });
  }

  Future<void> _selectMonthYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year, // Starts in year view
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE040FB),
              onPrimary: Colors.white,
              surface: Color(0xFF1D1D35),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF14142A),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // Set focused day to the 1st of the newly picked month
        _focusedDay = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _getDaysInMonth(_focusedDay);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: StreamBuilder<List<EventModel>>(
          stream: _eventsStream,
          builder: (context, snapshot) {
            
            // Catch Firestore Indexes Errors
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    "Database Error:\n${snapshot.error}",
                    style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFE040FB)));
            }

            final allEvents = snapshot.data ?? [];

            // Filter specific elements belonging to chosen date bubble
            final activeSelectedEvents = allEvents.where((e) => _isSameDay(e.date, _selectedDay)).toList();

            return Column(
              children: [
                _buildHeader(),
                
                // Add the Month Selector right below the main header
                _buildMonthSelector(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                  child: _buildCalendarGrid(daysInMonth, allEvents),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A1A2E),
                        const Color(0xFF14142A).withOpacity(0.95),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activeSelectedEvents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                            child: Text(
                              "No events scheduled for this day.",
                              style: TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                          ),
                        )
                      else
                        ...activeSelectedEvents.map((event) => EventCard(event: event)).toList(),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => AddEventSheet.show(context, widget.houseId, widget.currentUserId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D1D35),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_circle, color: Color(0xFFE040FB)),
                              SizedBox(width: 12),
                              Text(
                                "New event",
                                style: TextStyle(
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Icon(Icons.pets, color: Color(0xFFE040FB)),
          ),
          const Text(
            "MAD HOUSE",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF6B6892)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── Month Selector UI ────────────────────────────────────────────────────
  Widget _buildMonthSelector() {
    // Formats the month into "MAY 2026"
    final String monthName = DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase();

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1D35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                monthName,
                style: const TextStyle(
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

  Widget _buildCalendarGrid(List<DateTime> days, List<EventModel> events) {
    final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    
    // Calculate leading padding offset blocks matching specific day-of-week indexes
    int paddingCount = days.first.weekday - 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays
              .map((d) => Text(
                    d,
                    style: const TextStyle(
                      color: Color(0xFF6B6892),
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
            final hasEvents = events.any((e) => _isSameDay(e.date, dayDate));

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = dayDate;
                });
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected 
                      ? const Color(0xFFE040FB) 
                      : (hasEvents ? const Color(0xFF3E3054) : Colors.transparent),
                  border: hasEvents && !isSelected
                      ? Border.all(color: const Color(0xFFE040FB).withOpacity(0.5), width: 1)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  dayDate.day.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : (hasEvents ? const Color(0xFFE040FB) : Colors.white70),
                    fontSize: 15,
                    fontWeight: isSelected || hasEvents ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}