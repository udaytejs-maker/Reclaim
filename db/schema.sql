create extension if not exists "pgcrypto";

create table users (
  id uuid primary key default gen_random_uuid(),
  first_name text not null,
  last_name text not null,
  email text not null unique,
  phone text,
  birth_year int,
  current_state text,
  prior_states text[] default '{}',
  ssn_token text,
  consent_terms_at timestamptz,
  consent_privacy_at timestamptz,
  consent_finder_at timestamptz,
  consent_comms_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table payment_methods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  processor text not null default 'stripe',
  token text not null,
  brand text, last4 text, exp text,
  is_default boolean not null default true,
  created_at timestamptz not null default now()
);

create table finds (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  source text not null, source_kind text not null,
  jurisdiction text not null, property_type text not null,
  holder text, amount numeric(12,2), est_range text,
  fee_cap int not null, pay_to text not null default 'either',
  ach boolean not null default false,
  reported_year int, confidence text,
  status text not null default 'found',
  created_at timestamptz not null default now()
);

create table claims (
  id uuid primary key default gen_random_uuid(),
  find_id uuid not null references finds(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  authorized_at timestamptz not null default now(),
  auth_ref text, poa_signed boolean not null default false,
  filed_at timestamptz, paid_at timestamptz,
  confirmed_amount numeric(12,2)
);

create table invoices (
  id text primary key,
  user_id uuid not null references users(id),
  claim_id uuid references claims(id),
  jurisdiction text, property_type text,
  gross numeric(12,2) not null, fee_rate numeric(5,4) not null,
  fee numeric(12,2) not null, tax numeric(12,2) not null default 0,
  net numeric(12,2) not null, pay_to text, charge_ref text,
  created_at timestamptz not null default now()
);

create table messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete set null,
  channel text not null, to_addr text not null,
  subject text, body text not null,
  sent_at timestamptz not null default now(),
  provider_id text
);

create table disclosure_rules (
  code text primary key, agency text not null, url text,
  missing_money boolean not null default true,
  wait_months int not null default 0,
  need_amount boolean not null default true,
  need_direct boolean not null default true,
  allow_unsolicited boolean not null default true,
  notes text, updated_at timestamptz not null default now()
);

create index on finds(user_id);
create index on claims(user_id);
create index on invoices(user_id);
create index on messages(user_id);

create or replace function touch_updated_at() returns trigger as $$
begin new.updated_at = now(); return new; end;
$$ language plpgsql;
create trigger users_touch before update on users
  for each row execute function touch_updated_at();
