import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chore_model.dart';
import '../../models/note_model.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../services/theme_service.dart';
import '../../theme.dart';
import 'home_widgets.dart';
import 'new_chore_sheet.dart';
import 'new_note_sheet.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String houseId;

  const HomeScreen({super.key, required this.userId, required this.houseId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fs = FirestoreService();
  final _scrollCtrl = ScrollController();
  StreamSubscription? _membersSub;

  List<Map<String, dynamic>> _members = []; 
  String _houseName = '';
  String _inviteCode = '';
  bool _initialized = false;

  static const double _fabBottomInset = 123;

  @override
  void initState() {
    super.initState();
    _loadHouseData();
    _listenToMembers();
  }

  @override
void dispose() {
  for (final sub in _userSubs) {
    sub.cancel();
  }
  _membersSub?.cancel();
  _scrollCtrl.dispose();
  super.dispose();
}
final List<StreamSubscription> _userSubs = [];

void _listenToMembers() async {
  
  final members = await _fs.getHouseMemberDetails(widget.houseId);
  if (!mounted) return;
  setState(() => _members = members);

  
  for (final m in members) {
    final uid = m['userId'] as String;
    final sub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (!mounted || !doc.exists) return;
      final data = doc.data()!;
      setState(() {
        final idx = _members.indexWhere((m) => m['userId'] == uid);
        if (idx != -1) {
          _members[idx] = {
            ..._members[idx],
            'name': data['name'] as String? ?? data['userName'] as String? ?? '',
            'avatarIndex': data['avatarIndex'] as int? ?? 0,
          };
        }
      });
    });
    _userSubs.add(sub);
  }
}
  Future<void> _loadHouseData() async {
    final house = await _fs.getHouseData(widget.houseId);
    final members = await _fs.getHouseMemberDetails(widget.houseId);
    if (mounted) {
      setState(() {
        _houseName = (house?['name'] as String?) ?? 'Our House';
        _inviteCode = (house?['inviteCode'] as String?) ?? '';
        _members = members;
        _initialized = true;
      });
    }
  }

  

  String get _weekRangeLabel {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return '(${fmt(monday)}-${fmt(sunday)})';
  }

  

  Map<String, dynamic> get _myMember => _members.firstWhere(
        (m) => m['userId'] == widget.userId,
        orElse: () => {'userId': widget.userId, 'name': '', 'avatarIndex': 0},
      );

  

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: HomeTokens.screenBg,
        body: const Center(child: CircularProgressIndicator(color: AppColors.pink)),
      );
    }

    final fabBottom = MediaQuery.paddingOf(context).bottom + _fabBottomInset;

    return Scaffold(
      backgroundColor: HomeTokens.screenBg,
      body: StreamBuilder<List<ChoreModel>>(
        stream: _fs.choresStream(widget.houseId),
        builder: (context, choreSnap) {
          final chores = choreSnap.data ?? [];
          final myChores = chores
              .where((c) => c.assignedTo == widget.userId)
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          final pendingVotes = chores
              .where((c) =>
                  c.xpStatus == 'pending' &&
                  !c.xpVotes.containsKey(widget.userId))
              .toList();

          final housemates =
              _members.where((m) => m['userId'] != widget.userId).toList();

          return StreamBuilder<List<NoteModel>>(
            stream: _fs.notesStream(widget.houseId),
            builder: (context, noteSnap) {
              final notes = noteSnap.data ?? [];

              return Stack(
                children: [
                  CustomScrollView(
                      controller: _scrollCtrl,
                      slivers: [
                        // Spacer that sits behind the global static top bar
                        // (status bar + kGlobalTopBarHeight).
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.of(context).padding.top +
                                kGlobalTopBarHeight,
                          ),
                        ),
                        if (pendingVotes.isNotEmpty)
                          SliverToBoxAdapter(
                            child: _buildPendingVotesSection(pendingVotes),
                          ),
                        SliverToBoxAdapter(
                          child: _buildUserChoreSection(myChores),
                        ),
                        SliverToBoxAdapter(
                          child: housemates.isNotEmpty
                              ? _buildHousematesSection(housemates, chores)
                              : _buildHousematePlaceholders(),
                        ),
                        SliverToBoxAdapter(
                          child: _buildLeaderboard(chores),
                        ),
                        SliverToBoxAdapter(
                          child: _buildNotesSection(notes),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 180),
                        ),
                      ],
                    ),
                  const HomeBottomScrollFade(),
                  Positioned(
                    left: HomeTokens.horizontalPadding,
                    bottom: fabBottom,
                    child: HomeGlassActionButton(
                      label: 'New chore',
                      width: 171,
                      onTap: () =>
                          _onNewChorePressed(housemates, myChores),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  

  Widget _buildPendingVotesSection(List<ChoreModel> pending) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeTokens.horizontalPadding,
        20,
        HomeTokens.horizontalPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_vote_outlined,
                  color: AppColors.pink, size: 16),
              const SizedBox(width: 6),
              Text(
                'Vote on XP (${pending.length})',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pending.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _buildVoteCard(pending[i]),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildVoteCard(ChoreModel chore) {
    
    final creator = _members.firstWhere(
      (m) => m['userId'] == chore.createdBy,
      orElse: () => {'name': 'Someone'},
    );

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.onPanelDivider,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.pink.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${chore.title}" — ${chore.proposedXP} XP',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onPanel),
          ),
          Text(
            'proposed by ${creator['name']}',
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _SmallButton(
                  label: '✓ Agree',
                  onTap: () => _fs.voteOnChoreXP(
                    choreId: chore.choreId,
                    userId: widget.userId,
                    vote: chore.proposedXP,
                    houseId: widget.houseId,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _SmallButton(
                  label: 'Suggest',
                  outline: true,
                  onTap: () => _showVoteSheet(chore),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showVoteSheet(ChoreModel chore) {
    int tempXP = chore.proposedXP;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suggest XP for "${chore.title}"',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onPanel),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('1',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: tempXP.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      activeColor: AppColors.pink,
                      inactiveColor: AppColors.onPanelDivider,
                      label: '$tempXP XP',
                      onChanged: (v) => setS(() => tempXP = v.round()),
                    ),
                  ),
                  Text('20',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              Center(
                child: Text(
                  '$tempXP XP',
                  style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pink),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    _fs.voteOnChoreXP(
                      choreId: chore.choreId,
                      userId: widget.userId,
                      vote: tempXP,
                      houseId: widget.houseId,
                    );
                    Navigator.pop(ctx);
                  },
                  child: Text('Submit Vote',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.onPanel)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  Widget _buildUserChoreSection(List<ChoreModel> myChores) {
    const avatarSize = 50.0;
    const avatarOverlap = 15.0; 

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeTokens.horizontalPadding,
        12,
        HomeTokens.horizontalPadding,
        0,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: EdgeInsets.only(top: avatarSize - avatarOverlap),
            child: _ChoreCard(
              chores: myChores,
              isOwner: true,
              onToggle: (chore) => _toggleChore(chore),
              onDelete: (chore) => _confirmDeleteChore(chore),
            ),
          ),
          _AvatarCircle(
            avatarIndex: _myMember['avatarIndex'] as int? ?? 0,
            size: avatarSize,
          ),
        ],
      ),
    );
  }

  

  Widget _buildHousematePlaceholders() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeTokens.horizontalPadding,
        12,
        HomeTokens.horizontalPadding,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: HomeHousemateInvitePlaceholder(
                onTap: _showFamilyInviteQr,
              ),
            ),
          ),
          Expanded(
            child: HomeHousemateInvitePlaceholder(
              onTap: _showFamilyInviteQr,
            ),
          ),
        ],
      ),
    );
  }

  void _showFamilyInviteQr() {
    HomeFamilyInviteSheet.show(context, _inviteCode);
  }

  Widget _buildHousematesSection(
    List<Map<String, dynamic>> housemates,
    List<ChoreModel> allChores,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeTokens.horizontalPadding,
        12,
        HomeTokens.horizontalPadding,
        0,
      ),
      child: Row(
        children: housemates.take(3).map((m) {
          final uid = m['userId'] as String;
          final memberChores = allChores
              .where((c) => c.assignedTo == uid)
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _HousemateCard(
                member: m,
                chores: memberChores,
                onTap: () => _showHousemateOverlay(m, memberChores),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showHousemateOverlay(
    Map<String, dynamic> member,
    List<ChoreModel> chores,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.78),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      pageBuilder: (_, _, _) => Center(
        child: Material(
          color: Colors.transparent,
          child: _HousemateOverlay(member: member, chores: chores),
        ),
      ),
    );
  }

  Future<void> _toggleChore(ChoreModel chore) async {
    try {
      await _fs.toggleChore(chore.choreId, !chore.completed);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update chore',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  void _confirmDeleteChore(ChoreModel chore) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HomiePalette.current.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete chore?',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '"${chore.title}" will be removed for everyone in your house.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteChore(chore);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: AppColors.pink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChore(ChoreModel chore) async {
    try {
      SoundService.instance.playDelete();
      await _fs.deleteChore(chore.choreId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete chore',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  void _openNewNote() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => NewNoteSheet(
        userId: widget.userId,
        houseId: widget.houseId,
        authorName: _myMember['name'] as String? ?? '',
      ),
    );
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await _fs.deleteNote(noteId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete note',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    }
  }

  

  void _onNewChorePressed(
    List<Map<String, dynamic>> housemates,
    List<ChoreModel> myChores,
  ) {
    final uncompleted = myChores.where((c) => !c.completed).length;

    if (uncompleted >= 6) {
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🐱', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(
                'Slow down!',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPanel),
              ),
              const SizedBox(height: 8),
              Text(
                'You still have 6 unfinished chores.\nTick some off before piling on more!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Got it!',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, color: AppColors.onPanel)),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => NewChoreSheet(
        userId: widget.userId,
        houseId: widget.houseId,
        members: [_myMember, ...housemates],
        memberCount: _members.length,
        myChores: myChores,
      ),
    );
  }

  Widget _buildLeaderboard(List<ChoreModel> chores) {
    final xpMap = <String, int>{};
    for (final c in chores) {
      if (c.completed) {
        xpMap[c.assignedTo] = (xpMap[c.assignedTo] ?? 0) + c.effectiveXP;
      }
    }

    final ranked = List<Map<String, dynamic>>.from(_members)
      ..sort((a, b) {
        final aXP = xpMap[a['userId'] as String] ?? 0;
        final bXP = xpMap[b['userId'] as String] ?? 0;
        return bXP.compareTo(aXP);
      });

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeTokens.horizontalPadding,
        32,
        HomeTokens.horizontalPadding,
        0,
      ),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width *
                  HomeTokens.podiumWidthFraction,
              child: HomePodium(rankedMembers: ranked.take(3).toList()),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: HomeTokens.leaderboardListGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.heroShadow,
            ),
            child: Column(
              children: ranked.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                final uid = m['userId'] as String;
                final xp = xpMap[uid] ?? 0;
                final isLast = i == ranked.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _AvatarCircle(
                            avatarIndex: m['avatarIndex'] as int? ?? 0,
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            m['name'] as String? ?? '',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onHero),
                          ),
                          const Spacer(),
                          Text(
                            '$xp XP',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onHeroSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                          color: AppColors.onHero.withValues(alpha: 0.2),
                          height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(List<NoteModel> notes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeTokens.horizontalPadding,
        32,
        HomeTokens.horizontalPadding,
        0,
      ),
      child: HomeStickyNotesBanner(
        members: _members,
        notes: notes,
        currentUserId: widget.userId,
        onAddNote: _openNewNote,
        onDeleteNote: _deleteNote,
      ),
    );
  }
}







class _AvatarCircle extends StatelessWidget {
  final int avatarIndex;
  final double size;

  const _AvatarCircle({required this.avatarIndex, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return HomeCatAvatar(
      avatarIndex: avatarIndex,
      size: size,
      borderWidth: size >= 40 ? 2 : 1.5,
    );
  }
}



class _ChoreCard extends StatelessWidget {
  final List<ChoreModel> chores;
  final bool isOwner;
  final void Function(ChoreModel)? onToggle;
  final void Function(ChoreModel)? onDelete;

  const _ChoreCard({
    required this.chores,
    required this.isOwner,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (chores.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(),
        child: Center(
          child: Text(
            isOwner ? 'No chores this week 🎉' : 'No chores assigned',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    
    final rows = <Widget>[];
    for (int i = 0; i < chores.length; i += 2) {
      final left = chores[i];
      final right = i + 1 < chores.length ? chores[i + 1] : null;
      rows.add(_choreRow(left, right, context));
      if (i + 2 < chores.length) {
        rows.add(Divider(color: AppColors.onPanelDivider, height: 1));
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: rows,
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    final secondary = AppColors.secondaryCard(radius: 20);
    if (ThemeService.instance.isLight) return secondary;
    return BoxDecoration(
      gradient: HomeTokens.mainChoreGradient,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [HomeTokens.cardShadow],
    );
  }

  Widget _choreRow(ChoreModel left, ChoreModel? right, BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: _choreItem(left, ctx)),
          if (right != null) Expanded(child: _choreItem(right, ctx)),
          if (right == null) const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _choreItem(ChoreModel chore, BuildContext ctx) {
    final canToggle = isOwner && onToggle != null;
    final canDelete = isOwner && onDelete != null;
    final isPending = chore.xpStatus == 'pending';

    return GestureDetector(
      onLongPress: canDelete
          ? () {
              SoundService.instance.playPop();
              onDelete!(chore);
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    chore.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: chore.completed
                          ? AppColors.onPanelMuted
                          : AppColors.onPanel,
                      decoration: chore.completed
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppColors.onPanelMuted,
                    ),
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.timer_outlined,
                      color: AppColors.pink, size: 12),
                ],
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canToggle ? () => onToggle!(chore) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      chore.completed ? AppColors.pink : AppColors.onPanelMuted,
                  width: 1.5,
                ),
                color: chore.completed
                    ? AppColors.pink.withValues(alpha: 0.25)
                    : Colors.transparent,
              ),
              child: chore.completed
                  ? SvgPicture.asset(
                      'assets/images/home/checkmark.svg',
                      width: 14,
                      height: 14,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}



class _HousemateCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final List<ChoreModel> chores;
  final VoidCallback onTap;

  const _HousemateCard({
    required this.member,
    required this.chores,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = member['name'] as String? ?? '';
    final avatarIdx = member['avatarIndex'] as int? ?? 0;
    final incompleteChores =
        chores.where((c) => !c.completed).toList();
    final first =
        incompleteChores.isNotEmpty ? incompleteChores.first.title : null;
    final extra = (incompleteChores.length - 1).clamp(0, 99);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: ThemeService.instance.isLight
            ? AppColors.secondaryCard(radius: 20)
            : BoxDecoration(
                gradient: HomeTokens.memberPanelGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [HomeTokens.cardShadow],
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarCircle(avatarIndex: avatarIdx, size: 36),
            const SizedBox(height: 8),
            if (first != null) ...[
              Text(
                first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onPanel),
              ),
              if (extra > 0)
                Text(
                  '+$extra more',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
            ] else
              Text(
                name,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}



class _HousemateOverlay extends StatelessWidget {
  final Map<String, dynamic> member;
  final List<ChoreModel> chores;

  const _HousemateOverlay({required this.member, required this.chores});

  @override
  Widget build(BuildContext context) {
    final name = member['name'] as String? ?? '';
    final avatarIdx = member['avatarIndex'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.onPanelDivider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AvatarCircle(avatarIndex: avatarIdx, size: 56),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onPanel),
          ),
          const SizedBox(height: 4),
          Text(
            'This week\'s chores',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          
          _ChoreCard(chores: chores, isOwner: false),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: AppColors.pink),
            ),
          ),
        ],
      ),
    );
  }
}



class _SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool outline;

  const _SmallButton({
    required this.label,
    required this.onTap,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: outline ? Colors.transparent : AppColors.pink.withOpacity(0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: outline ? AppColors.pink : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onPanel,
            ),
          ),
        ),
      ),
    );
  }
}
