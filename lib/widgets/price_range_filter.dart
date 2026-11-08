import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_filter.dart';
import '../providers/filter_provider.dart';
import '../providers/products_provider.dart';

// The price range slider. Customers drag the two handles to only see the
// books between those two prices.
class PriceRangeFilter extends ConsumerStatefulWidget {
  const PriceRangeFilter({super.key});

  @override
  ConsumerState<PriceRangeFilter> createState() => _PriceRangeFilterState();
}

class _PriceRangeFilterState extends ConsumerState<PriceRangeFilter> {
  // The handles' position while the customer is dragging. The filter (and
  // the Supabase query) only changes when they let go, so a query isn't sent
  // for every tiny move.
  RangeValues? _dragValues;

  String _peso(double value) => '₱${value.round()}';

  void _applyRange(RangeValues values, PriceSliderScale scale) {
    setState(() => _dragValues = null);
    // A handle pushed all the way to its end means "no limit" on that side,
    // so books added later that are cheaper or pricier still show up.
    ref
        .read(productFilterProvider.notifier)
        .setPriceRange(
          values.start <= scale.lowest ? null : values.start,
          values.end >= scale.highest ? null : values.end,
        );
  }

  @override
  Widget build(BuildContext context) {
    final bounds = ref.watch(priceBoundsProvider).value;
    final filter = ref.watch(productFilterProvider);

    // Nothing to show while loading, after an error, or with no books.
    if (bounds == null) return const SizedBox.shrink();

    final scale = PriceSliderScale.fromBounds(bounds);
    final values = scale.clampValues(
      _dragValues ??
          RangeValues(
            filter.minPrice ?? scale.lowest,
            filter.maxPrice ?? scale.highest,
          ),
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26211E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                // On narrow phones or with big text, the title gets
                // shortened ("Price Ra...") and the range shrinks a little,
                // instead of running off the screen.
                Expanded(
                  child: Text(
                    'Price Range',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_peso(values.start)} – ${_peso(values.end)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (filter.hasPriceRange)
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => ref
                        .read(productFilterProvider.notifier)
                        .clearPriceRange(),
                    child: const Text('Reset'),
                  )
                else
                  const SizedBox(width: 10),
              ],
            ),
          ),
          SliderTheme(
            // Hide the little dots for every step, there can be up to 40.
            data: SliderTheme.of(context).copyWith(
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
            ),
            child: RangeSlider(
              min: scale.lowest,
              max: scale.highest,
              divisions: scale.divisions,
              values: values,
              labels: RangeLabels(_peso(values.start), _peso(values.end)),
              semanticFormatterCallback: _peso,
              onChanged: (newValues) => setState(() => _dragValues = newValues),
              onChangeEnd: (newValues) => _applyRange(newValues, scale),
            ),
          ),
        ],
      ),
    );
  }
}

// The two ends of the slider, rounded out to a tidy step.
// Example: books from ₱299 to ₱699 give a ₱290 – ₱700 slider that moves in
// ₱10 steps.
class PriceSliderScale {
  const PriceSliderScale({
    required this.lowest,
    required this.highest,
    required this.step,
  });

  factory PriceSliderScale.fromBounds(PriceBounds bounds) {
    final step = _pickStep(bounds.max - bounds.min);
    final lowest = (bounds.min / step).floor() * step;
    var highest = (bounds.max / step).ceil() * step;
    // Every book has the same price: still give the slider some room.
    if (highest <= lowest) highest = lowest + step;
    return PriceSliderScale(lowest: lowest, highest: highest, step: step);
  }

  final double lowest;
  final double highest;
  final double step;

  // How many steps the slider has from end to end.
  int get divisions => ((highest - lowest) / step).round();

  // Keeps both handles on the slider. Needed because the slider's ends can
  // move after a book is edited or deleted.
  RangeValues clampValues(RangeValues values) {
    final start = values.start.clamp(lowest, highest).toDouble();
    final end = values.end.clamp(start, highest).toDouble();
    return RangeValues(start, end);
  }

  // The smallest tidy step that gives the slider 40 steps or fewer.
  static double _pickStep(double priceRange) {
    const tidySteps = [1.0, 5.0, 10.0, 25.0, 50.0, 100.0, 250.0, 500.0, 1000.0];
    for (final step in tidySteps) {
      if (priceRange / step <= 40) return step;
    }
    return (priceRange / 40).ceilToDouble();
  }
}
