# AnkhLens — Project Setup Package

This is the initial scaffold matching `ANKHLENS_ARCHITECTURE.md`: folder
structure, the Drift/SQLite schema (dictionary, cartouches, scan history,
agency/itinerary), and the phonetic cartouche engine boilerplate.

## 1. Create the Flutter project (skip if already created)

```bash
flutter create --org com.yourcompany ankhlens
cd ankhlens
```

## 2. Scaffold the folder structure

Copy `setup_structure.sh` into your project root, then:

```bash
chmod +x setup_structure.sh
./setup_structure.sh
```

## 3. Add dependencies

Merge the contents of `pubspec_dependencies_snippet.yaml` into your
project's `pubspec.yaml`, then:

```bash
flutter pub get
```

Also add the asset declarations to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/data/
    - assets/images/signs/
    - assets/audio/signs/
```

## 4. Copy in the provided source files

Copy this package's `lib/` and `test/` contents into your project's `lib/`
and `test/` at matching paths, and `assets/data/phoneme_to_sign_map.json`
into your project's `assets/data/`.

You'll still need to create `assets/data/signs_v1.json` — the seed file for
the 200+-sign dictionary (`app_database.dart`'s `seedDictionaryIfNeeded`
expects this shape per entry):

```json
[
  {
    "gardiner_code": "G17",
    "category_code": "G",
    "unicode_glyph": "𓅓",
    "transliteration": "m",
    "approx_pronunciation": "mm",
    "literal_meaning": "owl",
    "cultural_meaning": "...",
    "historical_context": "...",
    "phonetic_value": "m",
    "sign_type": "uniliteral",
    "image_asset_path": "assets/images/signs/g17.png",
    "audio_asset_path": "assets/audio/signs/g17.mp3"
  }
]
```

## 5. Generate Drift/Riverpod code

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `app_database.g.dart`, `sign_dao.g.dart`, `history_dao.g.dart`,
and `agency_dao.g.dart` next to their source files — required before the
project will compile.

## 6. Run the phonetic engine tests

```bash
flutter test test/features/cartouche_maker/phonetics/cartouche_engine_test.dart
```

These pin the G2P → normalization → sign-mapping pipeline behavior with a
small in-memory mapping table, independent of the real
`phoneme_to_sign_map.json` (which still needs Egyptology consultant review
per architecture doc §9 before it's production content).

## What's intentionally NOT included here

- The camera/ML scanning pipeline (Phase 3 in the architecture doc's build
  order) — this package covers Phases 1 (foundation/DB) and the cartouche
  engine's data-layer piece of Phase 4.
- The real 200+-sign dictionary content and the reviewed
  `phoneme_to_sign_map.json` biliteral table — both are content workstreams,
  not code.
- Presentation-layer widgets (screens/UI) — the DAOs and engine above are
  provider-exposed and ready for a UI layer to consume, but no screens are
  scaffolded yet.

## Suggested next step

Say the word and I'll build the **Manual Glyph Selector** end-to-end
(Phase 2 in the architecture doc) — it's the fastest path to a running,
testable app before any ML model is wired in.
