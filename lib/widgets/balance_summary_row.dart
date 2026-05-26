import 'package:flutter/material.dart';
import 'package:fluttertry/theme.dart';

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
            gradientColors: const [AppColors.oweStart, AppColors.oweEnd],
            amountColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BalanceCard(
            label: 'Owe you',
            amount: oweYou,
            gradientColors: const [AppColors.owedStart, AppColors.owedEnd],
            amountColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final double amount;
  final List<Color> gradientColors;
  final Color amountColor;

  const _BalanceCard({
    required this.label,
    required this.amount,
    required this.gradientColors,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.4),
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
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${amount.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                ),
          ),
        ],
      ),
    );
  }
}