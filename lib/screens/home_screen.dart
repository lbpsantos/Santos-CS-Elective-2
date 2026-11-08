import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../models/product_filter.dart';
import '../models/product_page.dart';
import '../providers/filter_provider.dart';
import '../providers/pagination_provider.dart';
import '../providers/products_provider.dart';
import '../responsive/mobile_scaffold.dart';
import '../responsive/responsive_layout.dart';
import '../responsive/tablet_scaffold.dart';
import '../services/product_service.dart';
import '../theme/app_them.dart';
import '../widgets/genre_filter.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/price_range_filter.dart';
import '../widgets/product_cover.dart';
import '../widgets/product_form_sheet.dart';

// HomeScreen shows the shop.
// The search text, category, price range and page number are kept in
// Riverpod providers (lib/providers). productsProvider watches them and loads
// the matching page of books from Supabase whenever one of them changes.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Waits until the customer stops typing before searching.
  Timer? _searchTimer;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Search once the customer stops typing for a moment, instead of sending a
  // Supabase query for every letter.
  void _onSearchChanged(String text) {
    setState(() {}); // show or hide the clear (x) button
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(productFilterProvider.notifier).setSearch(text);
    });
  }

  void _clearSearch() {
    _searchTimer?.cancel();
    _searchController.clear();
    ref.read(productFilterProvider.notifier).setSearch('');
    setState(() {});
  }

  void _clearAllFilters() {
    _searchTimer?.cancel();
    _searchController.clear();
    ref.read(productFilterProvider.notifier).clearAll();
  }

  void _goToPage(int page) {
    ref.read(currentPageProvider.notifier).goToPage(page);
    // Start the new page from the top.
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Pull down (or press Retry) to load everything from Supabase again.
  Future<void> _reload() async {
    ref.invalidate(genresProvider);
    ref.invalidate(priceBoundsProvider);
    ref.invalidate(featuredProductProvider);
    ref.invalidate(productsProvider);
    try {
      // Wait for the new books, so the refresh spinner stays until then.
      await ref.read(productsProvider.future);
    } catch (_) {
      // The error is already shown on the screen, with a Retry button.
    }
  }

  void _openDetails(Product product) {
    // Refresh the cart badge when coming back
    context.push('/details', extra: product).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filter = ref.watch(productFilterProvider);
    final productsAsync = ref.watch(productsProvider);
    // The page on screen. While the next page loads, the old one stays
    // (value keeps the last result). null before the first load or on error.
    final shownPage = productsAsync.hasError ? null : productsAsync.value;

    return Scaffold(
      appBar: _buildAppBar(theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showProductForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
      ),
      // Page buttons, always visible at the bottom
      bottomNavigationBar: shownPage == null || shownPage.totalCount == 0
          ? null
          : PaginationBar(
              page: shownPage.page,
              totalPages: shownPage.totalPages,
              onPageSelected: _goToPage,
            ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          // Room at the end so the Add Book button doesn't cover the books
          padding: const EdgeInsets.only(bottom: 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              _buildCategoryTabs(theme, isDark, filter.category),
              const SizedBox(height: 10),

              // Genre dropdown and Price Range Slider
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    GenreFilter(),
                    SizedBox(height: 8),
                    PriceRangeFilter(),
                  ],
                ),
              ),

              // Featured Spotlight Card (first page, nothing filtered)
              if (filter.isEmpty && shownPage?.page == 1)
                _buildSpotlight(theme, isDark),

              _buildResultsHeader(theme, productsAsync, filter),

              // Responsive Book Grid for the current page
              productsAsync.when(
                // Keep the current books on screen while the next page or a
                // new filter loads. The header shows a small spinner instead.
                skipLoadingOnReload: true,
                loading: () => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => _buildError(theme, error),
                data: (page) => page.products.isEmpty
                    ? _buildEmpty(theme, filter)
                    : ResponsiveLayout(
                        mobileBody: MobileScaffold(products: page.products),
                        tabletBody: TabletScaffold(products: page.products),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(
              Icons.person,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hello, Reader',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'What would you like to read?',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Light / Dark mode toggle button
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, themeMode, _) {
            final activeDark = themeMode == ThemeMode.dark;
            return IconButton(
              tooltip: activeDark ? 'Switch to Light' : 'Switch to Dark',
              icon: Icon(
                activeDark ? Icons.light_mode : Icons.dark_mode_outlined,
              ),
              onPressed: () {
                themeModeNotifier.value = activeDark
                    ? ThemeMode.light
                    : ThemeMode.dark;
              },
            );
          },
        ),
        // Cart action button with live item count badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'View Cart',
              icon: const Icon(Icons.shopping_bag_outlined),
              onPressed: () {
                // Refresh home screen badge when returning from cart
                context.push('/cart').then((_) => setState(() {}));
              },
            ),
            if (totalCartCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    '$totalCartCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search books by title or author...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: _clearSearch,
                )
              : null,
        ),
        onChanged: _onSearchChanged,
        // Pressing Enter searches right away
        onSubmitted: (text) {
          _searchTimer?.cancel();
          ref.read(productFilterProvider.notifier).setSearch(text);
        },
      ),
    );
  }

  // Horizontal Category Tabs
  Widget _buildCategoryTabs(
    ThemeData theme,
    bool isDark,
    BookCategory selectedCategory,
  ) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: BookCategory.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = BookCategory.values[index];
          final isSelected = selectedCategory == category;

          return GestureDetector(
            onTap: () =>
                ref.read(productFilterProvider.notifier).setCategory(category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? const Color(0xFF26211E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.white12 : Colors.black12),
                ),
              ),
              child: Center(
                child: Text(
                  category.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Featured Spotlight Card: the highest rated book in Supabase
  Widget _buildSpotlight(ThemeData theme, bool isDark) {
    final featured = ref.watch(featuredProductProvider).value;
    if (featured == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF332922), const Color(0xFF241D18)]
                : [const Color(0xFFF3ECE1), const Color(0xFFE8DFCE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '★ Top Rated',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    featured.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    featured.genre.isEmpty
                        ? featured.author
                        : '${featured.author} • ${featured.genre}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _openDetails(featured),
                    child: Row(
                      children: [
                        Text(
                          'Read More',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Spotlight Book Cover Image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 90,
                  child: ProductCover(
                    imageUrl: featured.imageUrl,
                    iconSize: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // "Showing 7–12 of 20 books", plus a spinner while loading and a button
  // to clear the filters.
  Widget _buildResultsHeader(
    ThemeData theme,
    AsyncValue<ProductPage> productsAsync,
    ProductFilter filter,
  ) {
    final page = productsAsync.hasError ? null : productsAsync.value;
    String summary = '';
    if (page != null) {
      summary = page.totalCount == 0
          ? 'No books found'
          : 'Showing ${page.firstItemNumber}–${page.lastItemNumber} of '
                '${page.totalCount} ${page.totalCount == 1 ? 'book' : 'books'}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(
              child: Text(
                summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Small spinner while the next page or a new filter loads
            if (productsAsync.isLoading && page != null)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (!filter.isEmpty)
              TextButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Clear filters'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme, Object error) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load the books',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              friendlyErrorMessage(error),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, ProductFilter filter) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              filter.isEmpty ? 'No books yet' : 'No books found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filter.isEmpty
                  ? 'Tap "Add Book" to add one, or run supabase/products.sql '
                        'to add the sample books.'
                  : 'Try another search, category, genre or price range.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (!filter.isEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
