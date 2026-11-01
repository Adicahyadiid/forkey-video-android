-- FORKEY VIDEO: secure starter database setup
-- Run this entire script in Supabase Dashboard > SQL Editor > New query.
-- Review before running. Do not expose service_role keys in an Android app.

create extension if not exists pgcrypto;

-- 1) Profiles: one profile per authenticated account.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Pengguna',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2) Wallet: free and paid coins are separate.
create table if not exists public.wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  free_coins bigint not null default 0 check (free_coins >= 0),
  paid_coins bigint not null default 0 check (paid_coins >= 0),
  updated_at timestamptz not null default now()
);

-- 3) Immutable transaction ledger.
create table if not exists public.coin_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  bucket text not null check (bucket in ('free','paid')),
  amount bigint not null check (amount <> 0),
  reason text not null,
  reference_id text,
  created_at timestamptz not null default now()
);

-- 4) Private administrator registry.
-- Only the database owner/service role should manage this table.
create table if not exists public.private_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- 5) Enable Row Level Security on every user-facing table.
alter table public.profiles enable row level security;
alter table public.wallets enable row level security;
alter table public.coin_ledger enable row level security;
alter table public.private_admins enable row level security;

-- Remove potentially permissive policies from previous experiments.
drop policy if exists "profile_select_own" on public.profiles;
drop policy if exists "wallet_select_own" on public.wallets;
drop policy if exists "ledger_select_own" on public.coin_ledger;
drop policy if exists "profiles read own" on public.profiles;
drop policy if exists "wallet read own" on public.wallets;
drop policy if exists "ledger read own" on public.coin_ledger;

create policy "profile_select_own"
on public.profiles for select to authenticated
using (auth.uid() = id);

create policy "wallet_select_own"
on public.wallets for select to authenticated
using (auth.uid() = user_id);

create policy "ledger_select_own"
on public.coin_ledger for select to authenticated
using (auth.uid() = user_id);

-- Intentionally no client INSERT/UPDATE/DELETE policies for wallets,
-- coin_ledger, or private_admins. This prevents clients from minting coins
-- or granting themselves administrator privileges.

-- 6) Create profile and wallet automatically when a new Auth user signs up.
create or replace function public.handle_new_forkey_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), 'Pengguna')
  )
  on conflict (id) do nothing;

  insert into public.wallets (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_forkey on auth.users;
create trigger on_auth_user_created_forkey
after insert on auth.users
for each row execute procedure public.handle_new_forkey_user();

-- 7) Helper to check administrator status.
-- The private_admins table has RLS enabled and no user-facing policies.
create or replace function public.is_forkey_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.private_admins a
    where a.user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_forkey_admin() from public;
grant execute on function public.is_forkey_admin() to authenticated;

-- IMPORTANT: after creating/signing up your own account, make yourself admin:
-- 1. Open Authentication > Users and copy YOUR user UUID.
-- 2. Replace YOUR_AUTH_USER_UUID below with that UUID (keep the single quotes).
-- 3. Run only this INSERT in SQL Editor as project owner.
--
-- insert into public.private_admins (user_id)
-- values ('YOUR_AUTH_USER_UUID')
-- on conflict (user_id) do nothing;

-- For now, do not enable public storage buckets or payment endpoints.
-- Video uploads, paid coin top-ups, gift transfers, and live streaming need
-- server-side authorization, moderation, payment-webhook verification,
-- rate limiting, and appropriate privacy/legal policies before launch.
