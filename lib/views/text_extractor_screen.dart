import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/text_extractor_controller.dart';
import '../core/app_theme.dart';
import '../models/paint_label_data.dart';

/// Screen for capturing/uploading photos of paint cartons or buckets,
/// extracting specific target fields (Paint Name, MRP, USP, Pack Qty, Mfd, Batch),
/// and viewing the full extracted text.
class TextExtractorScreen extends StatefulWidget {
  const TextExtractorScreen({super.key});

  @override
  State<TextExtractorScreen> createState() => _TextExtractorScreenState();
}

class _TextExtractorScreenState extends State<TextExtractorScreen> {
  bool _showRawText = false;

  void _copyToClipboard(BuildContext context, String text, String label) {
    if (text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label copied to clipboard!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TextExtractorController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.format_paint_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'Paint Label Extractor',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          if (controller.hasResult || controller.imageFile != null)
            IconButton(
              tooltip: 'Clear & New Scan',
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
              onPressed: () => controller.clear(),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Primary Action Buttons: Camera & Gallery
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.isProcessing
                          ? null
                          : () => controller.captureFromCamera(),
                      icon: const Icon(Icons.camera_alt_rounded, size: 20),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.isProcessing
                          ? null
                          : () => controller.pickFromGallery(),
                      icon: const Icon(Icons.photo_library_rounded, size: 20),
                      label: const Text('From Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // Main Content Area
            Expanded(
              child: controller.isProcessing
                  ? _buildProcessingState()
                  : controller.hasResult
                      ? _buildResultView(context, controller)
                      : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.cameraCardBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cameraCardBorder, width: 2),
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                size: 46,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scan Paint Box or Label',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Snap a photo or upload an image from your gallery.\nExtracts Brand, Paint Name, MRP, Unit Price, Pack Size, Mfd & Batch.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    '100% Free & Offline • On-Device ML Kit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Processing Indicator
  Widget _buildProcessingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 18),
            Text(
              'Analyzing Paint Label...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Extracting paint name & key packaging fields',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Result View: Specific Extracted Fields (Textract style)
  Widget _buildResultView(BuildContext context, TextExtractorController controller) {
    final data = controller.paintLabelData ??
        PaintLabelData(rawText: controller.text, rawLines: controller.extractedResult?.lines ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview Thumbnail
          if (controller.imageFile != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      controller.imageFile!,
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Captured Label',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Target fields extracted offline',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _copyToClipboard(context, data.formattedSummary, 'All data'),
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy All', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Section Title
          const Row(
            children: [
              Icon(Icons.label_important_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'Extracted Paint Data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Single Unified Card with All Extracted Paint Data
          _buildUnifiedPaintDataCard(context, data),

          const SizedBox(height: 16),

          // 3. Collapsible Raw OCR Text
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ExpansionTile(
              initiallyExpanded: _showRawText,
              onExpansionChanged: (val) => setState(() => _showRawText = val),
              shape: const Border(),
              leading: const Icon(Icons.notes_rounded, color: AppColors.textSecondary),
              title: const Text(
                'View All Raw OCR Text',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: SelectableText(
                          data.rawText.isNotEmpty ? data.rawText : 'No text available.',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.45,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _copyToClipboard(context, data.rawText, 'Raw text'),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy Raw Text'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Single unified card displaying all extracted paint data in one structured container
  Widget _buildUnifiedPaintDataCard(BuildContext context, PaintLabelData data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with title and "Copy All" action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Extracted Paint Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _copyToClipboard(context, data.formattedSummary, 'All paint data'),
                  icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                  label: const Text(
                    'Copy All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.cameraCardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          // 0. BRAND NAME
          if (data.brandName != null && data.brandName!.trim().isNotEmpty) ...[
            _buildCardRow(
              context,
              label: 'BRAND',
              subtitle: 'Manufacturer brand',
              value: data.brandName!,
              isAvailable: true,
              icon: Icons.verified_rounded,
              iconColor: const Color(0xFFDC2626),
              iconBgColor: const Color(0xFFFEF2F2),
              valueColor: const Color(0xFFDC2626),
              valueSize: 16,
            ),
            const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
          ],

          // 0b. SUB-BRAND
          if (data.subBrand != null && data.subBrand!.trim().isNotEmpty) ...[
            _buildCardRow(
              context,
              label: 'SUB-BRAND',
              subtitle: 'Product line / series',
              value: data.subBrand!,
              isAvailable: true,
              icon: Icons.category_rounded,
              iconColor: const Color(0xFF7C3AED),
              iconBgColor: const Color(0xFFF5F3FF),
              valueColor: const Color(0xFF7C3AED),
              valueSize: 15,
            ),
            const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
          ],

          // 1. MRP
          _buildCardRow(
            context,
            label: 'MRP',
            subtitle: 'Incl. of all taxes',
            value: data.mrp ?? 'Not detected',
            isAvailable: data.mrp != null,
            icon: Icons.currency_rupee_rounded,
            iconColor: const Color(0xFF059669),
            iconBgColor: const Color(0xFFECFDF5),
            valueColor: const Color(0xFF059669),
          ),
          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),

          // 2. UNIT SALE PRICE
          _buildCardRow(
            context,
            label: 'UNIT SALE PRICE',
            subtitle: 'Per litre / per ml rate',
            value: data.unitSalePrice ?? 'Not detected',
            isAvailable: data.unitSalePrice != null,
            icon: Icons.sell_rounded,
            iconColor: const Color(0xFF4F46E5),
            iconBgColor: const Color(0xFFEEF2FF),
            valueColor: const Color(0xFF4F46E5),
          ),
          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),

          // 3. NET QUANTITY
          _buildCardRow(
            context,
            label: 'NET QUANTITY',
            value: data.packQuantity ?? 'Not detected',
            isAvailable: data.packQuantity != null,
            icon: Icons.inventory_2_outlined,
            iconColor: const Color(0xFFD97706),
            iconBgColor: const Color(0xFFFFFBEB),
          ),
          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),

          // 4. MFD
          _buildCardRow(
            context,
            label: 'MFD',
            subtitle: 'Manufacturing date',
            value: data.mfd ?? 'Not detected',
            isAvailable: data.mfd != null,
            icon: Icons.calendar_today_rounded,
            iconColor: const Color(0xFF7C3AED),
            iconBgColor: const Color(0xFFF5F3FF),
          ),
          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),

          // 5. PAINT NAME
          _buildCardRow(
            context,
            label: 'PAINT NAME',
            subtitle: 'Product / variant name (brand excluded)',
            value: data.paintName ?? 'Not detected',
            isAvailable: data.paintName != null,
            icon: Icons.palette_rounded,
            iconColor: const Color(0xFF0284C7),
            iconBgColor: const Color(0xFFE0F2FE),
            valueSize: 16,
          ),

          // 6. BASE (if BASE exists there)
          if (data.base != null && data.base!.trim().isNotEmpty) ...[
            const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
            _buildCardRow(
              context,
              label: 'BASE',
              subtitle: 'Base component / shade specification',
              value: data.base!,
              isAvailable: true,
              icon: Icons.layers_rounded,
              iconColor: const Color(0xFF0891B2),
              iconBgColor: const Color(0xFFECFEFF),
            ),
          ],

          // 7. HARDENER (if HARDENER exists then show)
          if (data.hardener != null && data.hardener!.trim().isNotEmpty) ...[
            const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
            _buildCardRow(
              context,
              label: 'HARDENER',
              subtitle: 'Catalyst / curing component',
              value: data.hardener!,
              isAvailable: true,
              icon: Icons.science_rounded,
              iconColor: const Color(0xFFE11D48),
              iconBgColor: const Color(0xFFFFF1F2),
            ),
          ],

          // 8. BATCH NO. (if exists)
          if (data.batchNo != null && data.batchNo!.trim().isNotEmpty) ...[
            const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
            _buildCardRow(
              context,
              label: 'BATCH NO.',
              value: data.batchNo!,
              isAvailable: true,
              icon: Icons.tag_rounded,
              iconColor: const Color(0xFF475569),
              iconBgColor: const Color(0xFFF1F5F9),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a single clean row within the unified card
  Widget _buildCardRow(
    BuildContext context, {
    required String label,
    required String value,
    required bool isAvailable,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    String? subtitle,
    Color? valueColor,
    double valueSize = 15,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w700,
                    color: isAvailable
                        ? (valueColor ?? AppColors.textPrimary)
                        : AppColors.textMuted,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isAvailable)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textSecondary),
              tooltip: 'Copy $label',
              onPressed: () => _copyToClipboard(context, value, label),
            ),
        ],
      ),
    );
  }
}
