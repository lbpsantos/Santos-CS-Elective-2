-- =====================================================================
-- Shop App: only logged-in users may add, edit or delete books
-- (Authentication activity)
--
-- Run this AFTER supabase/products.sql:
-- Supabase Dashboard -> SQL Editor -> New query -> paste -> Run.
-- It is safe to run more than once.
--
-- How it works: when the app is logged in, every request carries the
-- user's ACCESS TOKEN (a JWT). Supabase reads it and runs the request as
-- the "authenticated" role. Without a token the request runs as "anon".
-- The policies below only allow changes for the "authenticated" role.
-- =====================================================================

-- Reading books stays open to everyone (anon and authenticated).

-- Remove the old "anyone can change books" policies.
drop policy if exists "Anyone can add products" on public.products;
drop policy if exists "Anyone can update products" on public.products;
drop policy if exists "Anyone can delete products" on public.products;

-- Requests without a login can no longer change the table at all.
revoke insert, update, delete on public.products from anon;
grant insert, update, delete on public.products to authenticated;

drop policy if exists "Logged-in users can add products" on public.products;
create policy "Logged-in users can add products"
  on public.products for insert
  to authenticated
  with check (true);

drop policy if exists "Logged-in users can update products" on public.products;
create policy "Logged-in users can update products"
  on public.products for update
  to authenticated
  using (true)
  with check (true);

drop policy if exists "Logged-in users can delete products" on public.products;
create policy "Logged-in users can delete products"
  on public.products for delete
  to authenticated
  using (true);
