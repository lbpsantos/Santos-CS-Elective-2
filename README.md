# my_first_flutter_ui

A book shop app built with Flutter, Supabase and Riverpod.

## Price Filter + Pagination activity

- **Price filtering:** the price range slider on the home screen narrows the
  book list. The range is sent to Supabase as `gte` / `lte` filters on `price`.
- **Pagination:** 6 books per page. Each page is loaded with a Supabase
  `.range(from, to)` query, plus `.count(CountOption.exact)` for the total.
  The page number and filters live in Riverpod providers.
- **Create / update / delete:** "Add Book" button, the ⋮ menu on each book
  card, and the Edit / Delete buttons on the book details page.
- **Filter:** search text, category chips, and a genre dropdown. The genres
  come from the `genres` table, and each book links to its genre with
  `products.genre_id` (all sent to Supabase).

| File | What it does |
| --- | --- |
| `lib/services/product_service.dart` | All Supabase queries |
| `lib/providers/filter_provider.dart` | Search, category, genre and price range |
| `lib/providers/pagination_provider.dart` | Current page (back to 1 when the filter changes) |
| `lib/providers/products_provider.dart` | Loads the current page; add / edit / delete |
| `lib/widgets/genre_filter.dart` | The genre dropdown |
| `lib/widgets/price_range_filter.dart` | The price slider |
| `lib/widgets/pagination_bar.dart` | The page buttons |
| `supabase/products.sql` | Genres and products tables, policies and 20 sample books |

## Supabase setup

1. Get the project URL and the public anon/publishable key from **Supabase
   Dashboard -> Project Settings -> API**.
2. Create a `.env` file in the project root using `.env.example` as a template:

   ```text
   SUPABASE_URL=https://your-project-ref.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

   The app loads this file before initializing Supabase. The real `.env` is
   ignored by Git, so credentials are not committed to the repository.
   Use only the public anon/publishable key in this Flutter client. Never put
   the service-role or other secret key in the app.
3. Open **Supabase Dashboard -> SQL Editor**, paste all of
   `supabase/products.sql` and click **Run**. It creates the `genres` and
   `products` tables, lets the app read them (and change the products), and
   adds 7 genres and 20 sample books (4 pages). Running it again does not
   duplicate anything. Add or rename genres in the Table Editor.
4. `flutter run`

Run the tests with `flutter test`. They use a fake Supabase, so they work
without a database.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
