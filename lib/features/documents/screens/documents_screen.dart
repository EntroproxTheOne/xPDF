import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_morphism.dart';
import '../../../core/theme/xp_haptics.dart';
import '../../../core/widgets/xp_ui.dart';
import '../../../models/pdf_library_item.dart';
import '../../../services/pdf_library_repository.dart';
import '../../../services/pdf_pick_open_service.dart';

enum _DocSort { openedDesc, nameAsc, nameDesc }

enum _DocQuickFilter { all, scanned, exports }

/// History list — Stitch mock (8) glass rows; search/sort/filter secondary.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({
    super.key,
    this.initialFocusSearch = false,
    this.initialQuery,
  });

  final bool initialFocusSearch;
  final String? initialQuery;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late final TextEditingController _search;
  final FocusNode _searchFocus = FocusNode();

  _DocSort _sort = _DocSort.openedDesc;
  _DocQuickFilter _quickFilter = _DocQuickFilter.all;
  late bool _showSearch;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuery ?? '';
    _search = TextEditingController(text: q);
    _showSearch = widget.initialFocusSearch || q.isNotEmpty;
    if (widget.initialFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocus.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<PdfLibraryItem> _buildViewList(List<PdfLibraryItem> raw) {
    var list = <PdfLibraryItem>[...raw];
    final query = _search.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where(
            (e) =>
                e.title.toLowerCase().contains(query) ||
                e.path.toLowerCase().contains(query),
          )
          .toList(growable: false);
    }

    switch (_quickFilter) {
      case _DocQuickFilter.all:
        break;
      case _DocQuickFilter.scanned:
        list = list
            .where((e) {
              final t = e.title.toLowerCase();
              final p = e.path.toLowerCase();
              return t.contains('scan') || p.contains('scan');
            })
            .toList(growable: false);
      case _DocQuickFilter.exports:
        list = list
            .where((e) {
              final t = e.title.toLowerCase();
              return t.contains('export') ||
                  t.contains('edited') ||
                  t.endsWith('_export.pdf');
            })
            .toList(growable: false);
    }

    switch (_sort) {
      case _DocSort.openedDesc:
        list.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
      case _DocSort.nameAsc:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case _DocSort.nameDesc:
        list.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
    }
    return list;
  }

  String _sortLabel(_DocSort s) {
    return switch (s) {
      _DocSort.openedDesc => 'Recent',
      _DocSort.nameAsc => 'Name A→Z',
      _DocSort.nameDesc => 'Name Z→A',
    };
  }

  String _filterLabel(_DocQuickFilter f) {
    return switch (f) {
      _DocQuickFilter.all => 'All',
      _DocQuickFilter.scanned => 'Scanned',
      _DocQuickFilter.exports => 'Exports',
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 92;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          const XpAmbientBackground(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              XpMobileTopBar(
                onMenu: () => showXpMissionMenu(context),
                centerTitle: '',
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: PdfLibraryRepository.instance,
                  builder: (context, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'History',
                                style: AppTypography.display.copyWith(
                                  fontSize: 30,
                                  height: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Review and manage your recently processed documents.',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Search',
                                    onPressed: () {
                                      XpHaptics.surfaceTap();
                                      setState(() {
                                        _showSearch = !_showSearch;
                                        if (_showSearch) {
                                          _searchFocus.requestFocus();
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      Iconsax.search_normal,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Open PDF',
                                    onPressed: () {
                                      XpHaptics.surfaceTap();
                                      pickPdfAndNavigateViewer(context);
                                    },
                                    icon: Icon(
                                      Iconsax.add_circle,
                                      color: AppColors.primary,
                                      size: 26,
                                    ),
                                  ),
                                  const Spacer(),
                                  PopupMenuButton<String>(
                                    tooltip: 'Sort',
                                    onSelected: (v) {
                                      XpHaptics.navTap();
                                      setState(() {
                                        _sort = switch (v) {
                                          'r' => _DocSort.openedDesc,
                                          'a' => _DocSort.nameAsc,
                                          _ => _DocSort.nameDesc,
                                        };
                                      });
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'r',
                                        child: Text('Recently opened'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'a',
                                        child: Text('Name A-Z'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'z',
                                        child: Text('Name Z-A'),
                                      ),
                                    ],
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Iconsax.sort,
                                          size: 20,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _sortLabel(_sort),
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  PopupMenuButton<_DocQuickFilter>(
                                    tooltip: 'Filter',
                                    onSelected: (v) {
                                      XpHaptics.surfaceTap();
                                      setState(() => _quickFilter = v);
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: _DocQuickFilter.all,
                                        child: Text(
                                          'All',
                                          style: AppTypography.body,
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: _DocQuickFilter.scanned,
                                        child: Text(
                                          'Scanned',
                                          style: AppTypography.body,
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: _DocQuickFilter.exports,
                                        child: Text(
                                          'Exports',
                                          style: AppTypography.body,
                                        ),
                                      ),
                                    ],
                                    child: Icon(
                                      Iconsax.filter,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              /*
                              IconButton(
                                tooltip: 'Search',
                                onPressed: () {
                                  XpHaptics.surfaceTap();
                                  setState(() {
                                    _showSearch = !_showSearch;
                                    if (_showSearch) {
                                      _searchFocus.requestFocus();
                                    }
                                  });
                                },
                                icon: Icon(
                                  Iconsax.search_normal,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Open PDF…',
                                onPressed: () {
                                  XpHaptics.surfaceTap();
                                  pickPdfAndNavigateViewer(context);
                                },
                                icon: Icon(
                                  Iconsax.add_circle,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Sort',
                                onSelected: (v) {
                                  XpHaptics.navTap();
                                  setState(() {
                                    _sort = switch (v) {
                                      'r' => _DocSort.openedDesc,
                                      'a' => _DocSort.nameAsc,
                                      _ => _DocSort.nameDesc,
                                    };
                                  });
                                },
                                itemBuilder:
                                    (_) => [
                                      const PopupMenuItem(
                                        value: 'r',
                                        child: Text('Recently opened'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'a',
                                        child: Text('Name · A→Z'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'z',
                                        child: Text('Name · Z→A'),
                                      ),
                                    ],
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    right: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Iconsax.sort,
                                        size: 20,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _sortLabel(_sort),
                                        style: AppTypography.caption
                                            .copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              PopupMenuButton<_DocQuickFilter>(
                                tooltip: 'Filter',
                                onSelected: (v) {
                                  XpHaptics.surfaceTap();
                                  setState(() => _quickFilter = v);
                                },
                                itemBuilder:
                                    (_) => [
                                      PopupMenuItem(
                                        value: _DocQuickFilter.all,
                                        child: Text(
                                          'All',
                                          style: AppTypography.body,
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: _DocQuickFilter.scanned,
                                        child: Text(
                                          'Scanned',
                                          style: AppTypography.body,
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: _DocQuickFilter.exports,
                                        child: Text(
                                          'Exports',
                                          style: AppTypography.body,
                                        ),
                                      ),
                                    ],
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    left: 4,
                                  ),
                                  child: Icon(
                                    Iconsax.filter,
                                    size: 20,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              */
                            ],
                          ),
                        ),
                        if (_showSearch) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                            child: GlassContainer(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              borderRadius: 14,
                              child: Row(
                                children: [
                                  Icon(
                                    Iconsax.search_normal,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _search,
                                      focusNode: _searchFocus,
                                      style: AppTypography.body,
                                      onChanged: (_) => setState(() {}),
                                      textInputAction: TextInputAction.search,
                                      decoration: InputDecoration(
                                        hintText: 'Search by filename…',
                                        hintStyle: AppTypography.bodySmall,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                        suffixIcon: _search.text.isEmpty
                                            ? null
                                            : IconButton(
                                                tooltip: 'Clear',
                                                icon: Icon(
                                                  Icons.close_rounded,
                                                  size: 20,
                                                  color: AppColors.textMuted,
                                                ),
                                                onPressed: () {
                                                  XpHaptics.surfaceTap();
                                                  _search.clear();
                                                  setState(() {});
                                                  _searchFocus.requestFocus();
                                                },
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Showing: ${_filterLabel(_quickFilter)} · ${_sortLabel(_sort)}',
                              style: AppTypography.caption,
                            ),
                          ),
                        ),
                        Expanded(child: _buildList(bottom)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList(double bottomPad) {
    final docs = PdfLibraryRepository.instance.recent(limit: 200);
    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No PDFs tracked yet.', style: AppTypography.label),
              const SizedBox(height: 10),
              Text(
                'Use + to open a PDF, or share one into xPDF.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    final filtered = _buildViewList(docs);
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No matches', style: AppTypography.label),
              const SizedBox(height: 8),
              Text(
                'Adjust search or filters.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad),
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _HistoryGlassRow(item: filtered[index])
          .animate(delay: ((index.clamp(0, 14)) * 50).ms)
          .fadeIn(duration: 280.ms)
          .slideX(begin: 0.03, end: 0),
    );
  }
}

class _HistoryGlassRow extends StatelessWidget {
  final PdfLibraryItem item;

  const _HistoryGlassRow({required this.item});

  String _relTime(DateTime opened) {
    final delta = DateTime.now().difference(opened.toLocal());
    if (delta.inMinutes < 120) return '${delta.inMinutes} min ago';
    if (delta.inHours < 48) return '${delta.inHours} hr ago';
    return '${opened.month}/${opened.day}/${opened.year}';
  }

  PopupMenuItem<String> _menuPopup(
    String value,
    IconData icon,
    String label, {
    bool destructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: destructive ? AppColors.error : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTypography.label.copyWith(
              color: destructive ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        key: ValueKey<String>(item.path),
        borderRadius: 12,
        onTap: () =>
            context.push('/viewer?path=${Uri.encodeComponent(item.path)}'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Icon(
                Iconsax.document_text_1,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Opened • ${_relTime(item.lastOpenedAt)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Export',
              onPressed: () {
                XpHaptics.surfaceTap();
                context.push('/export?path=${Uri.encodeComponent(item.path)}');
              },
              icon: Icon(Iconsax.export_1, size: 20, color: AppColors.tertiary),
            ),
            PopupMenuButton<String>(
              icon: Icon(Iconsax.more, color: AppColors.tertiary, size: 20),
              color: AppColors.backgroundSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                switch (value) {
                  case 'view':
                    XpHaptics.navTap();
                    if (!context.mounted) return;
                    context.push(
                      '/viewer?path=${Uri.encodeComponent(item.path)}',
                    );
                  case 'edit':
                    XpHaptics.navTap();
                    if (!context.mounted) return;
                    context.push(
                      '/editor?path=${Uri.encodeComponent(item.path)}',
                    );
                  case 'export':
                    XpHaptics.navTap();
                    if (!context.mounted) return;
                    context.push(
                      '/export?path=${Uri.encodeComponent(item.path)}',
                    );
                  case 'lock':
                    XpHaptics.navTap();
                    if (!context.mounted) return;
                    context.push(
                      '/lock?path=${Uri.encodeComponent(item.path)}',
                    );
                  case 'delete':
                    XpHaptics.emphasize();
                    await PdfLibraryRepository.instance.removeRecent(item.path);
                }
              },
              itemBuilder: (_) => [
                _menuPopup('view', Iconsax.eye, 'View'),
                _menuPopup('edit', Iconsax.edit, 'Edit'),
                _menuPopup('export', Iconsax.export_1, 'Export'),
                _menuPopup('lock', Iconsax.lock, 'Lock'),
                _menuPopup(
                  'delete',
                  Iconsax.trash,
                  'Remove from recent',
                  destructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
