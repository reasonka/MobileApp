import 'package:flutter/material.dart';
import '../../models/bill_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'package:fluttertry/theme.dart';

class AddBillSheet extends StatefulWidget {
  final String houseId;
  final List<UserModel> houseMembers;

  const AddBillSheet({
    super.key,
    required this.houseId,
    required this.houseMembers,
  });

  static Future<void> show(
    BuildContext context, {
    required String houseId,
    required List<UserModel> houseMembers,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBillSheet(
        houseId: houseId,
        houseMembers: houseMembers,
      ),
    );
  }

  @override
  State<AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends State<AddBillSheet> {
  final _amountController = TextEditingController();
  BillCategory _selectedCategory = BillCategory.groceries;
  late List<String> _selectedMembers;
  bool _loading = false;

  final _service = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Select all members by default
    _selectedMembers =
        widget.houseMembers.map((m) => m.userId).toList();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = double.tryParse(_amountController.text.trim());
    if (raw == null || raw <= 0) {
      _showError('Please enter a valid amount.');
      return;
    }
    if (_selectedMembers.isEmpty) {
      _showError('Select at least one member to split with.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _service.addBill(
        amount: raw,
        category: _selectedCategory,
        splitBetween: _selectedMembers,
        houseId: widget.houseId, currentUserId: '',
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to add bill: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'New Bill',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),

          // Amount field
          _SectionLabel(label: 'Amount (\$)'),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            decoration: _inputDecoration('e.g. 25.00'),
          ),
          const SizedBox(height: 18),

          // Category
          _SectionLabel(label: 'Category'),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: BillCategory.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = BillCategory.values[i];
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.pink.withOpacity(0.2)
                          : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected
                            ? AppColors.pink
                            : Colors.white.withOpacity(0.1),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(cat.emoji),
                        const SizedBox(width: 6),
                        Text(
                          cat.label,
                          style: TextStyle(
                            color: selected
                                ? AppColors.pink
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Split between
          _SectionLabel(label: 'Split between'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.houseMembers.map((member) {
              final selected = _selectedMembers.contains(member.userId);
              return FilterChip(
                label: Text(member.userName),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedMembers.add(member.userId);
                    } else {
                      _selectedMembers.remove(member.userId);
                    }
                  });
                },
                selectedColor: AppColors.pink.withOpacity(0.25),
                checkmarkColor: AppColors.pink,
                backgroundColor: AppColors.cardBg,
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.pink
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: selected
                      ? AppColors.pink
                      : Colors.white.withOpacity(0.1),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Add Bill',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.pink, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 11,
            letterSpacing: 1.2,
            color: AppColors.textMuted,
          ),
    );
  }
}