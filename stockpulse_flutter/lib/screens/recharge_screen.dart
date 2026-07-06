import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../utils/formatter.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final _supabase = Supabase.instance.client;
  int _step = 0; // 0: amount, 1: confirm, 2: done
  int _selectedAmount = 10000;
  final _customController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;
  bool _useCustom = false;

  static const _presets = [5000, 10000, 25000, 50000];

  int get _finalAmount =>
      _useCustom ? (int.tryParse(_customController.text) ?? 0) : _selectedAmount;

  @override
  void dispose() {
    _customController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || _finalAmount <= 0) return;

    setState(() => _isLoading = true);
    try {
      await _supabase.from('recharge_requests').insert({
        'user_email': user.email,
        'user_name': user.name,
        'requested_amount': _finalAmount,
        'description': _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        'status': 'pending',
      });
      setState(() => _step = 2);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.secondary),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('E-Token Recharge', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _step == 0
                ? _buildStepAmount()
                : _step == 1
                    ? _buildStepConfirm()
                    : _buildStepDone(),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (i) {
        final active = i <= _step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active ? AppTheme.primary : AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepAmount() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepIndicator(),
        const SizedBox(height: 32),
        Text('Select Amount', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.onSurface)),
        const SizedBox(height: 8),
        Text('Choose how many E-Tokens to request from admin.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 32),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.4,
          physics: const NeverScrollableScrollPhysics(),
          children: _presets.map((amount) {
            final selected = !_useCustom && _selectedAmount == amount;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedAmount = amount;
                _useCustom = false;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.15)
                      : (AppTheme.isDark ? AppTheme.surfaceContainer.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.borderColor,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    formatINR(amount.toDouble()),
                    style: TextStyle(
                      color: selected ? AppTheme.primary : AppTheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _useCustom = true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: _useCustom
                  ? AppTheme.primary.withValues(alpha: 0.1)
                  : (AppTheme.isDark ? AppTheme.surfaceContainer.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.03)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _useCustom ? AppTheme.primary : AppTheme.borderColor,
              ),
            ),
            child: TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppTheme.onSurface),
              onTap: () => setState(() => _useCustom = true),
              decoration: InputDecoration(
                hintText: 'Custom amount...',
                hintStyle: TextStyle(color: AppTheme.onSurfaceVariant),
                border: InputBorder.none,
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _descController,
          style: TextStyle(color: AppTheme.onSurface),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Reason / note (optional)',
            hintStyle: TextStyle(color: AppTheme.onSurfaceVariant),
            filled: true,
            fillColor: AppTheme.isDark ? AppTheme.surfaceContainer.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _finalAmount > 0 ? () => setState(() => _step = 1) : null,
            child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepConfirm() {
    final user = context.read<AuthProvider>().user;
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepIndicator(),
        const SizedBox(height: 32),
        Text('Confirm Request', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.onSurface)),
        const SizedBox(height: 8),
        Text('Review your recharge request before submitting.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 32),
        GlassCard(
          child: Column(
            children: [
              _buildConfirmRow('Account', user?.email ?? ''),
              Divider(color: AppTheme.borderColor, height: 24),
              _buildConfirmRow('Requested Amount', formatINR(_finalAmount.toDouble())),
              if (_descController.text.trim().isNotEmpty) ...[
                Divider(color: AppTheme.borderColor, height: 24),
                _buildConfirmRow('Note', _descController.text.trim()),
              ],
              Divider(color: AppTheme.borderColor, height: 24),
              _buildConfirmRow('Status', 'Pending Admin Approval'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your request will be reviewed by an admin. E-Tokens will be credited upon approval.',
                  style: TextStyle(color: AppTheme.primary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.onSurfaceVariant,
                  side: BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : () => setState(() => _step = 0),
                child: const Text('BACK'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('SUBMIT REQUEST', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepDone() {
    return Column(
      key: const ValueKey(2),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepIndicator(),
        const Spacer(),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 2),
          ),
          child: const Icon(Icons.check_rounded, color: AppTheme.primary, size: 48),
        ),
        const SizedBox(height: 24),
        Text('Request Submitted!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.onSurface)),
        const SizedBox(height: 12),
        Text(
          'Your request for ${formatINR(_finalAmount.toDouble())} in E-Tokens has been sent to the admin for approval.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
