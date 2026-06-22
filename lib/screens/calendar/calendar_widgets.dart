import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../home/home_widgets.dart';

/// Calendar design tokens from Figma node 88:498.
class CalendarTokens {
  static const horizontalPadding = HomeTokens.horizontalPadding;
  static const eventCardHeight = 71.0;
  static const eventCardRadius = 19.0;
  static const eventsPanelTopRadius = 94.0;

  static const weekdayColor = Color(0xFF6B6892);
  static const selectedDayColor = Color(0xFF7B2DBD);

  static const eventCardGradient = RadialGradient(
    center: Alignment(0.86, 0.62),
    radius: 1.6,
    colors: [
      Color(0x33FFFFFF),
      Color(0x33FFFFFF),
      Color(0x33D0DBE4),
      Color(0x33A2B7C9),
      Color(0x337393AE),
      Color(0x33446F93),
    ],
    stops: [0.0, 0.47, 0.60, 0.73, 0.87, 1.0],
  );

  static const eventsPanelGradient = RadialGradient(
    center: Alignment(0.86, 0.62),
    radius: 1.8,
    colors: [
      Color(0x33AF69F1),
      Color(0x33DA70D7),
      Color(0x33AE67BC),
      Color(0x33815EA0),
      Color(0x33555485),
      Color(0x333E5077),
      Color(0x33284B69),
    ],
    stops: [0.0, 0.47, 0.60, 0.73, 0.87, 0.93, 1.0],
  );
}

/// Month grid matching the Figma calendar layout.
class CalendarMonthGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final List<EventModel> events;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;

  const CalendarMonthGrid({
    super.key,
    required this.focusedMonth,
    required this.selectedDay,
    required this.events,
    required this.onDaySelected,
    this.onPreviousMonth,
    this.onNextMonth,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> _daysInMonth() {
    final last = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    return List.generate(
      last.day,
      (i) => DateTime(focusedMonth.year, focusedMonth.month, i + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth();
    final paddingCount = days.first.weekday - 1;
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CalendarTokens.horizontalPadding,
      ),
      child: Column(
        children: [
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! > 0) {
                onPreviousMonth?.call();
              } else if (details.primaryVelocity! < 0) {
                onNextMonth?.call();
              }
            },
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekdays
                      .map(
                        (d) => Text(
                          d,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: CalendarTokens.weekdayColor,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length + paddingCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    if (index < paddingCount) {
                      return const SizedBox.shrink();
                    }
                    final day = days[index - paddingCount];
                    final isSelected = _isSameDay(day, selectedDay);
                    final hasEvents =
                        events.any((e) => _isSameDay(e.date, day));

                    return GestureDetector(
                      onTap: () => onDaySelected(day),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isSelected)
                            SvgPicture.asset(
                              'assets/images/calendar/selected_day.svg',
                              width: 40,
                              height: 39,
                            ),
                          Text(
                            '${day.day}',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : (hasEvents
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.85)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom events panel with rounded top from Figma.
class CalendarEventsPanel extends StatelessWidget {
  final List<Widget> children;

  const CalendarEventsPanel({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: CalendarTokens.eventsPanelGradient,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(CalendarTokens.eventsPanelTopRadius),
        ),
        boxShadow: const [HomeTokens.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Single event row from Figma.
class CalendarEventCard extends StatelessWidget {
  final EventModel event;
  final int creatorAvatarIndex;

  const CalendarEventCard({
    super.key,
    required this.event,
    required this.creatorAvatarIndex,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('d/MM').format(event.date);

    return Container(
      height: CalendarTokens.eventCardHeight,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: CalendarTokens.eventCardGradient,
        borderRadius:
            BorderRadius.circular(CalendarTokens.eventCardRadius),
        boxShadow: const [HomeTokens.cardShadow],
      ),
      child: Row(
        children: [
          HomeCatAvatar(avatarIndex: creatorAvatarIndex, size: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "New event" pill button from Figma.
class CalendarNewEventButton extends StatelessWidget {
  final VoidCallback onTap;

  const CalendarNewEventButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: HomeTokens.actionButtonBg,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [HomeTokens.cardShadow],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/calendar/plus_sign.svg',
              width: 31,
              height: 31,
            ),
            const SizedBox(width: 12),
            Text(
              'New event',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
