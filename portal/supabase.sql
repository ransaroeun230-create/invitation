-- Run this once in Supabase → SQL Editor
create table if not exists public.profiles(
  id uuid primary key references auth.users(id) on delete cascade,
  email text, name text, avatar text, provider text,
  role text not null default 'customer' check (role in ('customer','admin')),
  plan text not null default 'free' check (plan in ('free','pro')),
  created_at timestamptz default now(), last_seen timestamptz default now());

create table if not exists public.invitations(
  id uuid primary key default gen_random_uuid(),
  owner uuid not null references auth.users(id) on delete cascade,
  title text not null, slug text unique not null, template text default 'Wedding Gold',
  active boolean default true, created_at timestamptz default now());

create table if not exists public.views(
  id bigint generated always as identity primary key,
  invitation_id uuid references public.invitations(id) on delete cascade,
  slug text, device text, referrer text, created_at timestamptz default now());

create or replace function public.is_admin() returns boolean language sql security definer set search_path=public stable
as $$ select exists(select 1 from profiles where id=auth.uid() and role='admin') $$;

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into profiles(id,email,name,avatar,provider) values(new.id,new.email,
    coalesce(new.raw_user_meta_data->>'full_name',new.raw_user_meta_data->>'name',split_part(new.email,'@',1)),
    new.raw_user_meta_data->>'avatar_url', new.raw_app_meta_data->>'provider') on conflict do nothing;
  return new; end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

-- customers cannot promote themselves or change plan
create or replace function public.protect_profile() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then new.role:=old.role; new.plan:=old.plan; end if;
  return new; end $$;
drop trigger if exists protect_profile_t on public.profiles;
create trigger protect_profile_t before update on public.profiles for each row execute function public.protect_profile();

alter table profiles enable row level security;
alter table invitations enable row level security;
alter table views enable row level security;

create policy "profile read" on profiles for select using (id=auth.uid() or public.is_admin());
create policy "profile update" on profiles for update using (id=auth.uid() or public.is_admin());
create policy "inv read" on invitations for select using (owner=auth.uid() or public.is_admin());
create policy "inv insert" on invitations for insert with check (owner=auth.uid());
create policy "inv update" on invitations for update using (owner=auth.uid() or public.is_admin());
create policy "inv delete" on invitations for delete using (owner=auth.uid() or public.is_admin());
create policy "views read" on views for select using (public.is_admin() or exists(select 1 from invitations i where i.id=invitation_id and i.owner=auth.uid()));
create policy "views insert" on views for insert to anon, authenticated with check (true);

-- After you sign in once with your own account, make yourself admin:
-- update public.profiles set role='admin' where email='YOUR_EMAIL_HERE';
