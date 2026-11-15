-- Run in Supabase SQL editor. New staff accounts are inactive until approved.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '', role text not null default 'salesperson' check(role in ('salesperson','manager','admin')),
 active boolean not null default false, created_at timestamptz not null default now());
create table if not exists public.coverage (
 id uuid primary key default gen_random_uuid(), street text not null, area text not null default '',
 salesperson text not null default '', installation_duration text not null default '', available boolean not null default true,
 latitude double precision, longitude double precision, updated_at timestamptz not null default now(),
 unique(street,area));
create table if not exists public.visits (
 id uuid primary key default gen_random_uuid(), assigned_to uuid not null references public.profiles(id),
 created_by uuid not null references public.profiles(id), customer_name text not null, customer_phone text,
 address text not null, scheduled_at timestamptz, status text not null default 'assigned' check(status in ('assigned','in_progress','completed','follow_up','cancelled')),
 notes text not null default '', checkin_lat double precision, checkin_lng double precision,
 checked_in_at timestamptz, created_at timestamptz not null default now());
create table if not exists public.location_sessions (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id),
 started_at timestamptz not null default now(), ended_at timestamptz);
create table if not exists public.location_updates (
 id bigint generated always as identity primary key, session_id uuid not null references public.location_sessions(id),
 user_id uuid not null references public.profiles(id), latitude double precision not null, longitude double precision not null,
 accuracy_m double precision, recorded_at timestamptz not null default now());
create index if not exists idx_visits_assigned on public.visits(assigned_to);
create index if not exists idx_location_updates_user_time on public.location_updates(user_id,recorded_at desc);
create index if not exists idx_coverage_street on public.coverage(street);
create or replace function public.my_role() returns text language sql stable security definer set search_path = public as $$
 select role from public.profiles where id=auth.uid() and active=true limit 1 $$;
create or replace function public.is_staff() returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles where id=auth.uid() and active=true) $$;
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
 begin insert into public.profiles(id,full_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name','')) on conflict(id) do nothing; return new; end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
alter table public.profiles enable row level security;
alter table public.coverage enable row level security;
alter table public.visits enable row level security;
alter table public.location_sessions enable row level security;
alter table public.location_updates enable row level security;
-- Explicit public coverage lookup: do not put private information in this table.
create policy "public read coverage" on public.coverage for select to anon,authenticated using(true);
create policy "admin manage coverage" on public.coverage for all to authenticated using(public.my_role()='admin') with check(public.my_role()='admin');
create policy "staff see profiles" on public.profiles for select to authenticated using(public.is_staff());
create policy "admin update profiles" on public.profiles for update to authenticated using(public.my_role()='admin') with check(public.my_role()='admin');
create policy "staff read relevant visits" on public.visits for select to authenticated using(public.is_staff() and (assigned_to=auth.uid() or public.my_role() in ('manager','admin')));
create policy "staff create visits" on public.visits for insert to authenticated with check(public.is_staff() and created_by=auth.uid() and (assigned_to=auth.uid() or public.my_role() in ('manager','admin')));
create policy "staff update visits" on public.visits for update to authenticated using(public.is_staff() and (assigned_to=auth.uid() or public.my_role() in ('manager','admin'))) with check(public.is_staff() and (assigned_to=auth.uid() or public.my_role() in ('manager','admin')));
create policy "own sessions read" on public.location_sessions for select to authenticated using(public.is_staff() and (user_id=auth.uid() or public.my_role() in ('manager','admin')));
create policy "own sessions start" on public.location_sessions for insert to authenticated with check(public.is_staff() and user_id=auth.uid() and ended_at is null);
create policy "own sessions end" on public.location_sessions for update to authenticated using(public.is_staff() and user_id=auth.uid()) with check(user_id=auth.uid());
create policy "own location or manager read" on public.location_updates for select to authenticated using(public.is_staff() and (user_id=auth.uid() or public.my_role() in ('manager','admin')));
create policy "own active session location insert" on public.location_updates for insert to authenticated with check(public.is_staff() and user_id=auth.uid() and exists(select 1 from public.location_sessions s where s.id=session_id and s.user_id=auth.uid() and s.ended_at is null));
-- IMPORTANT: Additional production hardening is recommended: server-side rate limiting,
-- restricted staff provisioning, audit trails, and retention/deletion jobs.
