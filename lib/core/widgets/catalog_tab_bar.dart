import 'package:flutter/material.dart';

import 'tonal_tab_bar.dart';

/// Backward-compatible catalog tab bar for Explore and Library.
///
/// Delegates to [TonalTabBar] so existing screens inherit the Phase 6 tonal
/// contract without screen-by-screen rewrites.
class CatalogTabBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const CatalogTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TonalTabBar(
      labels: labels,
      selectedIndex: selectedIndex,
      onSelected: onSelected,
    );
  }
}
