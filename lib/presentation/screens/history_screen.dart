import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/qr_item.dart';
import '../../data/models/qr_type.dart';
import '../providers/qr_history_provider.dart';
import '../providers/scanner_provider.dart';
import '../widgets/export_dialog.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QrItem> _filterItems(List<QrItem> items) {
    if (_searchQuery.trim().isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((it) {
      return it.title.toLowerCase().contains(q) ||
          it.formattedPayload.toLowerCase().contains(q) ||
          it.type.title.toLowerCase().contains(q);
    }).toList();
  }

  void _confirmDelete(BuildContext context, String id, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 28),
        title: const Text('Delete QR Code?'),
        content: Text(
          'Are you sure you want to remove "$title" from your history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () {
              ref.read(qrHistoryProvider.notifier).deleteItem(id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final historyState = ref.watch(qrHistoryProvider);
    final notifier = ref.read(qrHistoryProvider.notifier);

    final currentFilter = historyState.currentFilter;
    final displayItems = _filterItems(historyState.filteredItems);

    return Column(
      children: [
        // 1. Material 3 SearchBar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Search by title, URL or content...',
            leading: const Icon(Icons.search),
            trailing: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
            ],
            elevation: const WidgetStatePropertyAll(1),
            backgroundColor: WidgetStatePropertyAll(
              colorScheme.surfaceContainerHigh,
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),

        // 2. Material 3 FilterChips (scrollable, never wraps awkward lines)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              FilterChip(
                selected: currentFilter == HistoryFilter.all,
                showCheckmark: false,
                avatar: Icon(
                  Icons.layers_outlined,
                  size: 16,
                  color: currentFilter == HistoryFilter.all
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                label: Text('All (${historyState.totalCount})'),
                onSelected: (_) => notifier.setFilter(HistoryFilter.all),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: currentFilter == HistoryFilter.created,
                showCheckmark: false,
                avatar: Icon(
                  Icons.add_circle_outline,
                  size: 16,
                  color: currentFilter == HistoryFilter.created
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                label: Text('Created (${historyState.createdCount})'),
                onSelected: (_) => notifier.setFilter(HistoryFilter.created),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: currentFilter == HistoryFilter.scanned,
                showCheckmark: false,
                avatar: Icon(
                  Icons.qr_code_scanner,
                  size: 16,
                  color: currentFilter == HistoryFilter.scanned
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                label: Text('Scanned (${historyState.scannedCount})'),
                onSelected: (_) => notifier.setFilter(HistoryFilter.scanned),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: currentFilter == HistoryFilter.favorites,
                showCheckmark: false,
                avatar: Icon(
                  Icons.star_outline,
                  size: 16,
                  color: currentFilter == HistoryFilter.favorites
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                label: Text('Favorites (${historyState.favoritesCount})'),
                onSelected: (_) => notifier.setFilter(HistoryFilter.favorites),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // 3. List View / Empty State
        Expanded(
          child: historyState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : displayItems.isEmpty
              ? _buildEmptyState(context, currentFilter)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: displayItems.length,
                  itemBuilder: (ctx, index) {
                    final item = displayItems[index];
                    return _buildItemCard(context, item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, HistoryFilter filter) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_searchQuery.trim().isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_off, size: 44, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              Text(
                'No matching QR codes',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'No results match "$_searchQuery".',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Text('Clear Search'),
              ),
            ],
          ),
        ),
      );
    }

    String title;
    String message;
    IconData icon;
    Widget? actionButton;

    switch (filter) {
      case HistoryFilter.all:
        title = 'No QR Codes Yet';
        message = 'Create your first customized QR code or scan one with the camera.';
        icon = Icons.qr_code_2_outlined;
        actionButton = FilledButton.icon(
          onPressed: () => context.push('/scan'),
          icon: const Icon(Icons.qr_code_scanner, size: 18),
          label: const Text('Scan QR Code'),
        );
        break;
      case HistoryFilter.created:
        title = 'No Created Codes';
        message = 'You haven\'t created any QR codes yet. Choose a type from the Create tab to start!';
        icon = Icons.draw_outlined;
        break;
      case HistoryFilter.scanned:
        title = 'No Scanned Codes';
        message = 'Scan QR codes using the camera scanner to keep a history of links and contacts.';
        icon = Icons.qr_code_scanner_outlined;
        actionButton = FilledButton.icon(
          onPressed: () => context.push('/scan'),
          icon: const Icon(Icons.qr_code_scanner, size: 18),
          label: const Text('Open Scanner'),
        );
        break;
      case HistoryFilter.favorites:
        title = 'No Bookmarks Yet';
        message = 'Tap the star icon on any QR code card to save it to your favorites.';
        icon = Icons.star_border_rounded;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 20),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, QrItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCustomTitle = item.title.trim() != item.type.title.trim();
    final isUpi = item.type == QrType.upi || item.formattedPayload.startsWith('upi://');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: item.type.brandColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(item.type.icon, color: item.type.brandColor, size: 24),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.formattedPayload,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (isCustomTitle)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.type.brandColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.type.title,
                      style: TextStyle(
                        fontSize: 10,
                        color: item.type.brandColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.isScanned
                        ? colorScheme.tertiaryContainer.withValues(alpha: 0.6)
                        : colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.isScanned ? Icons.qr_code_scanner : Icons.draw_outlined,
                        size: 11,
                        color: item.isScanned
                            ? colorScheme.onTertiaryContainer
                            : colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.isScanned ? 'Scanned' : 'Created',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.isScanned
                              ? colorScheme.onTertiaryContainer
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: item.isFavorite ? 'Remove from favorites' : 'Add to favorites',
              icon: Icon(
                item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: item.isFavorite ? Colors.amber : colorScheme.onSurfaceVariant,
                size: 24,
              ),
              onPressed: () => ref.read(qrHistoryProvider.notifier).toggleFavorite(item.id),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
              onSelected: (action) {
                if (action == 'pay') {
                  ref.read(scannerProvider.notifier).launchExternal(item.formattedPayload);
                } else if (action == 'export') {
                  ExportDialog.show(context, item);
                } else if (action == 'edit') {
                  context.push('/customize', extra: item);
                } else if (action == 'delete') {
                  _confirmDelete(context, item.id, item.title);
                }
              },
              itemBuilder: (_) => [
                if (isUpi)
                  const PopupMenuItem(
                    value: 'pay',
                    child: Row(
                      children: [
                        Icon(Icons.payment, size: 20, color: Color(0xFF059669)),
                        SizedBox(width: 12),
                        Text(
                          'Pay via UPI App',
                          style: TextStyle(
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Download / Export'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.palette_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Customize Style'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                      const SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: colorScheme.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => context.push('/customize', extra: item),
      ),
    );
  }
}
