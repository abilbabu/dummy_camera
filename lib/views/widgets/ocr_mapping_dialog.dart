import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/ocr_rule_model.dart';

/// Modal bottom sheet allowing users to manually map an unrecognized OCR token
/// or label field directly into the local SQLite database.
class OcrMappingBottomSheet extends StatefulWidget {
  final List<String> detectedLines;
  final String? initialToken;
  final String? initialCategory;
  final Future<void> Function({
    required String category,
    required String token,
    String? targetValue,
    String? parentBrand,
  }) onSave;

  const OcrMappingBottomSheet({
    super.key,
    this.detectedLines = const [],
    this.initialToken,
    this.initialCategory,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    List<String> detectedLines = const [],
    String? initialToken,
    String? initialCategory,
    required Future<void> Function({
      required String category,
      required String token,
      String? targetValue,
      String? parentBrand,
    }) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OcrMappingBottomSheet(
        detectedLines: detectedLines,
        initialToken: initialToken,
        initialCategory: initialCategory,
        onSave: onSave,
      ),
    );
  }

  @override
  State<OcrMappingBottomSheet> createState() => _OcrMappingBottomSheetState();
}

class _OcrMappingBottomSheetState extends State<OcrMappingBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedCategory;
  late final TextEditingController _tokenController;
  late final TextEditingController _targetValueController;
  late final TextEditingController _parentBrandController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'brand';
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
    _targetValueController = TextEditingController();
    _parentBrandController = TextEditingController();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _targetValueController.dispose();
    _parentBrandController.dispose();
    super.dispose();
  }

  String _getCategoryHint() {
    switch (_selectedCategory) {
      case 'brand':
        return 'Maps this OCR word to a manufacturer (e.g., "JSW" -> "JSW Paints").';
      case 'sub_brand':
        return 'Maps a product line to its sub-brand and parent company (e.g., "APEX" -> "Apex" under "Asian Paints").';
      case 'boilerplate':
        return 'Legal, address, or regulatory text to strictly ignore (never treat as Paint Name).';
      case 'paint_prefix':
        return 'Prefix keyword identifying a paint type or shade line (e.g., "PGE", "PU", "ENAMEL").';
      case 'skip_token':
        return 'Corporate token to strip away from paint name candidates.';
      default:
        return '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        category: _selectedCategory,
        token: _tokenController.text.trim().toUpperCase(),
        targetValue: _targetValueController.text.trim().isNotEmpty
            ? _targetValueController.text.trim()
            : null,
        parentBrand: _parentBrandController.text.trim().isNotEmpty
            ? _parentBrandController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Mapping saved! Token "${_tokenController.text.trim().toUpperCase()}" learned.'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save mapping: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Train Dynamic OCR Rule',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Map unrecognized text into local SQLite dictionary',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Detected Lines Chip Suggestions (if any)
              if (widget.detectedLines.isNotEmpty) ...[
                const Text(
                  'Tap a detected OCR line to populate token:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.detectedLines.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final line = widget.detectedLines[i].trim();
                      if (line.isEmpty) return const SizedBox.shrink();
                      return ActionChip(
                        label: Text(
                          line.length > 25 ? '${line.substring(0, 25)}...' : line,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: AppColors.background,
                        side: const BorderSide(color: AppColors.border),
                        onPressed: () {
                          setState(() {
                            _tokenController.text = line.toUpperCase();
                            if (_selectedCategory == 'brand' && _targetValueController.text.isEmpty) {
                              _targetValueController.text = line;
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Category Selector
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Rule Category',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                items: OcrRuleCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat.key,
                    child: Text(cat.label),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 6),
              Text(
                _getCategoryHint(),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              // Token Field
              TextFormField(
                controller: _tokenController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Token / Text in Image *',
                  hintText: 'e.g. OPUS, APEX, KANSAI, REGD OFFICE',
                  prefixIcon: const Icon(Icons.text_fields_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Token text is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Target Canonical Name (for Brand & Sub-Brand)
              if (_selectedCategory == 'brand' || _selectedCategory == 'sub_brand') ...[
                TextFormField(
                  controller: _targetValueController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: _selectedCategory == 'brand'
                        ? 'Canonical Brand Name *'
                        : 'Sub-Brand / Product Line Name *',
                    hintText: _selectedCategory == 'brand' ? 'e.g. Asian Paints' : 'e.g. Apex Ultima',
                    prefixIcon: const Icon(Icons.label_outline_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Canonical display name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Parent Brand (for Sub-Brand only)
              if (_selectedCategory == 'sub_brand') ...[
                TextFormField(
                  controller: _parentBrandController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Parent Manufacturer Brand *',
                    hintText: 'e.g. Asian Paints, Berger Paints, Nerolac',
                    prefixIcon: const Icon(Icons.business_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Parent manufacturer brand is required for sub-brands';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Submit Action
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(_isSaving ? 'Saving...' : 'Save & Re-Extract Label'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
