import 'package:flutter/material.dart';
import '../../models/bill_model.dart';
import '../theme.dart';

class BillCard extends StatelessWidget {
  final BillModel bill;
  final String paidByName; // resolved from userID
  final VoidCallback? onDelete;

  const BillCard({
    super.key,
    required this.bill,
    required this.paidByName,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top row: icon + category + amount ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                _CategoryBadge(category: bill.category),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bill.category.label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text(
                  '\$${bill.amount.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Divider ────────────────────────────────────────────────────
          Divider(
            height: 1,
            color: Colors.white.withOpacity(0.07),
            indent: 14,
            endIndent: 14,
          ),

          // ── Bottom row: "Paid by" chip ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                Text(
                  'Paid by',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(width: 8),
                _UserChip(userName: paidByName),
                const Spacer(),
                Text(
                  '÷${bill.splitBetween.length} people',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
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

// ── Category icon badge ────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final BillCategory category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Center(
        child: Text(
          category.emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

// ── User name pill ─────────────────────────────────────────────────────────────

class _UserChip extends StatelessWidget {
  final String userName;

  const _UserChip({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pink.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: AppColors.pink.withOpacity(0.3),
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.pink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            userName,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}