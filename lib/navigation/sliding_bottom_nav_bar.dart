import 'package:flutter/material.dart';
import '../theme.dart';

class HomieNavItem {
  final IconData icon;
  final String label;

  const HomieNavItem({required this.icon, required this.label});
}

class SlidingBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final List<HomieNavItem> items;

  const SlidingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.items,
  });

  @override
  State<SlidingBottomNavBar> createState() => _SlidingBottomNavBarState();
}

class _SlidingBottomNavBarState extends State<SlidingBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnim;
  int _prev = 0;

  @override
  void initState() {
    super.initState();
    _prev = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(SlidingBottomNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _prev = old.currentIndex;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.items.length;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.navBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Sliding pill indicator ─────────────────────────────────────
          AnimatedBuilder(
            animation: _slideAnim,
            builder: (context, _) {
              final itemWidth =
                  MediaQuery.of(context).size.width / itemCount;
              final targetX = widget.currentIndex * itemWidth;
              final prevX = _prev * itemWidth;
              final currentX =
                  prevX + (targetX - prevX) * _slideAnim.value;

              return Positioned(
                left: currentX + itemWidth * 0.25,
                top: 10,
                child: Container(
                  width: itemWidth * 0.5,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.pink,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pink.withOpacity(0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Tab buttons ────────────────────────────────────────────────
          Row(
            children: List.generate(itemCount, (i) {
              final active = widget.currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onTabChanged(i),
                  child: SizedBox(
                    height: 72,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: active ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            widget.items[i].icon,
                            color: active
                                ? Colors.white
                                : AppColors.navIconInactive,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}