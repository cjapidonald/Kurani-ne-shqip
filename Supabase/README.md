# Supabase setup for Notes and Favourites

This project expects two Postgres tables that are secured with row level security (RLS) and owned by the authenticated user: `notes` for per-ayah notes and `favourites` for bookmarking ayat. The sections below walk you through creating them in Supabase.

## 1. Enable extensions

```sql
create extension if not exists "uuid-ossp";
```

The tables below use `uuid_generate_v4()` for their primary keys.

## 2. `notes` table

```sql
create table if not exists public.notes (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references auth.users (id) on delete cascade,
    surah integer not null,
    ayah integer not null,
    text text not null,
    updated_at timestamptz not null default timezone('utc'::text, now()),
    constraint notes_user_surah_ayah_unique unique (user_id, surah, ayah)
);
```

```sql
create index if not exists notes_user_surah_idx on public.notes (user_id, surah, ayah);
```

### Row Level Security

```sql
alter table public.notes enable row level security;
```

```sql
create policy "Individuals can manage their notes" on public.notes
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);
```

This aligns with the app logic in `NotesStore` which upserts a single note per user/surah/ayah combination.

## 3. `favourites` table

```sql
create table if not exists public.favourites (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references auth.users (id) on delete cascade,
    surah integer not null,
    ayah integer not null,
    created_at timestamptz not null default timezone('utc'::text, now()),
    constraint favourites_user_surah_ayah_unique unique (user_id, surah, ayah)
);
```

```sql
create index if not exists favourites_user_surah_idx on public.favourites (user_id, surah, ayah);
```

### Row Level Security

```sql
alter table public.favourites enable row level security;
```

```sql
create policy "Individuals can manage their favourites" on public.favourites
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);
```

With this schema the app can:

- Read every user's own notes and favourites.
- Upsert notes so that one record exists per ayah for each user.
- Toggle favourites by inserting or deleting records tied to the authenticated user.

After running the SQL above, the `SupabaseClientProvider` will be able to connect using the `SUPABASE_URL` and `SUPABASE_ANON_KEY` entries defined in your app's `Info.plist` or build settings.

## 4. iOS authentication configuration

To use the new `AuthService` helpers you need to configure a redirect URL and the platform capabilities required by Sign in with Apple and Google OAuth flows.

### Info.plist keys

- `SUPABASE_REDIRECT_URL`: the custom scheme Supabase should redirect to after OAuth completes (for example `io.supabase.kurani://auth/callback`).
- `CFBundleURLTypes`: register the same scheme so iOS can hand the callback URL back to the app. A minimal entry looks like:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>SupabaseAuth</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.supabase.kurani</string>
    </array>
  </dict>
</array>
<key>SUPABASE_REDIRECT_URL</key>
<string>io.supabase.kurani://auth/callback</string>
```

Make sure the same redirect URL is allowed in your Supabase project's Authentication settings (`Authentication → URL Configuration`).

### Capabilities and entitlements

- **Sign in with Apple**: add the "Sign In with Apple" capability to the target. Xcode will create the `com.apple.developer.applesignin` entitlement automatically.
- **Google OAuth**: no additional entitlements are required when using Supabase's PKCE flow, but the redirect scheme above must be registered so `ASWebAuthenticationSession` can return control to the app.
