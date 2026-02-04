# Written Artwork: Step-by-Step Walkthrough

## Overview

You're adding book/written work support to ARTbeat by:
1. Creating a new content type for literature
2. Adding optional metadata fields for writing-specific info
3. Updating UI to display books appropriately
4. Enabling search/discovery for written works

**Timeline**: 1-2 weeks for MVP  
**Complexity**: Medium (mostly UI updates)  
**Risk**: Low (backward compatible, optional fields)

---

## What Each Step Does

### Step 1.1: Extend Content Type
**What**: Add "literature" and "poetry" as valid content types  
**Why**: Currently only "visual", "audio", "video" exist. Need to tell system what type of artwork a book is.  
**Impact**: 1 file, 10 lines of code  
**How it works**: When someone uploads, they can now select "Book" as content type instead of "Painting"

---

### Step 1.2: Create WritingMetadata Model
**What**: Create a container class for book-specific information (genre, word count, excerpt, etc.)  
**Why**: Books need different metadata than visual art. Can't put genre/wordcount on a painting.  
**Impact**: 1 new file  
**How it works**: 
- Holds info like "Science Fiction", "75000 words", "450 min read time"
- Has JSON methods to save/load from database
- Optional field on artwork (some artworks won't have it)

**Example data structure**:
```
WritingMetadata {
  genre: "Science Fiction",
  wordCount: 75000,
  estimatedReadMinutes: 450,
  excerpt: "Once upon a time...",
  themes: ["space", "future"],
  language: "English"
}
```

---

### Step 1.3: Extend ArtworkModel
**What**: Add WritingMetadata as optional field to existing ArtworkModel  
**Why**: Now artworks can optionally have writing metadata  
**Impact**: 1 file, ~20 lines changed  
**How it works**: 
- When saving a book to database, the writingMetadata goes with it
- When loading a book, the metadata comes back with it
- Visual art artworks don't have metadata (null) - no change to them

**Before**:
```dart
class ArtworkModel {
  final String id;
  final String title;
  final String description;
  // ... no writing support
}
```

**After**:
```dart
class ArtworkModel {
  final String id;
  final String title;
  final String description;
  final WritingMetadata? writingMetadata;  // ← NEW
  // ... everything else stays same
}
```

---

### Step 1.4: Update Upload UI
**What**: Show different form fields when user selects "Book" as content type  
**Why**: Books and paintings have different metadata needs  
**Impact**: 2-3 files (upload screens)  
**How it works**:
- User taps "Content Type: Book"
- Form shows new fields: Genre, Word Count, Preview Excerpt
- These get captured and sent to database as WritingMetadata

**User flow**:
```
1. Open upload
2. Select "Book" as type
3. Form changes to show book fields
4. Fill: Title, Description, Genre, Word Count, Excerpt
5. Upload → stored as literature contentType with metadata
```

---

### Step 1.5: Update Display UI
**What**: Show book information differently than visual art  
**Why**: A book shouldn't look like an art gallery. Need to display metadata appropriately.  
**Impact**: 2-3 files (detail screens)  
**How it works**:
- Check if artwork is contentType "literature"
- If yes, show: Genre, Word Count, Read Time, Excerpt Preview
- If no, show existing visual art display

**What reader sees**:
```
📚 My Novel
Science Fiction • 75,000 words • 450 min read

Preview:
"Once upon a time in a galaxy far away..."
```

---

### Step 1.6: Update Artist Profile
**What**: Add "📚 Written Works" section to artist profile alongside visual artworks  
**Why**: Writers should showcase their books in their profile  
**Impact**: 1-2 files  
**How it works**:
- After showing visual artworks, check if artist has any books
- If yes, add a section showing them in book-list format
- Each book links to its detail page

**What artist sees**:
```
🖼️ Artworks
[visual art gallery...]

📚 Written Works
- My Novel (Science Fiction, 75k words)
- Short Story Collection (Fiction, 12k words)
```

---

### Step 1.7: Update Search/Discovery
**What**: Add database queries to find books by content type, genre, author  
**Why**: Users need to discover books through search and explore  
**Impact**: 1-2 files (service layer)  
**How it works**:
- Add query: "Get all literature contentType ordered by newest"
- Add query: "Get literature where genre = 'SciFi'"
- Add query: "Get literature by specific author"
- Use in discover/browse screens

**Database query example**:
```dart
// Get all published books
artworks
  .where(contentType == 'literature')
  .where(isPublic == true)
  .orderBy(createdAt)
```

---

## Data Flow Example

### Uploading a Book

```
Writer clicks "Upload"
    ↓
Selects "Book" as type
    ↓
Form shows writing fields
    ↓
Fills: Title, Genre, Word Count, Excerpt [Step 1.4]
    ↓
Data structured as:
ArtworkModel {
  title: "My Novel",
  contentType: "literature",           [Step 1.1]
  writingMetadata: WritingMetadata {   [Step 1.2]
    genre: "Science Fiction",
    wordCount: 75000,
    excerpt: "..."
  }
}
    ↓
Saved to Firestore in "artworks" collection
    ↓
Book appears in writer's profile [Step 1.6]
    ↓
Book findable in search [Step 1.7]
```

### Viewing a Book

```
Reader searches for "Science Fiction"
    ↓
Query: Get all literature with genre="SciFi" [Step 1.7]
    ↓
Results show: "My Novel" by Writer
    ↓
Reader taps on book
    ↓
Detail screen loads ArtworkModel [Step 1.3]
    ↓
Detects: contentType == "literature" [Step 1.1]
    ↓
Shows book-specific UI [Step 1.5]
  - Cover image
  - Title: "My Novel"
  - Genre: "Science Fiction"
  - Word Count: "75,000"
  - Excerpt preview
    ↓
Reader can like, comment, purchase
```

---

## Why This Is Safe

### ✅ Backward Compatible
- WritingMetadata is optional (nullable)
- Visual art artworks don't need it
- Can roll out gradually

### ✅ No Data Loss
- No database migration
- New field just stored alongside existing
- Old artworks keep working

### ✅ Non-Disruptive
- Visual artists unaffected
- Existing UI unchanged for their work
- Just new conditional logic

### ✅ Reuses Everything
- Uses existing artist profiles
- Uses existing earnings system
- Uses existing engagement (likes, comments)
- Uses existing collections/portfolios
- Uses existing search infrastructure

---

## Testing Strategy

After each step:

**1.1 (Enum)**: Verify new enum values exist and fromString() works
```dart
expect(ArtworkContentType.literature.displayName, 'literature');
expect(ArtworkContentType.fromString('literature'), ArtworkContentType.literature);
```

**1.2 (Model)**: Test WritingMetadata JSON round-trip
```dart
final metadata = WritingMetadata(genre: 'SciFi', wordCount: 75000);
final json = metadata.toJson();
final restored = WritingMetadata.fromJson(json);
expect(restored.genre, 'SciFi');
```

**1.3 (ArtworkModel)**: Test artwork with writingMetadata
```dart
final artwork = ArtworkModel(
  // ... required fields ...
  writingMetadata: WritingMetadata(genre: 'SciFi'),
);
final json = artwork.toFirestore();
expect(json['writingMetadata']['genre'], 'SciFi');
```

**1.4 (Upload UI)**: Manual test uploading a book
```
1. Open upload
2. Select "Book" type
3. See new fields appear
4. Fill and upload
5. Verify in Firestore
```

**1.5 (Display UI)**: Manual test viewing uploaded book
```
1. Load book detail
2. Verify shows genre, word count, excerpt
3. Verify visual art still shows old way
```

**1.6 (Profile)**: Manual test artist profile
```
1. Go to writer's profile
2. See 📚 Written Works section
3. Books listed with metadata
```

**1.7 (Search)**: Manual test discovery
```
1. Search for "Science Fiction"
2. See books appear in results
3. Filter by genre
```

---

## Order of Implementation

**Recommended**: Implement in order 1.1 → 1.7

- **1.1 & 1.2** first (setup, no UI needed)
- **1.3** next (model changes)
- **1.4, 1.5, 1.6** together (UI work)
- **1.7** last (queries depend on other changes)

**Estimated per task**:
- 1.1: 30 min
- 1.2: 1 hour
- 1.3: 1.5 hours
- 1.4: 2 hours
- 1.5: 2 hours
- 1.6: 1.5 hours
- 1.7: 1 hour

**Total**: ~9 hours spread over 1-2 weeks

---

## Success Checkpoints

**After 1.1**: Enum compiles and has literature/poetry values ✅  
**After 1.2**: WritingMetadata model compiles and serializes ✅  
**After 1.3**: ArtworkModel has writingMetadata field ✅  
**After 1.4**: Can upload book and fill writing fields ✅  
**After 1.5**: Book displays with book UI (not gallery UI) ✅  
**After 1.6**: Artist profile shows 📚 Written Works section ✅  
**After 1.7**: Can search and filter by genre ✅  

**End State**: Writers can share their books with the ARTbeat community.

---

## Phase 2 Preview

Once Phase 1 is live and writers are using it:

- **Chapters**: Break books into chapters, serialize releases
- **Genres**: Better genre taxonomy and filtering
- **Reading**: Reading lists, progress tracking, estimated read time
- **Community**: Beta readers, writing forums, challenges

But don't start these until Phase 1 is working!

---

## Questions to Answer Before Starting

1. **Content upload format**: Can writers just paste text, or need DOCX/PDF support?
   - *MVP answer*: Plain text/paste

2. **Pricing**: Do you want writers to pay to list books, or free with optional premium?
   - *MVP answer*: Same as visual artists (free to list)

3. **Discoverability**: Books in main feed or separate section?
   - *MVP answer*: Separate "Books" browsing section

4. **Chapters**: Support from day 1 or Phase 2?
   - *MVP answer*: Phase 2 (just full books in Phase 1)

Answer these and you're ready to start!

