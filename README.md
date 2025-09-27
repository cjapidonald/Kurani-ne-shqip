# Kurani

Kurani është një aplikacion SwiftUI për iOS 17 që ofron një përvojë leximi të përkthimit shqip të Kuranit, menaxhimin e shënimeve në çdo ajet dhe integrimin me Supabase për autentikim dhe ruajtje të të dhënave. Projekti përdor MVVM, `NavigationStack`, `async/await` dhe një sistem ngjyrash të personalizuar.

## Kërkesat
- Xcode 15 ose më i ri
- iOS 17 për ekzekutim në pajisje ose simulator
- Swift 5.9+

## Tipografia
- Aplikacioni përdor fontin "KG Primary Penmanship". Për arsye licence skedari
  `KGPrimaryPenmanship.ttf` nuk është i përfshirë në repo. Pas sigurimit të
  licencës, vendose skedarin në `Resources/Fonts/` përpara se të ndërtosh
  aplikacionin.

## Konfigurimi i Supabase
1. **Krijo projektin Supabase** dhe shto paketën [`supabase-swift`](https://github.com/supabase-community/supabase-swift) në projekt nëpërmjet Swift Package Manager (File > Add Packages… > paste URL-në).
2. Kopjo `Config.xcconfig` në një skedar të ri lokal (p.sh. `Config.local.xcconfig`) dhe mos e shto në git.
   - Vendos vlerat reale për `SUPABASE_URL` dhe `SUPABASE_ANON_KEY` në skedarin lokal.
   - Në Xcode cakto `Config.local.xcconfig` si **Base Configuration** për konfigurimet ku ndërtohet aplikacioni (lokalisht, në CI, e kështu me radhë). `Config.xcconfig` i versionuar në repo mbetet me placeholder-a.
3. `App/Info.plist` tashmë përmban çelësat që lexojnë këto variabla në runtime:
   ```xml
   <key>SUPABASE_URL</key>
   <string>$(SUPABASE_URL)</string>
   <key>SUPABASE_ANON_KEY</key>
   <string>$(SUPABASE_ANON_KEY)</string>
   ```
4. (Opsionale) Për të përdorur Supabase edhe në SwiftUI Previews, vendos variablën e ambientit `ENABLE_SUPABASE_PREVIEWS=1` për ta lejuar aplikacionin të përdorë të njëjtin konfigurim si në runtime.
5. Në Supabase SQL Editor ekzekuto skriptin në vijim për të krijuar tabelën e shënimeve dhe politikat e RLS:
   ```sql
   create table if not exists public.notes (
     id uuid primary key default gen_random_uuid(),
     user_id uuid not null,
     surah int not null check (surah between 1 and 114),
     ayah int not null check (ayah >= 1),
     text text not null check (length(text) > 0),
     updated_at timestamptz not null default now(),
     constraint unique_user_verse unique (user_id, surah, ayah)
   );

   alter table public.notes enable row level security;

   create policy "read own notes"
   on public.notes for select
   using ( auth.uid() = user_id );

   create policy "insert own note"
   on public.notes for insert
   with check ( auth.uid() = user_id );

   create policy "update own note"
   on public.notes for update
   using ( auth.uid() = user_id )
   with check ( auth.uid() = user_id );
   ```
6. Aktivizo ofruesit e autentikimit në Supabase: **Sign in with Apple** dhe **Email (magic link)**. Në panelin e Supabase > Authentication sigurohu që Apple Sign-In të ketë domain dhe redirect URL të konfiguruar sipas udhëzimeve.
7. Përditëso Info.plist:
   - `CFBundleDevelopmentRegion = sq`
   - `CFBundleDisplayName = Kurani`

## Struktura e projektit
```
App/
  KuraniApp.swift
  Theme.swift
Models/
  Surah.swift, Ayah.swift, Note.swift
Data/
  TranslationStore.swift, ArabicDictionary.json, ReadingProgressStore.swift
Supabase/
  SupabaseClientProvider.swift, AuthManager.swift, NotesStore.swift, TranslationService.swift
ViewModels/
  LibraryViewModel.swift, ReaderViewModel.swift, NotesViewModel.swift, SettingsViewModel.swift
Views/
  RootView.swift, LibraryView.swift, SurahRow.swift, ReaderView.swift,
  NoteEditorView.swift, NotesView.swift, SettingsView.swift,
  Components/BrandHeader, Pill, GradientButton, ToastView, SignInPromptView
Utils/
  AppStorageKeys.swift, Haptics.swift, ShareSheet.swift
Resources/
  Assets.xcassets/ (ngjyrat e temës)
```

## Burimet e jashtme
Lexuesi i Kuranit nuk përfshin më tekste të ngulitura lokalisht. Metadata, tekstet në arabisht dhe përkthimet në shqip do të tërhiqen përmes Supabase.

## Ekzekutimi
1. Hap projektin në Xcode.
2. Sigurohu që `Assets.xcassets` dhe `Config.xcconfig` janë pjesë e target-it.
3. Ndërto dhe ekzekuto aplikacionin në simulator ose pajisje me iOS 17.

## Zgjidhja e problemeve

### Gabim: `hapticpatternlibrary.plist` couldn't be opened

- Ky log shfaqet kur aplikacioni ekzekutohet në macOS ose në simulatorë pa motor haptik të disponueshëm.
- Gabimi nuk ndikon në funksionimin e aplikacionit; versioni aktual kontrollon automatikisht nëse pajisja mbështet haptikë dhe nuk tenton të prodhojë feedback kur mungon.
- Për të testuar feedback-un haptik, përdor një pajisje iOS me motor Taptic.

## Sjellja e shënimeve
- Çdo përdorues mund të ruajë **një** shënim për çdo kombinim (sure, ajet).
- Ruajtja përdor `upsert` në Supabase dhe nuk ekziston asnjë veprim për fshirje.
- Shënimet duken në tab-in “Shënimet e mia” të grupuara sipas sures dhe mund të hapin lexuesin për përditësim.

## Licenca e përkthimit
Përkthimet dhe tekstet në arabisht do të merren nga Supabase sipas konfigurimit që siguron përdoruesi i aplikacionit.
