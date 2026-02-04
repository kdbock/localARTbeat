# Written Artwork Implementation Checklist

**Goal**: Get writers visible on ARTbeat within 1-2 weeks  
**Approach**: Extend existing artwork system  
**Status**: Ready to implement

---

## Phase 1: Foundation (1-2 weeks)

### Task 1.1: Extend Content Type Enum ⏱️ 30 min
- [x] Open `/packages/artbeat_artwork/lib/src/models/artwork_model.dart`
- [x] Add `literature` and `poetry` values to `ArtworkContentType` enum
- [x] Update `fromString()` method to handle new types
- [x] Verify compilation
- [x] Commit: "feat: Add literature and poetry content types"

**Status**: ✅ COMPLETE - Already existed in codebase!

---

### Task 1.2: Create WritingMetadata Model ⏱️ 1 hour
- [x] Create new file: `/packages/artbeat_core/lib/src/models/writing_metadata.dart`
- [x] Define `WritingMetadata` class with fields:
  - genre, wordCount, estimatedReadMinutes, language
  - themes (List), isSerializing, excerpt, firstPublishedDate, hasMultipleChapters
- [x] Implement `fromJson()` factory method
- [x] Implement `toJson()` serialization method
- [x] Implement `copyWith()` method
- [x] Add export to `/packages/artbeat_core/lib/src/models/models.dart`
- [x] Add export to `/packages/artbeat_core/lib/src/models/index.dart`
- [x] Verify compilation
- [x] Commit: "feat: Add WritingMetadata model"

**Status**: ✅ COMPLETE

---

### Task 1.3: Extend ArtworkModel ⏱️ 1.5 hours
- [x] Open `/packages/artbeat_artwork/lib/src/models/artwork_model.dart`
- [x] Add field: `final WritingMetadata? writingMetadata;`
- [x] Update constructor to include `writingMetadata` parameter
- [x] Update `fromFirestore()` factory to parse writingMetadata
- [x] Update `toFirestore()` method to serialize writingMetadata
- [x] Update `copyWith()` method to include writingMetadata
- [x] Update `fromJson()` if exists
- [x] Update `toJson()` if exists
- [x] Verify compilation
- [x] Run existing artwork tests
- [x] Commit: "feat: Add writingMetadata field to ArtworkModel"

**Files**: 1  
**Lines of code**: ~25-30
**Status**: ✅ COMPLETE

---

### Task 1.4: Update Upload UI ⏱️ 2 hours
- [x] Find artwork upload screens (likely in `/lib/screens/` or `/packages/artbeat_artist/lib/src/screens/`)
- [x] Add contentType selection widget (if not exists)
- [x] Add conditional UI that shows when contentType == literature:
  - [x] Genre text field
  - [x] Word count number field
  - [x] Serialized work checkbox
  - [x] Excerpt preview textarea
- [x] Capture these fields into WritingMetadata object
- [x] Pass writingMetadata to artwork creation call
- [x] Test manual upload
- [x] Commit: "feat: Integrate WritingMetadata into written content upload screen"

**Files**: 1  
**Lines of code**: ~50-80
**Status**: ✅ COMPLETE

---

### Task 1.5: Update Artwork Display ⏱️ 2 hours
- [x] Find artwork detail screens
- [x] Add conditional check: `if (artwork.contentType == ArtworkContentType.literature)`
- [x] When true, show WritingMetadata section:
  - [x] Genre with icon (📖)
  - [x] Word count with icon (📄)
  - [x] Estimated read time with icon (⏱️)
  - [x] Excerpt preview (selectable text)
- [x] When false, keep existing visual art UI
- [x] Test manual view of uploaded book
- [x] Commit: "feat: Add literature display UI to artwork detail screens"

**Files**: 2  
**Lines of code**: ~224
**Status**: ✅ COMPLETE - Updated both artwork_detail_screen and written_content_detail_screen

---

### Task 1.6: Update Artist Profile ⏱️ 1.5 hours
- [x] Open artist profile screen
- [x] Add new section after visual artworks:
  - [x] Title: "📚 Written Works" (only show if has books)
  - [x] List all artwork with contentType == literature
  - [x] Show as book list (title, genre, word count)
  - [x] Link to full work details
- [x] Test on writer's profile
- [x] Commit: "feat: Add written works section to artist profile"

**Files**: 1  
**Lines of code**: ~171
**Status**: ✅ COMPLETE - Added _writtenWorks state, separation logic, section UI, and _buildWrittenWorkItem method

---

### Task 1.7: Update Search/Discovery ⏱️ 1 hour
- [ ] Open artwork service (`/packages/artbeat_artwork/lib/src/services/artwork_service.dart`)
- [ ] Add method: `getPublishedWrittenWorks()`
  - [ ] Query: where contentType == 'written' AND isPublic == true
  - [ ] Order by createdAt descending
  - [ ] Support pagination (limit, startAfter)
- [ ] Add method: `getWrittenWorksByGenre(String genre)`
  - [ ] Query: where contentType == 'written' AND writingMetadata.genre == genre AND isPublic == true
- [ ] Add method: `getWrittenWorksByArtist(String artistId)`
  - [ ] Query: where contentType == 'written' AND artistProfileId == artistId
- [ ] Test queries return correct results
- [ ] Commit: "feat: Add literature search queries"

**Files**: 1  
**Lines of code**: ~40-60
**Status**: ⏳ IN PROGRESS

---

## Phase 1 Summary

| Task | Time | Status |
|------|------|--------|
| 1.1 Enum | 30 min | ✅ |
| 1.2 Model | 1 hr | ✅ |
| 1.3 ArtworkModel | 1.5 hrs | ✅ |
| 1.4 Upload UI | 2 hrs | ✅ |
| 1.5 Display UI | 2 hrs | ✅ |
| 1.6 Profile | 1.5 hrs | ✅ |
| 1.7 Search | 1 hr | ⏳ |
| **TOTAL** | **~9 hours** | **6/7 DONE (86%)** |

---

## Definition of Done - Phase 1

- [ ] All 7 tasks completed and working
- [x] Code compiles without errors
- [x] No regressions in existing artwork functionality
- [x] Visual artworks still display and function normally
- [x] Can upload a book with all metadata (Task 1.4 ✅)
- [x] Book appears in artist profile (Task 1.6 ✅)
- [ ] Book is discoverable in search by genre and author (Task 1.7 ⏳)
- [x] Book displays with book-specific UI (not gallery) (Task 1.5 ✅)
- [ ] Reader can engage (likes, comments) with book (existing system works)
- [ ] Book can be priced and sold (using existing payment system)
- [ ] Manual testing complete
- [x] All commits are clean and well-described (6 commits so far)

---

## Phase 2: Enhancements (2-4 weeks)

### Not Phase 1, but good to know:

- [ ] Chapter management system
- [ ] Genre taxonomy/curation
- [ ] Reading progress tracking
- [ ] Series/collection management
- [ ] Beta reader program
- [ ] Writing community forums
- [ ] Export to EPUB/PDF

---

## Before You Start

### Prerequisites
- [ ] Code is up-to-date (git pull)
- [ ] Build is clean (flutter clean && flutter pub get)
- [ ] Understand ArtworkModel structure
- [ ] Access to all 7 files listed above
- [ ] Flutter/Dart environment ready

### Decisions Made
- [ ] Phase 1 = full books only (no chapter serialization)
- [ ] Same pricing as visual artists
- [ ] WritingMetadata is optional
- [ ] No database migration needed
- [ ] Backward compatible

### Questions to Answer
- [ ] What's the target go-live date?
- [ ] Who is the first test writer?
- [ ] Where should "Books" section appear in UI?
- [ ] Should books appear in main feed or separate?

---

## Testing Checklist

### Unit Tests
- [ ] WritingMetadata serialization round-trip
- [ ] ArtworkModel with writingMetadata round-trip
- [ ] ContentType enum includes literature

### Integration Tests
- [ ] Upload book → verify in Firestore
- [ ] Load book → verify metadata displays
- [ ] Search for genre → returns books

### Manual Tests
- [ ] Upload book as writer
- [ ] View book as reader
- [ ] Like/comment on book
- [ ] Check artist profile shows books
- [ ] Search filters by genre
- [ ] Visual art unaffected

---

## Deployment Checklist

### Before going live:
- [ ] All tasks marked complete
- [ ] Code reviewed and approved
- [ ] Tests passing
- [ ] Tested on multiple devices (iOS, Android)
- [ ] Firestore rules allow writing to writingMetadata
- [ ] Analytics updated to track literature uploads

### Rollout:
- [ ] Deploy to staging
- [ ] Test in staging environment
- [ ] Get feedback from test writer
- [ ] Fix any issues
- [ ] Deploy to production

---

## Quick Reference

### Key Files

```
Enum:           /packages/artbeat_artwork/lib/src/models/artwork_model.dart
New Model:      /packages/artbeat_core/lib/src/models/writing_metadata.dart
Extended Model: /packages/artbeat_artwork/lib/src/models/artwork_model.dart
Upload UI:      /lib/screens/[upload_screen].dart (or /packages/artbeat_artist/)
Display UI:     /lib/screens/[detail_screen].dart
Profile:        /packages/artbeat_artist/lib/src/screens/artist_profile_screen.dart
Service:        /packages/artbeat_artwork/lib/src/services/artwork_service.dart
```

### Firestore Structure

```
artworks/
├── [existing visual art]
└── [new literature entries]
    └── writingMetadata: { optional metadata }
```

### What Changes

```
✅ ADD: contentType values for literature/poetry
✅ ADD: WritingMetadata model
✅ ADD: writingMetadata field to ArtworkModel
✅ ADD: UI for writing metadata
✅ ADD: Conditional display for books vs art
✅ ADD: Books section in artist profile
✅ ADD: Query methods for discovery

❌ CHANGE: Nothing - all backward compatible
❌ DELETE: Nothing
```

---

## Success!

When this is done:

```
Writer can:
✅ Upload a book
✅ Set genre, word count, preview excerpt
✅ Have it appear in their profile
✅ Get discovered by readers
✅ Earn money from sales

Reader can:
✅ Find books by genre or author
✅ Read preview excerpt
✅ Like and comment
✅ Support writer through purchase

Platform:
✅ Has new creative community (writers)
✅ Has new content type (literature)
✅ Same revenue model as visual art
✅ No disruption to existing features
```

You'll be ready for Phase 2: enhanced writing features!

---

## Need Help?

Reference documents:
- `written_artwork_implementation_plan.md` - Full technical details
- `WRITTEN_ARTWORK_WALKTHROUGH.md` - Concept explanations
- `written_artwork_library_idea.md` - Original discussion/context

