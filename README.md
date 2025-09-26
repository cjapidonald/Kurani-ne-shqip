# Kurani

Kurani është një aplikacion SwiftUI për iOS 17 që ofron një përvojë leximi të përkthimit shqip të Kuranit, menaxhimin e shënimeve në çdo ajet dhe integrimin me Supabase për autentikim dhe ruajtje të të dhënave. Projekti përdor MVVM, `NavigationStack`, `async/await` dhe një sistem ngjyrash të personalizuar.

## Kërkesat
- Xcode 15 ose më i ri
- iOS 17 për ekzekutim në pajisje ose simulator
- Swift 5.9+

## Konfigurimi i Supabase
1. **Krijo projektin Supabase** dhe shto paketën [`supabase-swift`](https://github.com/supabase-community/supabase-swift) në projekt nëpërmjet Swift Package Manager.
2. Kopjo skedarin `Config.xcconfig` në projekt dhe lidhe me target-in kryesor.
   - Plotëso `SUPABASE_URL` dhe `SUPABASE_ANON_KEY` me kredencialet nga Supabase.
3. Në Supabase SQL Editor ekzekuto skriptin në vijim për të krijuar tabelën e shënimeve dhe politikat e RLS:
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
4. Aktivizo ofruesit e autentikimit në Supabase: **Sign in with Apple** dhe **Email (magic link)**. Në panelin e Supabase > Authentication sigurohu që Apple Sign-In të ketë domain dhe redirect URL të konfiguruar sipas udhëzimeve.
5. Në Xcode, importo `Config.xcconfig` dhe konfiguro target-in për të lexuar çelësat e Supabase në Info.plist.
6. Përditëso Info.plist:
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
  QuranMeta.json, sample_translation.json, TranslationStore.swift
Supabase/
  SupabaseClientProvider.swift, AuthManager.swift, NotesStore.swift
ViewModels/
  LibraryViewModel.swift, ReaderViewModel.swift, NotesViewModel.swift, SettingsViewModel.swift
Views/
  RootView.swift, LibraryView.swift, SurahRow.swift, ReaderView.swift,
  NoteEditorView.swift, NotesView.swift, SettingsView.swift,
  Components/BrandHeader, Pill, GradientButton, ToastView, SignInPromptView
Utils/
  FileIO.swift, AppStorageKeys.swift, Haptics.swift, ShareSheet.swift
Resources/
  Assets.xcassets/ (ngjyrat e temës)
```

## Burimet e përfshira
- `QuranMeta.json`: metadata për të 114 suret (numri, emri në shqip, numri i ajeteve).
- `sample_translation.json`: përkthimi i plotë në shqip (Sherif Ahmeti) për të gjitha 114 suret, i marrë nga projekti [fawazahmed0/quran-api](https://github.com/fawazahmed0/quran-api) (licencë publike). Përdoret si përkthim i parazgjedhur në aplikacion.

Për të ngarkuar një përkthim të plotë, përdor `Importo përkthimin` në cilësime dhe zgjidh një skedar JSON me të njëjtën strukturë si shembulli i përfshirë.

## Ekzekutimi
1. Hap projektin në Xcode.
2. Sigurohu që skedarët `QuranMeta.json`, `sample_translation.json`, `Assets.xcassets` dhe `Config.xcconfig` janë pjesë e target-it.
3. Ndërto dhe ekzekuto aplikacionin në simulator ose pajisje me iOS 17.

## Sjellja e shënimeve
- Çdo përdorues mund të ruajë **një** shënim për çdo kombinim (sure, ajet).
- Ruajtja përdor `upsert` në Supabase dhe nuk ekziston asnjë veprim për fshirje.
- Shënimet duken në tab-in “Shënimet e mia” të grupuara sipas sures dhe mund të hapin lexuesin për përditësim.

## Licenca e përkthimit
Përkthimi i përfshirë (Sherif Ahmeti) është publikuar në projektin [quran-api](https://github.com/fawazahmed0/quran-api) nën licencë publike (Unlicense). Përkthimet e tjera të plota mund të jenë të mbrojtura nga të drejtat e autorit, ndaj përdoruesi duhet të importojë skedarët e vetë në përputhje me ligjin.
