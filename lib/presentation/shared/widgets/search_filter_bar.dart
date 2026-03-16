/// Reusable search & filter bar widget.
///
/// Provides a search TextField with debounce and optional filter chips.
/// Used across Products, Partners, Trading, and POS pages.
library;

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:fishcash_pos/core/theme/ocean_theme.dart';

/// A single filter chip option
class FilterOption {
  final String id;
  final String label;
  final IconData? icon;

  const FilterOption({
    required this.id,
    required this.label,
    this.icon,
  });
}

class SearchFilterBar extends StatefulWidget {
  /// Hint text for the search field
  final String hintText;

  /// Called when search query changes (after debounce)
  final ValueChanged<String> onSearchChanged;

  /// Optional list of filter options displayed as chips
  final List<FilterOption>? filters;

  /// Currently selected filter id
  final String? selectedFilterId;

  /// Called when a filter chip is tapped
  final ValueChanged<String>? onFilterChanged;

  /// Debounce duration for search input
  final Duration debounceDuration;

  const SearchFilterBar({
    super.key,
    this.hintText = 'Tìm kiếm...',
    required this.onSearchChanged,
    this.filters,
    this.selectedFilterId,
    this.onFilterChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onSearchChanged(query.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search field
          TextField(
            controller: _controller,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon:
                  Icon(Icons.search, color: cs.onSurfaceVariant, size: 20),
              suffixIcon: ListenableBuilder(
                listenable: _controller,
                builder: (_, _) {
                  if (_controller.text.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _controller.clear();
                      widget.onSearchChanged('');
                    },
                  );
                },
              ),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: OceanTheme.oceanPrimary, width: 1.5),
              ),
              isDense: true,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          // Filter chips
          if (widget.filters != null && widget.filters!.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.filters!.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final filter = widget.filters![index];
                  final isSelected = filter.id == widget.selectedFilterId;

                  return FilterChip(
                    selected: isSelected,
                    label: Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    avatar: filter.icon != null
                        ? Icon(filter.icon, size: 16)
                        : null,
                    onSelected: (_) {
                      widget.onFilterChanged?.call(filter.id);
                    },
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
