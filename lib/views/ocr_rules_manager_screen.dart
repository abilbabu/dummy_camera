import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/ocr_rule_model.dart';
import '../services/extraction_rules_repository.dart';
import 'widgets/ocr_mapping_dialog.dart';

class _RuleTabItem {
  final String key;
  final String label;
  final IconData icon;
  const _RuleTabItem(this.key, this.label, this.icon);
}

/// Screen allowing users to inspect, add, edit, disable, or delete
/// dynamic OCR extraction rules stored in the local SQLite database.
class OcrRulesManagerScreen extends StatefulWidget {
  const OcrRulesManagerScreen({super.key});

  @override
  State<OcrRulesManagerScreen> createState() => _OcrRulesManagerScreenState();
}

class _OcrRulesManagerScreenState extends State<OcrRulesManagerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _filterCustomOnly = false;

  final List<_RuleTabItem> _tabs = const [
    _RuleTabItem('brand', 'Brands', Icons.business_rounded),
    _RuleTabItem('sub_brand', 'Sub-Brands', Icons.layers_rounded),
    _RuleTabItem('boilerplate', 'Boilerplate', Icons.filter_alt_outlined),
    _RuleTabItem('paint_prefix', 'Prefixes & Skips', Icons.label_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddRuleDialog() {
    final currentCategory = _tabs[_tabController.index].key;
    OcrMappingBottomSheet.show(
      context,
      initialCategory: currentCategory,
      onSave: ({
        required String category,
        required String token,
        String? targetValue,
        String? parentBrand,
      }) async {
        final repo = context.read<ExtractionRulesRepository>();
        await repo.addRule(
          category: category,
          token: token,
          targetValue: targetValue,
          parentBrand: parentBrand,
        );
        setState(() {});
      },
    );
  }

  void _showEditRuleDialog(OcrRuleModel rule) {
    final tokenController = TextEditingController(text: rule.token);
    final targetController = TextEditingController(text: rule.targetValue ?? '');
    final parentController = TextEditingController(text: rule.parentBrand ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Rule: ${rule.token}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tokenController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Token / Pattern'),
              ),
              if (rule.category == 'brand' || rule.category == 'sub_brand') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: targetController,
                  decoration: InputDecoration(
                    labelText: rule.category == 'brand' ? 'Canonical Brand' : 'Sub-Brand Name',
                  ),
                ),
              ],
              if (rule.category == 'sub_brand') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: parentController,
                  decoration: const InputDecoration(labelText: 'Parent Brand Name'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final repo = context.read<ExtractionRulesRepository>();
              await repo.updateRule(rule.copyWith(
                token: tokenController.text.trim().toUpperCase(),
                targetValue: targetController.text.trim().isNotEmpty
                    ? targetController.text.trim()
                    : null,
                parentBrand: parentController.text.trim().isNotEmpty
                    ? parentController.text.trim()
                    : null,
              ));
              if (ctx.mounted) Navigator.of(ctx).pop();
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRule(OcrRuleModel rule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Rule?'),
        content: Text('Are you sure you want to delete rule "${rule.token}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              if (rule.id != null) {
                final repo = context.read<ExtractionRulesRepository>();
                await repo.deleteRule(rule.id!);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
              setState(() {});
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmResetDefaults() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset to Factory Defaults?'),
        content: const Text(
          'This will remove all custom added OCR rules and re-enable default factory brand dictionaries. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              final repo = context.read<ExtractionRulesRepository>();
              await repo.resetToDefaults();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Reset to factory default rules!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
              if (mounted) setState(() {});
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportRulesJson() async {
    final repo = context.read<ExtractionRulesRepository>();
    final jsonStr = await repo.exportRulesJson();
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rules exported and copied to clipboard as JSON!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showImportDialog() {
    final jsonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Rules from JSON'),
        content: TextField(
          controller: jsonController,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste exported JSON rules array here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = jsonController.text.trim();
              if (text.isEmpty) return;
              try {
                final repo = context.read<ExtractionRulesRepository>();
                final count = await repo.importRulesJson(text);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Successfully imported $count rules!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
                if (mounted) setState(() {});
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Import failed: $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ExtractionRulesRepository>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Dynamic OCR Rules',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Export Rules (JSON)',
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: _exportRulesJson,
          ),
          IconButton(
            tooltip: 'Import Rules (JSON)',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _showImportDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'reset') _confirmResetDefaults();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt_rounded, color: AppColors.danger, size: 20),
                    SizedBox(width: 8),
                    Text('Reset to Defaults', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search and Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search rules, tokens, or brands...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _filterCustomOnly,
                      label: const Text('Custom Only', style: TextStyle(fontSize: 12)),
                      onSelected: (v) => setState(() => _filterCustomOnly = v),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              // TabBar
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: _tabs.map((tab) {
                  return Tab(
                    child: Row(
                      children: [
                        Icon(tab.icon, size: 16),
                        const SizedBox(width: 6),
                        Text(tab.label),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<OcrRuleModel>>(
        future: repo.getRules(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allRules = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) {
              final categoryKey = tab.key;
              final filtered = allRules.where((r) {
                // Match category
                if (categoryKey == 'paint_prefix') {
                  if (r.category != 'paint_prefix' && r.category != 'skip_token') return false;
                } else if (r.category != categoryKey) {
                  return false;
                }

                // Custom filter
                if (_filterCustomOnly && !r.isCustom) return false;

                // Search query
                if (_searchQuery.isNotEmpty) {
                  final tokenMatch = r.token.toLowerCase().contains(_searchQuery);
                  final targetMatch = (r.targetValue ?? '').toLowerCase().contains(_searchQuery);
                  final parentMatch = (r.parentBrand ?? '').toLowerCase().contains(_searchQuery);
                  if (!tokenMatch && !targetMatch && !parentMatch) return false;
                }

                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rule_folder_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No rules match "$_searchQuery"'
                            : 'No rules found in this category',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _openAddRuleDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Rule'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final rule = filtered[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    color: rule.isActive ? AppColors.surface : AppColors.background,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              rule.token,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: rule.isActive ? AppColors.textPrimary : AppColors.textMuted,
                                decoration: rule.isActive ? null : TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: rule.isCustom
                                  ? AppColors.primaryLight.withValues(alpha: 0.2)
                                  : AppColors.borderLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rule.isCustom ? 'Custom' : 'System',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: rule.isCustom ? AppColors.primaryDark : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (rule.targetValue != null)
                            Text(
                              'Maps to: ${rule.targetValue}${rule.parentBrand != null ? ' (${rule.parentBrand})' : ''}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          if (categoryKey == 'paint_prefix')
                            Text(
                              rule.category == 'skip_token' ? 'Type: Skip Token' : 'Type: Paint Prefix',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: rule.isActive,
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: AppColors.primaryLight.withValues(alpha: 0.3),
                            onChanged: (val) async {
                              if (rule.id != null) {
                                await repo.toggleRuleActive(rule.id!, val);
                                setState(() {});
                              }
                            },
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                            onSelected: (action) {
                              if (action == 'edit') {
                                _showEditRuleDialog(rule);
                              } else if (action == 'delete') {
                                _confirmDeleteRule(rule);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: AppColors.danger)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddRuleDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Rule'),
      ),
    );
  }
}
