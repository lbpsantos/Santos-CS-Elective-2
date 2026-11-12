# my_first_flutter_ui

A book shop app built with Flutter, Supabase and Riverpod.

## Final Project: E-Commerce App

Two roles. **Admins** manage the books, the genres and the orders.
**Customers** browse, filter, fill a cart, check out and see their orders.
The project manual's `categories` table is the `genres` table here, because
the products are books.

| Requirement | Where |
| --- | --- |
| Email/password + Google sign-in, profile row, auth gate | `auth_service.dart`, `handle_new_user` trigger, `app_router.dart` |
| Role gate (admin vs customer pages) | `app_router.dart`, `isAdminProvider` |
| Admin: add / edit / delete books (with stock and cover upload) | `product_form_screen.dart`, Edit / Delete on each card |
| Admin: genres (categories) | `admin_genres_screen.dart` |
| Admin: all orders, change status | `admin_orders_screen.dart` |
| Customer: search, genre, price filter, pages | home screen (from the last activity) |
| Customer: cart with stock limits | `cart_provider.dart`, `cart_screen.dart` |
| Checkout (one transaction, prices from the database) | `place_order()` in `supabase/final_project.sql` |
| Order confirmation and history | `checkout_confirmation_screen.dart`, `order_history_screen.dart` |
| RLS on every table | `supabase/final_project.sql`, section 6 |

### Layers

Screens call **providers** (`lib/providers`), providers call **services**
(`lib/services`), and only the services talk to Supabase. No file in
`lib/screens` or `lib/widgets` uses the Supabase client.

### Why hiding a button is not security

The app hides Add / Edit / Delete from customers, but the app runs on the
customer's device with the public anon key. Anyone could send their own
request to Supabase. The **RLS policies** decide what each request may do,
using `auth.uid()` from the access token and `is_admin()`. So a customer's
"delete book" request is refused by Postgres even if the button is shown.
Checkout works the same way: the app only sends book ids and quantities to
`place_order()`, which reads the real prices and stock from the database,
lowers the stock and saves the order and its items in one transaction.

### Setup in the Supabase Dashboard

1. **SQL Editor:** run `supabase/products.sql` (if not done yet), then
   `supabase/final_project.sql`. The second file adds the roles, profiles,
   orders and order_items tables, the stock column, the functions, every RLS
   policy and the `product-images` storage bucket. It also works with the
   tables made in the lesson and is safe to run again. Don't run the old
   `supabase/auth.sql` after it. If you run `products.sql` again later, run
   `final_project.sql` again too.
2. **Make an admin:** register in the app, then run this in the SQL Editor
   with your email, and log out and in again:

   ```sql
   update public.profiles
   set role_id = (select id from public.roles where role = 'admin')
   where email = 'you@example.com';
   ```

3. **Google login:**
   - In **Google Cloud Console -> APIs & Services -> Credentials**, create an
     **OAuth client ID** of type **Web application**. Under **Authorized
     redirect URIs** add the Callback URL from Supabase's Google provider
     page (`https://<project-ref>.supabase.co/auth/v1/callback`).
   - In **Supabase -> Authentication -> Sign In / Providers -> Google**, turn
     it on and paste the Client ID and Client Secret.
   - The redirect URLs from the Authentication activity below
     (`http://localhost:3000/**`) are still needed.
4. Run on the fixed port: `flutter run -d chrome --web-port 3000`

Run the tests with `flutter test`. They use fake services, so they work
without a database.

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
4. Set up authentication (next section), then run the app on a fixed port so
   the GitHub login can come back to it:
   `flutter run -d chrome --web-port 3000`

Run the tests with `flutter test`. They use a fake Supabase, so they work
without a database.

## Authentication activity

- **Log in / Register pages** with email and password (Supabase Auth).
- **3rd-party provider: GitHub** ("Continue with GitHub").
- **Route guard:** logged-out users only see the login and register pages.
- **Sessions and tokens:** logging in gives the app a session with a
  short-lived access token (sent with every request) and a refresh token
  (used to get a new access token). supabase_flutter saves the session on the
  device and refreshes the access token by itself, so users stay logged in.
  The tokens are never shown on screen.
- **My Account page** (tap your picture on the home screen): name, email,
  login method (email or GitHub) and Sign Out.
- **Database policies:** `supabase/auth.sql` only lets logged-in users
  (requests with an access token) add, edit and delete books.

| File | What it does |
| --- | --- |
| `lib/services/auth_service.dart` | All Supabase Auth calls |
| `lib/providers/auth_provider.dart` | The current session (null = logged out) |
| `lib/routing/app_router.dart` | Sends logged-out users to the login page |
| `lib/screens/login_screen.dart`, `register_screen.dart` | Log in / register |
| `lib/screens/account_screen.dart` | Profile and sign out |
| `supabase/auth.sql` | Only logged-in users can change books |

### Setup in the Supabase Dashboard

1. **SQL Editor:** run `supabase/auth.sql` (after `products.sql`).
2. **Authentication -> URL Configuration:**
   - Site URL: `http://localhost:3000`
   - Redirect URLs: add `http://localhost:3000/**` and
     `io.supabase.shopapp://login-callback/` (Android).
3. **GitHub OAuth app:** on GitHub go to **Settings -> Developer settings ->
   OAuth Apps -> New OAuth App**:
   - Homepage URL: `http://localhost:3000`
   - Authorization callback URL: the **Callback URL** shown on Supabase's
     GitHub provider page (`https://<project-ref>.supabase.co/auth/v1/callback`)
   - Copy the **Client ID**, then **Generate a new client secret**.
4. **Authentication -> Sign In / Providers -> GitHub:** turn it on, paste the
   Client ID and Client Secret, and save.
5. Optional for testing: **Sign In / Providers -> Email -> Confirm email**.
   When it is on, new accounts must click the link in the email before they
   can log in (Supabase's built-in email only sends a few emails per hour).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
