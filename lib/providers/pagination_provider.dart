import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'filter_provider.dart';

// How many books one page shows (the activity asks for 6 to 8).
// 6 fills the grid evenly: 3 rows of 2 on phones, 2 rows of 3 on tablets.
const int productsPerPage = 6;

// Holds the page number the customer is on. The first page is 1.
class CurrentPageNotifier extends Notifier<int> {
  @override
  int build() {
    // Watching the filter makes this provider start over (back to page 1)
    // every time the filter changes. Page 3 of the old results might not
    // exist in the new results.
    ref.watch(productFilterProvider);
    return 1;
  }

  void goToPage(int page) {
    state = page < 1 ? 1 : page;
  }
}

final currentPageProvider = NotifierProvider<CurrentPageNotifier, int>(
  CurrentPageNotifier.new,
);
