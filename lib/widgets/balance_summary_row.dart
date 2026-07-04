import 'package:flutter/material.dart';
import '../theme.dart';

class BalanceSummaryRow extends StatelessWidget {
  final double youOwe;
  final double oweYou;

  const BalanceSummaryRow({
    super.key,
    required this.youOwe,
    required this.oweYou,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BalanceCard(
            label: 'You owe',
            amount: youOwe,
            gradient: AppColors.youOweGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BalanceCard(
            label: 'Owe you',
            amount: oweYou,
            gradient: AppColors.oweYouGradient,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final double amount;
  final LinearGradient gradient;

  const _BalanceCard({
    required this.label,
    required this.amount,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.onBalancePanel;
    final secondary = AppColors.onBalancePanelSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: secondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${amount.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                ),
          ),
        ],
      ),
    );
  }
}
