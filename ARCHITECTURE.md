# AnkhLens — Technical Architecture & Implementation Plan

**Version:** 1.0 (Foundation Architecture)
**Scope covered:** Product vision, CV/ML pipeline, offline-first data architecture, phonetic cartouche engine, Flutter module structure, testing, and white-label roadmap.

---

## 1. System Overview

AnkhLens is a Flutter mobile app with three cooperating subsystems:

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation Layer                    │
│   Camera Scan UI · Glyph Detail UI · Cartouche Maker UI ·     │
│   Dictionary Browser · Itinerary · Agency/Guide Contact       │
├─────────────────────────────────────────────────────────────┤
│                        Domain Layer                           │
│   Entities · Use Cases · Repository Interfaces                │
├─────────────────────────────────────────────────────────────┤
│                          Data Layer                            │
│  ┌───────────────┐  ┌────────────────┐  ┌──────────────────┐ │
│  │  ML Inference  │  │  Local DB       │  │  Remote (opt-in) │ │
│  │  (TFLite)      │  │  (Drift/SQLite) │  │  (agency sync)   │ │
│  └───────────────┘  └────────────────┘  └──────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

Everything below the presentation layer is designed so the **core scanning/dictionary/cartouche experience never depends on network access**. Network is used only for optional sync (branding, itinerary updates, cloud-assisted high-accuracy scans for ambiguous glyphs).

---

## 2. Architecture Pattern: Feature-First Clean Architecture

Each feature is a self-contained module with its own `presentation/domain/data` split. Shared code lives in `core/`. This is what lets AnkhLens later become a white-label SaaS: a new agency build is a new **flavor** (build config) that swaps `core/branding` and `core/config`, not a different codebase.

### 2.1 Folder Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart                 # MaterialApp, theming, routing root
│   ├── router/                  # go_router config
│   └── di/                      # Riverpod provider composition root
│
├── core/
│   ├── config/                  # Flavor config (agency id, feature flags, branding)
│   ├── branding/                # White-label theme, logo, copy overrides
│   ├── localization/            # ARB files, offline i18n
│   ├── database/                # Drift database, migrations
│   ├── ml/                      # Shared TFLite runtime wrapper
│   ├── networking/              # Dio client, connectivity checks (optional-sync only)
│   ├── storage/                 # Secure storage, file/asset cache manager
│   ├── error/                   # Failure types, exception mapping
│   └── utils/
│
├── features/
│   ├── glyph_scanner/
│   │   ├── presentation/        # Camera screen, bounding-box overlay, result sheet
│   │   ├── domain/               # ScanGlyph use case, GlyphDetection entity
│   │   └── data/                  # CV pipeline repo impl, TFLite model bindings
│   │
│   ├── glyph_dictionary/
│   │   ├── presentation/        # Browse/search/filter UI, glyph detail page
│   │   ├── domain/                # GlyphSign entity, dictionary repo interface
│   │   └── data/                   # Drift DAOs, seed JSON importer
│   │
│   ├── cartouche_maker/
│   │   ├── presentation/         # Name input, preview, export/share UI
│   │   ├── domain/                 # NameToPhonemes, PhonemesToGlyphs use cases
│   │   └── data/                    # Phoneme rule engine, sign mapping table
│   │
│   ├── itinerary/
│   │   ├── presentation/
│   │   ├── domain/
│   │   └── data/                    # Local cache + optional agency sync
│   │
│   ├── agency_contact/
│   │   ├── presentation/
│   │   ├── domain/
│   │   └── data/
│   │
│   └── manual_glyph_selector/       # Fallback UI reused by scanner + cartouche maker
│
└── l10n/
```

### 2.2 State Management & DI

- **Riverpod** (not BLoC): the app has many small, independent, swappable data sources (ML result, DB query, connectivity) — Riverpod's provider composition and `ref.watch` dependency graph fits this better than BLoC's event/state ceremony, and it scales cleanly to feature modules without a DI framework on top (no need for `get_it` + BLoC + injectable stack).
- Providers are declared per-feature (`glyph_scanner_providers.dart`, etc.) and composed at `app/di/`.
- Repository interfaces live in `domain/`; implementations are injected via provider overrides — this is what makes a white-label build swap possible (e.g. override `ItineraryRepository` with an agency-specific implementation without touching feature code).

---

## 3. Offline Data Layer

### 3.1 Why Drift (SQLite) over Hive/Isar

- The dictionary is **relational**: signs ↔ categories ↔ phonetic values ↔ cartouche mappings ↔ localized text. Drift gives real joins, indices, and full-text search (`FTS5`) for the 200+-sign dictionary search — Hive/Isar would force manual denormalization.
- Drift supports typed migrations, which matters once agencies need seed-data updates pushed as DB migrations rather than app updates.
- Isar is justified only if we needed vector/embedding search on-device; we don't — glyph matching happens in the ML layer, not the DB layer.

### 3.2 Core Schema (simplified)

```sql
-- Canonical sign dictionary (seeded from JSON at first launch, versioned)
CREATE TABLE gardiner_signs (
  id INTEGER PRIMARY KEY,
  gardiner_code TEXT UNIQUE NOT NULL,      -- e.g. "G17"
  category_code TEXT NOT NULL,             -- Gardiner category, e.g. "G" (birds)
  unicode_glyph TEXT,                      -- Unicode Egyptian Hieroglyph char if available
  transliteration TEXT,                    -- e.g. "m"
  approx_pronunciation TEXT,               -- e.g. "mm" (owl sound convention)
  literal_meaning TEXT,
  cultural_meaning TEXT,
  historical_context TEXT,
  phonetic_value TEXT,                     -- uniliteral/biliteral/triliteral value, nullable (ideograms)
  sign_type TEXT NOT NULL,                 -- uniliteral | biliteral | triliteral | ideogram | determinative
  image_asset_path TEXT NOT NULL,
  audio_asset_path TEXT
);

CREATE TABLE sign_translations (          -- localized copy (en, ar, fr, ...)
  sign_id INTEGER REFERENCES gardiner_signs(id),
  locale TEXT NOT NULL,
  literal_meaning TEXT,
  cultural_meaning TEXT,
  historical_context TEXT,
  PRIMARY KEY (sign_id, locale)
);

CREATE VIRTUAL TABLE signs_fts USING fts5(
  gardiner_code, transliteration, literal_meaning, cultural_meaning,
  content='gardiner_signs', content_rowid='id'
);

-- Scan history (fully local, no PII leaves device unless user explicitly shares)
CREATE TABLE scan_history (
  id INTEGER PRIMARY KEY,
  sign_id INTEGER REFERENCES gardiner_signs(id),
  confidence REAL NOT NULL,
  image_thumbnail_path TEXT,
  scanned_at INTEGER NOT NULL
);

-- Cartouche generations (local only)
CREATE TABLE cartouche_generations (
  id INTEGER PRIMARY KEY,
  input_name TEXT NOT NULL,
  phoneme_breakdown TEXT NOT NULL,          -- JSON array, e.g. ["A","LEK","SAN","DER"]
  sign_sequence TEXT NOT NULL,              -- JSON array of gardiner_codes used
  rendered_asset_path TEXT,
  created_at INTEGER NOT NULL
);

-- Agency / white-label config (overwritten by sync when online)
CREATE TABLE agency_profile (
  id INTEGER PRIMARY KEY CHECK (id = 1),   -- singleton row
  agency_name TEXT,
  logo_asset_path TEXT,
  primary_color_hex TEXT,
  contact_phone TEXT,
  contact_whatsapp TEXT,
  guide_name TEXT,
  guide_photo_path TEXT
);

-- Itinerary, cached fully for offline access
CREATE TABLE itinerary_items (
  id INTEGER PRIMARY KEY,
  day_index INTEGER NOT NULL,
  site_name TEXT NOT NULL,
  scheduled_time TEXT,
  notes TEXT,
  related_sign_ids TEXT                     -- JSON array — "signs you'll see at this site"
);
```

### 3.3 Seeding & Versioning

- The 200+-sign dictionary ships as a bundled JSON asset (`assets/data/signs_v1.json`) and is imported into Drift on first launch (or on version bump), not hand-written as SQL — this keeps content editable by non-engineers (Egyptology consultants) without touching Dart code.
- A `content_version` table tracks the imported JSON schema/version so future app updates can ship `signs_v2.json` and migrate additively.
- Optional online sync (when an agency wants to push corrections or new sites) pulls a delta JSON and upserts — never required for core function.

---

## 4. Computer Vision / ML Pipeline

### 4.1 Pipeline Stages

```
Camera Frame
   │
   ▼
[1] Preprocessing        — resize/normalize, optional perspective correction
   │
   ▼
[2] Detection Model       — TFLite object detector → bounding boxes for glyph regions
   │                          (trained to find "glyph-like" regions on stone/papyrus, not yet classify)
   ▼
[3] Crop + Rectify        — per-box crop, deskew
   │
   ▼
[4] Classification Model — TFLite classifier per crop → Gardiner code + confidence
   │
   ▼
[5] Confidence Gate       — threshold decides UI state:
   │     ≥ 0.75  → show result directly
   │     0.4–0.75 → show top-3 candidates, let user confirm
   │     < 0.4   → route to Manual Glyph Selector
   ▼
[6] Metadata Lookup       — join classified Gardiner code against local Drift dictionary
```

### 4.2 Model Choices & Rationale

- **Detection:** a lightweight single-shot detector (e.g. a MobileNet-SSD or YOLO-nano variant exported to TFLite/ONNX) — optimized for small, dense, low-contrast glyph regions rather than general object detection. This is a **custom-trained model**, not an off-the-shelf one; hieroglyph datasets (e.g. adapted from Egyptological corpora) are required for training, which is outside app-code scope but must be tracked as a project workstream (see §9).
- **Classification:** a compact CNN (MobileNetV3-small class) fine-tuned on isolated Gardiner-sign crops, mapping to Gardiner codes. Kept separate from detection so each model can be retrained/improved independently and so classification can also be invoked directly on a user-cropped region from the Manual Glyph Selector.
- **Runtime:** TensorFlow Lite over ONNX Runtime Mobile — better first-class Flutter plugin support (`tflite_flutter`), smaller footprint, and simpler quantization tooling (int8) for on-device speed on mid-range tourist phones.
- Both models ship bundled in the app (not downloaded) so scanning works from first launch with zero connectivity — this is a hard offline-first requirement, so model size/quantization budget (~10–20MB combined, int8) is a first-class constraint on model selection, not an afterthought.

### 4.3 Manual Fallback

The Manual Glyph Selector is not a "failure state" UI bolt-on — it's a first-class feature reusing the same dictionary browser (filter by shape category, e.g. birds/reptiles/human forms/geometric) so a tourist can visually match a glyph the model missed. Its result feeds back into `scan_history` identically to an ML-classified result.

---

## 5. Cartouche Phonetic Engine (Egyptology-Accurate)

This directly implements the accuracy requirement: **no letter-by-letter alphabet mapping.**

### 5.1 Pipeline

```
"ALEXANDER"
   │
   ▼
[1] Grapheme→Phoneme (G2P)  — rule-based English G2P (lightweight on-device rule table,
   │                            not a full ML G2P model — deterministic and auditable)
   │                            → ["AH", "LEK", "S AE N", "D ER"] (ARPABET-like units)
   ▼
[2] Phoneme Normalization    — collapse to consonantal skeleton Egyptian writing can represent
   │                            (Egyptian hieroglyphic writing is primarily consonantal;
   │                             vowels are approximated only via matres lectionis signs,
   │                             e.g. reed leaf for /i/-ish, quail chick for /w/-ish/u)
   │                            → consonant/semivowel sequence: ʔ-L-K-S-N-D-R (approx.)
   ▼
[3] Consonant→Sign Mapping   — deterministic lookup table: each consonant/phoneme unit maps to
   │                            an established uniliteral sign (per standard transliteration
   │                            convention, e.g. Gardiner's sign list uniliterals), preferring
   │                            biliteral signs where a known biliteral cleanly covers two
   │                            consecutive units (e.g. "ND" → known biliteral if applicable)
   ▼
[4] Cartouche Assembly       — arrange signs in the oval cartouche frame per conventional
                                 layout rules (top-to-bottom/right-to-left grouping), render as image
```

### 5.2 Key Design Rules

- The consonant/sign mapping table is **data, not code** (`assets/data/phoneme_to_sign_map.json`), reviewed by an Egyptology consultant and versioned independently of app releases.
- Where no reasonable Egyptian consonantal equivalent exists for a phoneme (e.g. certain vowel-heavy clusters), the engine explicitly marks that segment as "approximated" and the UI surfaces which segments are approximations vs. established sign matches.
- **Mandatory UI element** on every cartouche result screen (non-dismissible without acknowledgment on first use):
  > "This is an approximate phonetic rendering of your name using Egyptian hieroglyphic signs, not a historically authentic ancient Egyptian translation."
- This disclaimer string is itself localized and stored in `core/branding` copy overrides (an agency cannot remove it — it can only be translated).

### 5.3 Testability

Because the phoneme→sign table is external data and the pipeline stages are pure functions (`String → List<Phoneme> → List<GardinerCode>`), each stage is independently unit-testable with a fixed table of name examples and expected outputs — critical given the accuracy sensitivity here.

---

## 6. Offline-First Strategy Summary

| Capability | Bundled at install | Cached after first use | Requires connectivity |
|---|---|---|---|
| Dictionary (200+ signs, images, audio) | ✅ | — | never |
| Detection + classification models | ✅ | — | never |
| Cartouche phoneme/sign table | ✅ | — | never |
| Manual glyph selector | ✅ | — | never |
| Scan history, favorites | — | ✅ (local DB) | never |
| Agency branding/contact | ✅ default + | ✅ synced copy | only for updates |
| Itinerary | — | ✅ (pulled once, cached) | only for updates |
| Sharing to WhatsApp/Instagram | — | — | ✅ (inherent to the share action itself) |

Connectivity checks (`connectivity_plus`) gate only the sync layer — every feature's repository has a local-first read path and treats remote sync as a background "refresh if possible" side effect, never a blocking dependency.

---

## 7. Testing Strategy

- **Unit tests:** phoneme engine stages, Gardiner-code lookup/joins, confidence-gate logic, repository implementations (with fake DB/fake ML result injection).
- **Widget tests:** scan result sheet states (high/medium/low confidence), cartouche disclaimer gating, dictionary search/filter.
- **Integration tests:** full scan-to-result flow using a fixture image + mocked TFLite interpreter (never runs real inference in CI), full cartouche generation flow for a table of representative names (including edge cases with no clean consonant mapping).
- **Golden tests:** cartouche render output for a fixed name set, to catch layout regressions in sign assembly.

---

## 8. White-Label / B2B Path (Forward-Looking)

The architecture is already shaped for this, so the near-term build should not need rearchitecting later:

1. **Flavors, not forks:** each agency is a Flutter flavor (`--flavor agencyX`) pointing at a `core/config` JSON (branding, feature flags, bundled itinerary set). Single codebase, multiple store listings.
2. **Repository override seams:** `ItineraryRepository`, `AgencyProfileRepository`, and `BrandingRepository` are the only interfaces expected to have agency-specific implementations later (e.g. syncing from a specific agency's booking backend); everything else (dictionary, ML, cartouche) is shared and agency-agnostic.
3. **Future backend:** when this becomes multi-tenant SaaS, the natural seam is a thin sync API (`/agency/{id}/branding`, `/agency/{id}/itinerary`) — the local-first architecture means the backend only ever needs to serve "what's changed since last sync," not power live usage.

---

## 9. Open Workstreams Outside This Architecture Doc

These are real dependencies for a working v1 and should be tracked explicitly:

- **Training data & model training** for the detection/classification TFLite models (dataset sourcing/licensing from Egyptological corpora, annotation, training pipeline) — this is its own ML project, not something generated from this architecture alone.
- **Egyptology content review** of the 200+-sign dictionary and the phoneme→sign mapping table, by a qualified consultant, before any public/commercial release — given the explicit accuracy requirement, this is a gating step, not a nice-to-have.
- **Asset production**: glyph illustrations/photos, audio pronunciations, cartouche frame art.

---

## 10. Suggested Build Phases

1. **Foundation:** app shell, DI/router, Drift schema + JSON seed importer, dictionary browse/search UI (no ML yet, no cartouche yet).
2. **Manual-first scanning:** Manual Glyph Selector fully working end-to-end (camera capture → crop → manual pick → detail view) — validates the whole data/UI path before ML is in the loop.
3. **ML integration:** wire in detection + classification models (can start with a stub/placeholder model to validate the pipeline plumbing, swap in trained models when ready).
4. **Cartouche engine:** phoneme pipeline + sign assembly + disclaimer + share/export.
5. **Itinerary + agency contact + branding sync.**
6. **White-label flavoring** once a first paying agency is onboarding.

---

*Next steps I can help with directly: the Drift schema as actual Dart code (`tables.dart` + DAOs), the phoneme→sign mapping engine as a testable Dart module, or the camera/scanner UI widget tree — say which you want to start with.*
