import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../cards/add_event_sheet.dart';
import '../../services/firestore_service.dart';
import '../../cards/event_card.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme.dart';
import '../../services/sound_service.dart';
import '../../services/theme_service.dart';

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

  static const _pink = Color(0xFFB721A9);

  HomiePalette get _p => HomiePalette.current;
  bool get _isLight => ThemeService.instance.isLight;

  @override
  void initState() {
    super.initState();
    _eventsStream = _firestoreService.eventsStream(widget.houseId);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _eventOccursOn(EventModel e, DateTime day) => e.occursOnDay(day);

  List<DateTime> _getDaysInMonth(DateTime month) {
    final last = DateTime(month.year, month.month + 1, 0);
    return List.generate(
        last.day, (i) => DateTime(month.year, month.month, i + 1));
  }

  List<EventModel> _sortEventsForList(List<EventModel> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool isPast(EventModel e) {
      if (e.isBirthday) return false;
      return DateTime(e.date.year, e.date.month, e.date.day).isBefore(today);
    }

    final upcoming = events.where((e) => !isPast(e)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final done = events.where(isPast).toList()
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
      builder: (context, child) {
        final isLight = ThemeService.instance.isLight;
        return Theme(
          data: (isLight ? ThemeData.light() : ThemeData.dark()).copyWith(
            colorScheme: isLight
                ? ColorScheme.light(
                    primary: _pink,
                    onPrimary: Colors.white,
                    surface: HomiePalette.current.cardBg,
                    onSurface: HomiePalette.current.textPrimary,
                  )
                : const ColorScheme.dark(
                    primary: _pink,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1D1D35),
                    onSurface: Colors.white,
                  ),
            dialogTheme: DialogThemeData(
              backgroundColor: HomiePalette.current.dialogBg,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _focusedDay = DateTime(picked.year, picked.month, 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_focusedDay);

    return Scaffold(
      backgroundColor: _p.screenBg,
      body: StreamBuilder<List<EventModel>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent)),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _pink));
          }

          final allEvents = snapshot.data ?? [];
          final selectedEvents =
              allEvents.where((e) => _eventOccursOn(e, _selectedDay)).toList();

          final nonBirthdayEvents =
              allEvents.where((e) => !e.isBirthday).toList();
          final sortedAllEvents = _sortEventsForList(nonBirthdayEvents);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildMonthHeader()),
              SliverToBoxAdapter(child: _buildWeekdayRow()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildDayGrid(days, allEvents),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEventPanel(
                    context, selectedEvents, sortedAllEvents),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthHeader() {
    final label = DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase();
    final chevronColor = _p.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: chevronColor, size: 28),
            onPressed: () {
              SoundService.instance.playPop();
              _prevMonth();
            },
          ),
          GestureDetector(
            onTap: () {
              SoundService.instance.playPop();
              _pickMonthYear();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: _isLight ? _p.cardBg : const Color(0xFF111122),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isLight ? _p.cardBorder : Colors.white.withValues(alpha: 0.08),
                ),
                boxShadow: _isLight ? [_p.cardShadow] : null,
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: _p.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: chevronColor, size: 28),
            onPressed: () {
              SoundService.instance.playPop();
              _nextMonth();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayRow() {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map((d) => SizedBox(
                  width: 36,
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: _p.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDayGrid(List<DateTime> days, List<EventModel> events) {
    final paddingCount = days.first.weekday - 1;
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length + paddingCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.15,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
      ),
      itemBuilder: (context, index) {
        if (index < paddingCount) return const SizedBox.shrink();
        final day = days[index - paddingCount];
        final isSelected = _isSameDay(day, _selectedDay);
        final dayEvents = events.where((e) => _eventOccursOn(e, day));
        final hasEvents = dayEvents.isNotEmpty;
        final hasBirthday = dayEvents.any((e) => e.isBirthday);
        final isPast = day.isBefore(today);
        final hasGlow = hasEvents && !isPast;

        // Glow assets are dark-mode art; on light mode use a soft tint instead.
        final Color dayColor;
        if (hasGlow) {
          dayColor = Colors.white;
        } else if (isPast) {
          dayColor = _p.textMuted.withValues(alpha: 0.45);
        } else {
          dayColor = _p.textPrimary;
        }

        return GestureDetector(
          onTap: () {
            SoundService.instance.playPop();
            setState(() => _selectedDay = day);
          },
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasGlow && _isLight
                  ? (hasBirthday
                      ? const Color(0xFFFFC107).withValues(alpha: 0.35)
                      : _pink.withValues(alpha: 0.28))
                  : Colors.transparent,
              image: hasGlow && !_isLight
                  ? DecorationImage(
                      image: AssetImage(
                        hasBirthday
                            ? 'assets/images/bills/YouOwe.png'
                            : 'assets/images/bills/OweYou.png',
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
              border: isSelected ? Border.all(color: _pink, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: GoogleFonts.poppins(
                color: dayColor,
                fontSize: 18,
                fontWeight:
                    (hasEvents || isSelected) ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventPanel(
    BuildContext context,
    List<EventModel> selectedEvents,
    List<EventModel> allEvents,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: GestureDetector(
            onTap: () {
              SoundService.instance.playPop();
              AddEventSheet.show(
                context,
                widget.houseId,
                widget.currentUserId,
                initialDate: _selectedDay,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: _isLight ? AppColors.pink : const Color(0xFF111122),
                borderRadius: BorderRadius.circular(12),
                border: _isLight
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: _isLight ? [_p.cardShadow] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/calendar/plus_sign.svg',
                    width: 20,
                    height: 20,
                    colorFilter: _isLight
                        ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'NEW EVENT',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          height: screenHeight * 0.40,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _isLight ? _p.cardBg : null,
            borderRadius: BorderRadius.circular(_isLight ? 28 : 0),
            border: _isLight ? Border.all(color: _p.cardBorder) : null,
            boxShadow: _isLight ? [_p.cardShadow] : null,
            image: _isLight
                ? null
                : const DecorationImage(
                    image: AssetImage(
                        'assets/images/calendar/EventMainPanel.png'),
                    fit: BoxFit.fill,
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 25, 25, 40),
            child: Builder(
              builder: (context) {
                final birthdayToday =
                    selectedEvents.where((e) => e.isBirthday).toList();
                final combined = [...birthdayToday, ...allEvents];

                if (combined.isEmpty) {
                  return Center(
                    child: Text(
                      'No events scheduled',
                      style: GoogleFonts.poppins(color: _p.textMuted),
                    ),
                  );
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemCount: combined.length,
                    itemBuilder: (context, i) {
                      return EventCard(
                        event: combined[i],
                        houseId: widget.houseId,
                        currentUserId: widget.currentUserId,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
