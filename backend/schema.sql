-- Kindling starter schema for Supabase/PostgreSQL.
-- Review and split into timestamped migrations before production deployment.

create extension if not exists pgcrypto;

create type public.idea_lifecycle as enum
  ('captured', 'analyzed', 'validating', 'planning', 'building', 'launched');
create type public.idea_decision as enum
  ('explore', 'validate', 'pursue', 'watch', 'pause');
create type public.job_status as enum
  ('queued', 'running', 'completed', 'failed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  stage text not null default '',
  challenges text[] not null default '{}',
  business_type text not null default '',
  team_size text not null default '',
  experience text not null default '',
  goals text[] not null default '{}',
  time_available text not null default '',
  budget_comfort text not null default '',
  decision_style text not null default '',
  discovery_source text not null default '',
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.ideas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 240),
  summary text not null default '',
  customer text not null default '',
  problem text not null default '',
  business_model text not null default '',
  category text not null default 'Not sure yet',
  viability_score smallint check (viability_score between 0 and 100),
  founder_fit smallint check (founder_fit between 0 and 100),
  entry_difficulty smallint check (entry_difficulty between 0 and 100),
  competitor_count integer check (competitor_count >= 0),
  market_direction text not null default 'unknown'
    check (market_direction in ('up', 'flat', 'down', 'unknown')),
  lifecycle public.idea_lifecycle not null default 'captured',
  validation_progress smallint not null default 0
    check (validation_progress between 0 and 100),
  business_plan_progress smallint not null default 0
    check (business_plan_progress between 0 and 100),
  decision public.idea_decision not null default 'explore',
  accent text not null default 'orange'
    check (accent in ('coral', 'blue', 'orange', 'green', 'pink')),
  version integer not null default 1 check (version >= 1),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);
create index ideas_user_updated_idx on public.ideas(user_id, updated_at desc);

create table public.analysis_jobs (
  id uuid primary key default gen_random_uuid(),
  idea_id uuid not null references public.ideas(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status public.job_status not null default 'queued',
  model_version text,
  input_snapshot jsonb not null default '{}',
  output jsonb,
  error_code text,
  error_message text,
  created_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz,
  updated_at timestamptz not null default now()
);

create table public.sources (
  id uuid primary key default gen_random_uuid(),
  analysis_job_id uuid references public.analysis_jobs(id) on delete cascade,
  idea_id uuid not null references public.ideas(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  url text not null,
  title text not null,
  publisher text,
  summary text,
  retrieved_at timestamptz not null,
  created_at timestamptz not null default now()
);

create table public.validation_experiments (
  id uuid primary key default gen_random_uuid(),
  idea_id uuid not null references public.ideas(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  title text not null,
  hypothesis text not null,
  status text not null default 'draft'
    check (status in ('draft', 'active', 'completed', 'cancelled')),
  target_metric text,
  target_value numeric,
  started_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.validation_evidence (
  id uuid primary key default gen_random_uuid(),
  experiment_id uuid not null references public.validation_experiments(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  evidence_type text not null check (evidence_type in ('qualitative', 'quantitative')),
  metric_name text,
  numeric_value numeric,
  text_value text,
  notes text,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.business_plans (
  id uuid primary key default gen_random_uuid(),
  idea_id uuid not null unique references public.ideas(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  executive_summary text not null default '',
  target_customer text not null default '',
  positioning text not null default '',
  revenue_model text not null default '',
  go_to_market text not null default '',
  operations text not null default '',
  financial_plan text not null default '',
  risks text not null default '',
  milestones text not null default '',
  completed_sections text[] not null default '{}',
  version integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.market_updates (
  id uuid primary key default gen_random_uuid(),
  idea_id uuid not null references public.ideas(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('positive', 'negative', 'opportunity', 'neutral')),
  signal text not null,
  impact text not null,
  recommended_move text not null,
  score_delta integer not null default 0,
  confidence smallint check (confidence between 0 and 100),
  deduplication_key text,
  occurred_at timestamptz not null,
  created_at timestamptz not null default now(),
  unique (user_id, deduplication_key)
);

create table public.market_update_sources (
  market_update_id uuid not null references public.market_updates(id) on delete cascade,
  source_id uuid not null references public.sources(id) on delete cascade,
  primary key (market_update_id, source_id)
);

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  idea_id uuid references public.ideas(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  text text not null,
  insight text,
  action text,
  signal text check (signal in ('risk', 'action', 'opportunity', 'research', 'personal', 'change')),
  provider_message_id text,
  token_usage jsonb,
  created_at timestamptz not null default now()
);

-- Enable RLS. Each policy uses auth.uid() and must be regression-tested.
alter table public.profiles enable row level security;
alter table public.ideas enable row level security;
alter table public.analysis_jobs enable row level security;
alter table public.sources enable row level security;
alter table public.validation_experiments enable row level security;
alter table public.validation_evidence enable row level security;
alter table public.business_plans enable row level security;
alter table public.market_updates enable row level security;
alter table public.market_update_sources enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;

create policy profiles_owner_all on public.profiles
  for all using (id = auth.uid()) with check (id = auth.uid());

create policy ideas_owner_all on public.ideas
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy analysis_jobs_owner_all on public.analysis_jobs
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy sources_owner_all on public.sources
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy validation_experiments_owner_all on public.validation_experiments
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy validation_evidence_owner_all on public.validation_evidence
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy business_plans_owner_all on public.business_plans
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy market_updates_owner_all on public.market_updates
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy market_update_sources_owner_select on public.market_update_sources
  for select using (
    exists (
      select 1 from public.market_updates mu
      where mu.id = market_update_id and mu.user_id = auth.uid()
    )
  );

create policy conversations_owner_all on public.conversations
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy messages_owner_all on public.messages
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Production hardening still required:
-- 1. Add updated_at/version triggers.
-- 2. Prevent clients from directly writing computed analysis fields.
-- 3. Restrict service-only insert/update operations with separate functions.
-- 4. Add storage-bucket policies for evidence and export files.
-- 5. Add RLS tests proving cross-user isolation on every table.

