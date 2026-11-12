-- Выполните в Supabase: SQL Editor → New query → Run

create table if not exists public.attendance (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  first_name  text not null check (char_length(first_name) between 1 and 100),
  last_name   text not null check (char_length(last_name)  between 1 and 100),
  device_name text,
  user_agent  text,
  latitude    double precision,
  longitude   double precision,
  accuracy_m  double precision,
  place       text            -- метка точки из QR-кода (?place=...)
);

alter table public.attendance enable row level security;

-- Любой (анонимный) посетитель может только ДОБАВИТЬ запись
drop policy if exists "anon can insert" on public.attendance;
create policy "anon can insert"
  on public.attendance for insert
  to anon, authenticated
  with check (
    latitude  is not null and
    longitude is not null and
    accuracy_m is not null and
    accuracy_m <= 200          -- точность геолокации не хуже 200 м
  );

-- Читать записи могут только вошедшие администраторы
drop policy if exists "auth can read" on public.attendance;
create policy "auth can read"
  on public.attendance for select
  to authenticated
  using (true);

-- Живое обновление таблицы в админке (если выдаст "already member" — просто игнорируйте)
alter publication supabase_realtime add table public.attendance;

-- Удалять записи могут только вошедшие администраторы
drop policy if exists "auth can delete" on public.attendance;
create policy "auth can delete"
  on public.attendance for delete
  to authenticated
  using (true);
