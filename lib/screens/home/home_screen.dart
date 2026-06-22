import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chore_model.dart';
import '../../models/note_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shared_app_bar.dart';
import '../../theme.dart';
import 'new_chore_sheet.dart';
import 'new_note_sheet.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String houseId;

  const HomeScreen({super.key, required this.userId, required this.houseId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fs = FirestoreService();

  String _houseName = '';
  List<Map<String, dynamic>> _members = []; // {userId, name, avatarIndex}
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadHouseData();
  }

  Future<void> _loadHouseData() async {
    final house = await _fs.getHouseData(widget.houseId);
    final members = await _fs.getHouseMemberDetails(widget.houseId);
    if (mounted) {
      setState(() {
        _houseName = (house?['name'] as String?) ?? 'Our House';
        _members = members;
        _initialized = true;
      });
    }
  }

  // ── Week range label ──────────────────────────────────────────────────────────

  String get _weekRangeLabel {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return '(${fmt(monday)}-${fmt(sunday)})';
  }

  // ── Current user's member data ────────────────────────────────────────────────

  Map<String, dynamic> get _myMember => _members.firstWhere(
        (m) => m['userId'] == widget.userId,
        orElse: () => {'userId': widget.userId, 'name': '', 'avatarIndex': 0},
      );

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.pink)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: StreamBuilder<List<ChoreModel>>(
        stream: _fs.choresStream(widget.houseId),
        builder: (context, choreSnap) {
          final chores = choreSnap.data ?? [];
          final myChores = chores
              .where((c) => c.assignedTo == widget.userId)
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          // Chores I need to vote on (pending & I haven't voted yet)
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

              return CustomScrollView(
                slivers: [
                  // ── Sticky header ──────────────────────────────────────────
                  HouseAppBar(
  houseId: widget.houseId,
  currentUserId: widget.userId,
  weekRangeLabel: _weekRangeLabel,
),
                  if (pendingVotes.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildPendingVotesSection(pendingVotes),
                    ),
                  SliverToBoxAdapter(
                    child: _buildUserChoreSection(myChores),
                  ),
                  if (housemates.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHousematesSection(housemates, chores),
                    ),
                  SliverToBoxAdapter(
                    child: _buildNewChoreButton(housemates, myChores),
                  ),
                  SliverToBoxAdapter(
                    child: _buildLeaderboard(chores),
                  ),
                  SliverToBoxAdapter(
                    child: _buildNotesSection(notes),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ── Pending XP votes strip ────────────────────────────────────────────────────

  Widget _buildPendingVotesSection(List<ChoreModel> pending) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
    // Find who created it
    final creator = _members.firstWhere(
      (m) => m['userId'] == chore.createdBy,
      orElse: () => {'name': 'Someone'},
    );

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
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
                color: Colors.white),
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
                    color: Colors.white),
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
                      inactiveColor: Colors.white12,
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
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── User chore card ───────────────────────────────────────────────────────────

  Widget _buildUserChoreSection(List<ChoreModel> myChores) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          _AvatarCircle(
            avatarIndex: _myMember['avatarIndex'] as int? ?? 0,
            size: 56,
          ),
          const SizedBox(height: 8),
          _ChoreCard(
            chores: myChores,
            isOwner: true,
            onToggle: (chore) =>
                _fs.toggleChore(chore.choreId, !chore.completed),
          ),
        ],
      ),
    );
  }

  // ── Housemates row ────────────────────────────────────────────────────────────

  Widget _buildHousematesSection(
    List<Map<String, dynamic>> housemates,
    List<ChoreModel> allChores,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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

  // ── New chore button (with 6-chore limit) ────────────────────────────────────

  void _onNewChorePressed(
    List<Map<String, dynamic>> housemates,
    List<ChoreModel> myChores,
  ) {
    final uncompleted = myChores.where((c) => !c.completed).length;

    if (uncompleted >= 6) {
      // Cute limit popup
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🐱', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(
                'Slow down!',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
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
                          fontWeight: FontWeight.w600, color: Colors.white)),
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

  Widget _buildNewChoreButton(
    List<Map<String, dynamic>> housemates,
    List<ChoreModel> myChores,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => _onNewChorePressed(housemates, myChores),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_outline,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'New chore',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────────

  Widget _buildLeaderboard(List<ChoreModel> chores) {
    // Calculate XP from completed chores this week
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
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        children: [
          // Podium
          if (ranked.isNotEmpty) _buildPodium(ranked, xpMap),
          const SizedBox(height: 20),
          // XP list card
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3D1370).withOpacity(0.7),
                  const Color(0xFF7B2DBD).withOpacity(0.5),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
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
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          _AvatarCircle(
                            avatarIndex: m['avatarIndex'] as int? ?? 0,
                            size: 38,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            m['name'] as String? ?? '',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                          const Spacer(),
                          Text(
                            '$xp XP',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pink),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                          color: Colors.white.withOpacity(0.08), height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(
      List<Map<String, dynamic>> ranked, Map<String, int> xpMap) {
    // Show up to 3 on the podium — heights: 2nd, 1st, 3rd
    final order = <int>[]; // indices into ranked to display left→right
    if (ranked.length == 1) {
      order.add(0);
    } else if (ranked.length == 2) {
      order.addAll([1, 0]);
    } else {
      order.addAll([1, 0, 2]); // 2nd, 1st, 3rd
    }

    final podiumHeights = [80.0, 110.0, 60.0]; // left, center, right
    final rankLabels = ['2nd', '1st', '3rd'];

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(order.length, (slot) {
          final memberIdx = order[slot];
          if (memberIdx >= ranked.length) return const SizedBox(width: 80);
          final m = ranked[memberIdx];
          final uid = m['userId'] as String;
          final xp = xpMap[uid] ?? 0;
          final podH = podiumHeights[slot];

          return SizedBox(
            width: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  m['name'] as String? ?? '',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // TODO: Replace with Canva cat image: Image.asset('assets/images/cat_${m['avatarIndex']}.png')
                _AvatarCircle(
                  avatarIndex: m['avatarIndex'] as int? ?? 0,
                  size: slot == 1 ? 58 : 46,
                ),
                const SizedBox(height: 6),
                Container(
                  height: podH,
                  width: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: slot == 1
                          ? [AppColors.pink, const Color(0xFF7B2DBD)]
                          : [
                              const Color(0xFF3D1370),
                              const Color(0xFF5A2490),
                            ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rankLabels[slot],
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70),
                        ),
                        Text(
                          '$xp XP',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Notes section ─────────────────────────────────────────────────────────────

  Widget _buildNotesSection(List<NoteModel> notes) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO: Replace placeholder below with your Canva cat illustration:
          //   Image.asset('assets/images/cat_banner.png', width: double.infinity, fit: BoxFit.fitWidth)
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3D1370).withOpacity(0.5),
                  const Color(0xFF0D3B2E).withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(Icons.pets_rounded, color: Colors.white24, size: 56),
            ),
          ),
          const SizedBox(height: 20),
          // New note button
          GestureDetector(
            onTap: () => showModalBottomSheet(
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
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_circle_outline,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'New note',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...notes.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _NoteCard(note: n, currentUserId: widget.userId),
                )),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Private widgets
// ══════════════════════════════════════════════════════════════════════════════

// ── Avatar circle ─────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final int avatarIndex;
  final double size;

  const _AvatarCircle({required this.avatarIndex, this.size = 40});

  static const _gradients = [
    [Color(0xFF6A1B9A), Color(0xFFE040FB)], // purple
    [Color(0xFF1B5E20), Color(0xFF00C9A7)], // teal
    [Color(0xFF1A237E), Color(0xFF448AFF)], // blue
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[avatarIndex.clamp(0, 2)];
    // TODO: Replace with your Canva cat image:
    //   ClipOval(child: Image.asset('assets/images/cat_$avatarIndex.png',
    //       width: size, height: size, fit: BoxFit.cover))
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.pets_rounded,
          color: Colors.white, size: size * 0.5),
    );
  }
}

// ── Chore card (glass gradient grid) ─────────────────────────────────────────

class _ChoreCard extends StatelessWidget {
  final List<ChoreModel> chores;
  final bool isOwner;
  final void Function(ChoreModel)? onToggle;

  const _ChoreCard({
    required this.chores,
    required this.isOwner,
    this.onToggle,
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

    // Build a 2-column grid of chores
    final rows = <Widget>[];
    for (int i = 0; i < chores.length; i += 2) {
      final left = chores[i];
      final right = i + 1 < chores.length ? chores[i + 1] : null;
      rows.add(_choreRow(left, right, context));
      if (i + 2 < chores.length) {
        rows.add(Divider(color: Colors.white.withOpacity(0.08), height: 1));
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

  BoxDecoration _cardDecoration() => BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3D1370).withOpacity(0.75),
            const Color(0xFF7B2DBD).withOpacity(0.55),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      );

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
    final isPending = chore.xpStatus == 'pending';

    return Row(
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
                    color: chore.completed ? Colors.white38 : Colors.white,
                    decoration: chore.completed
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: Colors.white38,
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
          onTap: canToggle ? () => onToggle!(chore) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: chore.completed ? AppColors.pink : Colors.white38,
                width: 1.5,
              ),
              color: chore.completed
                  ? AppColors.pink.withOpacity(0.25)
                  : Colors.transparent,
            ),
            child: chore.completed
                ? const Icon(Icons.check, size: 14, color: AppColors.pink)
                : null,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ── Housemate card (tappable) ─────────────────────────────────────────────────

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
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
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
                    color: Colors.white),
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

// ── Housemate overlay (read-only chore view) ──────────────────────────────────

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
        border: Border.all(color: Colors.white.withOpacity(0.12)),
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
                color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'This week\'s chores',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          // Read-only chore list
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

// ── Note card ─────────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final String currentUserId;

  const _NoteCard({required this.note, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final isOwn = note.authorId == currentUserId;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOwn
            ? AppColors.pink.withOpacity(0.12)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwn
              ? AppColors.pink.withOpacity(0.35)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                note.authorName,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOwn ? AppColors.pink : AppColors.textSecondary),
              ),
              const Spacer(),
              const Icon(Icons.schedule, color: Colors.white24, size: 13),
              const SizedBox(width: 3),
              Text(
                'expires midnight',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.white24),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note.content,
            style: GoogleFonts.poppins(
                fontSize: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ── Small button helper ───────────────────────────────────────────────────────

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
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
