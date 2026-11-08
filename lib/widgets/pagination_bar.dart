import 'dart:math';

import 'package:flutter/material.dart';

// The page buttons at the bottom of the shop:  <  1  2  [3]  4  5  >
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageSelected,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241E1A) : const Color(0xFFF3ECE1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          // On very narrow phones the buttons shrink to fit.
          // heightFactor: 1 keeps the bar only as tall as the buttons.
          child: Center(
            heightFactor: 1,
            child: FittedBox(fit: BoxFit.scaleDown, child: _buildButtons()),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    // Show up to 5 page numbers with the current page in the middle,
    // e.g. 3 4 [5] 6 7.
    final firstShown = max(1, min(page - 2, totalPages - 4));
    final lastShown = min(totalPages, firstShown + 4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Previous page',
          onPressed: page > 1 ? () => onPageSelected(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        for (var number = firstShown; number <= lastShown; number++)
          _PageNumberButton(
            number: number,
            isCurrent: number == page,
            onTap: () => onPageSelected(number),
          ),
        IconButton(
          tooltip: 'Next page',
          onPressed: page < totalPages ? () => onPageSelected(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

// One round page number. The current page is filled in.
class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.number,
    required this.isCurrent,
    required this.onTap,
  });

  final int number;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Semantics(
        label: 'Page $number',
        selected: isCurrent,
        child: Material(
          color: isCurrent ? colors.primary : Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: isCurrent ? null : onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent ? colors.onPrimary : colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
