import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:path/path.dart' as p;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../services/pdf_library_repository.dart';
import '../../../services/security_service.dart';

enum PdfSecurityMode { lock, unlock, status }

class PdfLockerScreen extends StatefulWidget {
  final String filePath;
  final PdfSecurityMode initialMode;

  const PdfLockerScreen({
    super.key,
    required this.filePath,
    this.initialMode = PdfSecurityMode.lock,
  });

  @override
  State<PdfLockerScreen> createState() => _PdfLockerScreenState();
}

class _PdfLockerScreenState extends State<PdfLockerScreen> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _service = SecurityService();

  late PdfSecurityMode _mode;
  bool _obscure = true;
  bool _busy = false;
  bool? _locked;
  String? _resultPath;
  String? _message;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (_mode == PdfSecurityMode.status) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkStatus());
    }
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _title => switch (_mode) {
    PdfSecurityMode.lock => 'Lock PDF',
    PdfSecurityMode.unlock => 'Unlock PDF',
    PdfSecurityMode.status => 'PDF Lock Status',
  };

  String get _subtitle => p.basename(widget.filePath);

  bool get _canSubmit {
    final pin = _pinCtrl.text.trim();
    return switch (_mode) {
      PdfSecurityMode.lock => pin.isNotEmpty && pin == _confirmCtrl.text.trim(),
      PdfSecurityMode.unlock => pin.isNotEmpty,
      PdfSecurityMode.status => true,
    };
  }

  void _setMode(PdfSecurityMode mode) {
    setState(() {
      _mode = mode;
      _message = null;
      _resultPath = null;
      _locked = null;
      _pinCtrl.clear();
      _confirmCtrl.clear();
    });
    if (mode == PdfSecurityMode.status) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final locked = await _service.isPdfLocked(widget.filePath);
      if (!mounted) return;
      setState(() {
        _locked = locked;
        _message = locked ? 'This PDF is locked.' : 'This PDF is not locked.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Could not check PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit || _busy) return;
    if (_mode == PdfSecurityMode.status) {
      await _checkStatus();
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
      _resultPath = null;
    });

    try {
      final pin = _pinCtrl.text.trim();
      final out = switch (_mode) {
        PdfSecurityMode.lock => await _service.lockPdf(widget.filePath, pin),
        PdfSecurityMode.unlock => await _service.unlockPdf(
          widget.filePath,
          pin,
        ),
        PdfSecurityMode.status => widget.filePath,
      };
      await PdfLibraryRepository.instance.recordOpened(out);
      if (!mounted) return;
      setState(() {
        _resultPath = out;
        _locked = _mode == PdfSecurityMode.lock;
        _message = _mode == PdfSecurityMode.lock
            ? 'Locked PDF created.'
            : 'Unlocked PDF created.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = _mode == PdfSecurityMode.unlock
            ? 'Unlock failed. Check the PIN and try again.'
            : 'Security action failed: $e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _modeButton(PdfSecurityMode mode, IconData icon, String label) {
    final selected = _mode == mode;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: _busy ? null : () => _setMode(mode),
        icon: Icon(icon, size: 18),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: selected
              ? AppColors.primary
              : AppColors.textSecondary,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
          ),
          backgroundColor: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
      ),
    );
  }

  Widget _statusPanel() {
    final locked = _locked;
    final icon = locked == null
        ? Iconsax.shield_search
        : locked
        ? Iconsax.lock
        : Iconsax.unlock;
    final color = locked == null
        ? AppColors.textSecondary
        : locked
        ? AppColors.redTrim
        : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _message ?? 'Choose an action for this PDF.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showPin = _mode != PdfSecurityMode.status;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: GlassAppBar(
        title: _title,
        subtitle: _subtitle,
        showBackButton: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                _modeButton(PdfSecurityMode.lock, Iconsax.lock, 'Lock'),
                const SizedBox(width: 8),
                _modeButton(PdfSecurityMode.unlock, Iconsax.unlock, 'Unlock'),
                const SizedBox(width: 8),
                _modeButton(
                  PdfSecurityMode.status,
                  Iconsax.shield_search,
                  'Check',
                ),
              ],
            ),
            const SizedBox(height: 28),
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _mode == PdfSecurityMode.unlock
                      ? Iconsax.unlock
                      : _mode == PdfSecurityMode.status
                      ? Iconsax.shield_search
                      : Iconsax.lock,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (showPin) ...[
              Text('PIN', style: AppTypography.label),
              const SizedBox(height: 8),
              TextField(
                controller: _pinCtrl,
                obscureText: _obscure,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: AppTypography.body,
                decoration: InputDecoration(
                  hintText: 'Enter PIN',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Iconsax.eye_slash : Iconsax.eye,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (_mode == PdfSecurityMode.lock) ...[
                const SizedBox(height: 16),
                Text('Confirm PIN', style: AppTypography.label),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: AppTypography.body,
                  decoration: const InputDecoration(hintText: 'Re-enter PIN'),
                ),
              ],
              const SizedBox(height: 18),
            ],
            _statusPanel(),
            const SizedBox(height: 28),
            GradientButton(
              label: _mode == PdfSecurityMode.status
                  ? 'Check Lock Status'
                  : _mode == PdfSecurityMode.unlock
                  ? 'Unlock PDF'
                  : 'Lock PDF',
              icon: _mode == PdfSecurityMode.unlock
                  ? Iconsax.unlock
                  : _mode == PdfSecurityMode.status
                  ? Iconsax.shield_search
                  : Iconsax.lock,
              isLoading: _busy,
              onPressed: _canSubmit ? _submit : null,
            ),
            if (_resultPath != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => context.push(
                  '/viewer?path=${Uri.encodeComponent(_resultPath!)}',
                ),
                icon: const Icon(Iconsax.eye),
                label: const Text('View PDF'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
