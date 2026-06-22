import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../cards/add_event_sheet.dart';
import '../../services/firestore_service.dart';
import '../home/home_widgets.dart';
import 'calendar_widgets.dart';
import '../settings/settings_screen.dart';

class CalendarScreen extends StatefulWidget {
  final String houseId;
  final String currentUserId;

  const CalendarScreen({
    super.key,
    required this.houseId,
    required this.currentUserId,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late Stream<List<EventModel>> _eventsStream;

  String _houseName = '';
  int _myAvatarIndex = 0;
  List<Map<String, dynamic>> _members = [];
  bool _contextReady = false;

  @override
  void initState() {
    super.initState();
    _eventsStream = _firestoreService.eventsStream(widget.houseId);
    _loadContext();
  }

  Future<void> _loadContext() async {
    final house = await _firestoreService.getHouseData(widget.houseId);
    final members =
        await _firestoreService.getHouseMemberDetails(widget.houseId);
    final me = members.firstWhere(
      (m) => m['userId'] == widget.currentUserId,
      orElse: () => {'avatarIndex': 0},
    );
    if (mounted) {
      setState(() {
        _houseName = (house?['name'] as String?) ?? 'Our House';
        _members = members;
        _myAvatarIndex = me['avatarIndex'] as int? ?? 0;
        _contextReady = true;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

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

  Map<String, dynamic> _memberFor(String uid) => _members.firstWhere(
        (m) => m['userId'] == uid,
        orElse: () => {'avatarIndex': 0, 'name': 'Unknown'},
      );

  List<EventModel> _monthEvents(List<EventModel> all) {
    return all
        .where((e) => _isSameMonth(e.date, _focusedDay))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    if (!_contextReady) {
      return const Scaffold(
        backgroundColor: HomeTokens.screenBg,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE040FB)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: HomeTokens.screenBg,
      body: SafeArea(
        child: StreamBuilder<List<EventModel>>(
          stream: _eventsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Database Error:\n${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE040FB)),
              );
            }

            final allEvents = snapshot.data ?? [];
            final monthEvents = _monthEvents(allEvents);

            return Column(
              children: [
                HomeHeader(
                  houseName: _houseName,
                  avatarIndex: _myAvatarIndex,
                  onSettingsTap: () => SettingsScreen.open(
                    context,
                    userId: widget.currentUserId,
                    houseId: widget.houseId,
                  ),
                ),
                const SizedBox(height: 8),
                CalendarMonthGrid(
                  focusedMonth: _focusedDay,
                  selectedDay: _selectedDay,
                  events: allEvents,
                  onDaySelected: (day) => setState(() => _selectedDay = day),
                  onPreviousMonth: _goToPreviousMonth,
                  onNextMonth: _goToNextMonth,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: CalendarEventsPanel(
                    children: [
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CalendarTokens.horizontalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (monthEvents.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No events this month',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...monthEvents.map((event) {
                                final member =
                                    _memberFor(event.createdBy);
                                return CalendarEventCard(
                                  event: event,
                                  creatorAvatarIndex:
                                      member['avatarIndex'] as int? ?? 0,
                                );
                              }),
                            CalendarNewEventButton(
                              onTap: () => AddEventSheet.show(
                                context,
                                widget.houseId,
                                widget.currentUserId,
                              ),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
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
}
