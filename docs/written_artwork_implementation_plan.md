# Written Artwork Library Implementation Plan

**Status**: Ready for Implementation  
**Created**: February 3, 2026  
**Approach**: Hybrid Option (Extend Existing + Add Enhancements)
**MVP Timeline**: 1-2 weeks  
**Full Implementation**: 3-6 weeks  

---

## 🎯 The Strategy

Leverage ARTbeat's existing artwork infrastructure to get writers visible immediately, then layer on writing-specific features in phases.

### Why This Works
- ✅ Writers reuse artist profiles, earnings, subscriptions, analytics
- ✅ No database migrations needed (backward compatible)
- ✅ Non-disruptive to visual artists
- ✅ Can deploy Phase 1 in 1-2 weeks
- ✅ Room to grow with Phase 2 & 3 features

---

## 🛠️ Phase 1: Foundation (1-2 weeks) - GET WRITERS VISIBLE

### What You're Building
Writers can upload books/manuscripts and have them appear in their profile, be discoverable, and generate engagement + earnings.

### Implementation Steps (7 tasks, ~9 hours work)

#### **1.1: Extend Content Type Enum** (30 min)
**File**: `/packages/artbeat_artwork/lib/src/models/artwork_model.dart`

Add new content types:
```dart
enum ArtworkContentType {
  visual('visual'),
  audio('audio'),
  video('video'),
  literature('literature'),    // ← NEW
  poetry('poetry'),             // ← NEW
  interactive('interactive');

  final String displayName;
  
  static ArtworkContentType fromString(String value) {
    return values.firstWhere(
      (e) => e.displayName == value.toLowerCase(),
      orElse: () => ArtworkContentType.visual,
    );
  }
}
```

**What to do**: Add enum values and update fromString() logic  
**Complexity**: Low  
**Files affected**: 1

---

#### **1.2: Create WritingMetadata Model** (1 hour)
**New File**: `/packages/artbeat_core/lib/src/models/writing_metadata.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_utils.dart';

class WritingMetadata {
  final String? genre;                    // Fiction, Poetry, Essay, etc.
  final int? wordCount;
  final int? estimatedReadMinutes;
  final String? language;                 // English, Spanish, etc.
  final List<String> themes;              // Thematic tags
  final bool isSerializing;               // Released in chapters?
  final String? excerpt;                  // Preview text (first 500 words)
  final DateTime? firstPublishedDate;
  final bool hasMultipleChapters;

  const WritingMetadata({
    this.genre,
    this.wordCount,
    this.estimatedReadMinutes,
    this.language = 'English',
    this.themes = const [],
    this.isSerializing = false,
    this.excerpt,
    this.firstPublishedDate,
    this.hasMultipleChapters = false,
  });

  factory WritingMetadata.fromJson(Map<String, dynamic> json) {
    return WritingMetadata(
      genre: FirestoreUtils.safeString(json['genre']),
      wordCount: FirestoreUtils.safeInt(json['wordCount']),
      estimatedReadMinutes: FirestoreUtils.safeInt(json['estimatedReadMinutes']),
      language: FirestoreUtils.safeStringDefault(json['language'], 'English'),
      themes: (json['themes'] as List<dynamic>?)
              ?.map((e) => FirestoreUtils.safeStringDefault(e))
              .toList() ?? [],
      isSerializing: FirestoreUtils.safeBool(json['isSerializing'], false),
      excerpt: FirestoreUtils.safeString(json['excerpt']),
      firstPublishedDate: json['firstPublishedDate'] != null
          ? FirestoreUtils.safeDateTime(json['firstPublishedDate'])
          : null,
      hasMultipleChapters: FirestoreUtils.safeBool(json['hasMultipleChapters'], false),
    );
  }

  Map<String, dynamic> toJson() => {
    if (genre != null) 'genre': genre,
    if (wordCount != null) 'wordCount': wordCount,
    if (estimatedReadMinutes != null) 'estimatedReadMinutes': estimatedReadMinutes,
    'language': language,
    'themes': themes,
    'isSerializing': isSerializing,
    if (excerpt != null) 'excerpt': excerpt,
    if (firstPublishedDate != null) 'firstPublishedDate': Timestamp.fromDate(firstPublishedDate!),
    'hasMultipleChapters': hasMultipleChapters,
  };

  WritingMetadata copyWith({
    String? genre,
    int? wordCount,
    int? estimatedReadMinutes,
    String? language,
    List<String>? themes,
    bool? isSerializing,
    String? excerpt,
    DateTime? firstPublishedDate,
    bool? hasMultipleChapters,
  }) {
    return WritingMetadata(
      genre: genre ?? this.genre,
      wordCount: wordCount ?? this.wordCount,
      estimatedReadMinutes: estimatedReadMinutes ?? this.estimatedReadMinutes,
      language: language ?? this.language,
      themes: themes ?? this.themes,
      isSerializing: isSerializing ?? this.isSerializing,
      excerpt: excerpt ?? this.excerpt,
      firstPublishedDate: firstPublishedDate ?? this.firstPublishedDate,
      hasMultipleChapters: hasMultipleChapters ?? this.hasMultipleChapters,
    );
  }
}
```

**What to do**:
- Create new file
- Implement JSON serialization methods
- Export from models/models.dart

**Complexity**: Low  
**Files affected**: 2 (new file + export)

---

#### **1.3: Extend ArtworkModel** (1.5 hours)
**File**: `/packages/artbeat_artwork/lib/src/models/artwork_model.dart`

Add field to class:
```dart
class ArtworkModel {
  // ... existing fields ...
  
  /// Optional metadata for written works
  final WritingMetadata? writingMetadata;
  
  ArtworkModel({
    // ... existing params ...
    this.writingMetadata,
  });
}
```

Update factory method:
```dart
factory ArtworkModel.fromFirestore(Map<String, dynamic> data) {
  return ArtworkModel(
    // ... existing field parsing ...
    writingMetadata: data['writingMetadata'] != null
        ? WritingMetadata.fromJson(data['writingMetadata'] as Map<String, dynamic>)
        : null,
  );
}
```

Update serialization:
```dart
Map<String, dynamic> toFirestore() {
  return {
    // ... existing fields ...
    if (writingMetadata != null) 'writingMetadata': writingMetadata!.toJson(),
  };
}
```

Update copyWith:
```dart
ArtworkModel copyWith({
  // ... existing params ...
  WritingMetadata? writingMetadata,
}) {
  return ArtworkModel(
    // ... existing assignments ...
    writingMetadata: writingMetadata ?? this.writingMetadata,
  );
}
```

**What to do**:
- Add writingMetadata field
- Update constructor
- Update fromFirestore() factory
- Update toFirestore() method
- Update copyWith() method

**Complexity**: Medium  
**Files affected**: 1

---

#### **1.4: Update Upload UI** (2 hours)
**File(s)**: Art/artwork upload screens (likely `/lib/screens/` or `/packages/artbeat_artist/lib/src/screens/`)

Add conditional UI when `contentType == ArtworkContentType.literature`:

```dart
if (selectedContentType == ArtworkContentType.literature) {
  SizedBox(height: 16),
  Text('Writing Details', style: Theme.of(context).textTheme.titleMedium),
  SizedBox(height: 8),
  
  TextField(
    controller: genreController,
    label: 'Genre',
    hintText: 'Fiction, Poetry, Essay, etc.',
  ),
  
  TextField(
    controller: wordCountController,
    label: 'Word Count',
    keyboardType: TextInputType.number,
  ),
  
  CheckboxListTile(
    title: Text('Serialized Work? (Released in chapters)'),
    value: isSerializing,
    onChanged: (value) => setState(() => isSerializing = value ?? false),
  ),
  
  TextField(
    controller: excerptController,
    label: 'Excerpt / Preview (first 500 words)',
    minLines: 5,
    maxLines: 10,
  ),
}
```

**What to do**:
- Detect when user selects "Literature" as content type
- Show writing-specific input fields
- Capture metadata and include in artwork upload

**Complexity**: Medium  
**Files affected**: 1-3

---

#### **1.5: Update Artwork Display** (2 hours)
**File(s)**: Artwork detail screens

Add conditional rendering:

```dart
if (artwork.contentType == ArtworkContentType.literature) {
  if (artwork.writingMetadata != null) {
    Column(
      children: [
        ListTile(
          leading: Icon(Icons.local_library),
          title: Text('Genre'),
          subtitle: Text(artwork.writingMetadata!.genre ?? 'Not specified'),
        ),
        if (artwork.writingMetadata!.wordCount != null)
          ListTile(
            leading: Icon(Icons.description),
            title: Text('Word Count'),
            subtitle: Text('${artwork.writingMetadata!.wordCount} words'),
          ),
        if (artwork.writingMetadata!.estimatedReadMinutes != null)
          ListTile(
            leading: Icon(Icons.schedule),
            title: Text('Estimated Read Time'),
            subtitle: Text('${artwork.writingMetadata!.estimatedReadMinutes} min'),
          ),
        if (artwork.writingMetadata!.excerpt != null) ...[
          Divider(),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preview', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                SelectableText(
                  artwork.writingMetadata!.excerpt!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
} else {
  // Existing visual art display
}
```

**What to do**:
- Add conditional rendering for literature content type
- Display WritingMetadata fields (genre, word count, read time, excerpt)
- Keep existing visual art UI untouched

**Complexity**: Medium  
**Files affected**: 2-3

---

#### **1.6: Update Artist Profile** (1.5 hours)
**File**: `/packages/artbeat_artist/lib/src/screens/artist_profile_screen.dart` (or similar)

Add section to display written works:

```dart
// In the artist profile build method, after visual artworks:
if (artistWorks.where((w) => w.contentType == ArtworkContentType.literature).isNotEmpty)
  Padding(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '📚 Written Works',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: writtenWorks.length,
          itemBuilder: (context, index) {
            final work = writtenWorks[index];
            return ListTile(
              leading: work.imageUrl != null
                  ? Image.network(work.imageUrl!, width: 50, fit: BoxFit.cover)
                  : Icon(Icons.book),
              title: Text(work.title),
              subtitle: work.writingMetadata?.genre != null
                  ? Text('${work.writingMetadata!.genre} • ${work.writingMetadata?.wordCount ?? 0} words')
                  : null,
              onTap: () => navigateToWorkDetail(work),
            );
          },
        ),
      ],
    ),
  ),
```

**What to do**:
- Add section to artist profile layout
- Display books/written works in book-friendly format
- Link to full work details

**Complexity**: Low  
**Files affected**: 1-2

---

#### **1.7: Update Search/Discovery** (1 hour)
**File**: `/packages/artbeat_artwork/lib/src/services/artwork_service.dart`

Add helper methods:

```dart
/// Get all published written works
Future<List<ArtworkModel>> getPublishedWrittenWorks({
  int limit = 20,
  DocumentSnapshot? startAfter,
}) async {
  var query = _firestore
      .collection('artworks')
      .where('contentType', isEqualTo: 'literature')
      .where('isPublic', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(limit);

  if (startAfter != null) {
    query = query.startAfterDocument(startAfter);
  }

  return query.get().then((snapshot) => snapshot.docs
      .map((doc) => ArtworkModel.fromFirestore(doc.data()))
      .toList());
}

/// Search written works by genre
Future<List<ArtworkModel>> getWrittenWorksByGenre(String genre) async {
  return _firestore
      .collection('artworks')
      .where('contentType', isEqualTo: 'literature')
      .where('writingMetadata.genre', isEqualTo: genre)
      .where('isPublic', isEqualTo: true)
      .get()
      .then((snapshot) => snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc.data()))
          .toList());
}

/// Search written works by author
Future<List<ArtworkModel>> getWrittenWorksByArtist(String artistId) async {
  return _firestore
      .collection('artworks')
      .where('contentType', isEqualTo: 'literature')
      .where('artistProfileId', isEqualTo: artistId)
      .orderBy('createdAt', descending: true)
      .get()
      .then((snapshot) => snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc.data()))
          .toList());
}
```

**What to do**:
- Add query methods to artwork service
- Support filtering by content type and genre
- Enable discovery in explore/browse screens

**Complexity**: Low  
**Files affected**: 1-2

---

### Phase 1 Summary

| Step | Task | Time | Complexity |
|------|------|------|-----------|
| 1.1 | Extend ContentType enum | 30 min | Low |
| 1.2 | Create WritingMetadata model | 1 hr | Low |
| 1.3 | Extend ArtworkModel | 1.5 hrs | Medium |
| 1.4 | Update upload UI | 2 hrs | Medium |
| 1.5 | Update display UI | 2 hrs | Medium |
| 1.6 | Artist profile section | 1.5 hrs | Low |
| 1.7 | Search/discovery | 1 hr | Low |
| **TOTAL** | **Foundation Complete** | **~9 hours** | **1-2 dev days** |

**Deliverable**: Writers can upload books, see them in profiles, discover others' books, and generate engagement + earnings.

---

## 🎯 Phase 2: Writing Features (2-4 weeks) - ENHANCE THE EXPERIENCE

Once Phase 1 is live, enhance with writing-specific features:

### 2.1 Chapter Management System
- Break books into chapters
- Schedule chapter releases (serialization)
- Manage chapter drafts vs published
- Chapter-level engagement tracking

### 2.2 Genre/Theme Taxonomy
- Build comprehensive genre system
- Support sub-genres (Fantasy → High Fantasy, Urban Fantasy)
- Improve discovery and filtering

### 2.3 Reading Metadata
- Calculate and display estimated read time
- Support content warnings/maturity ratings
- Add to reading list feature
- Series/book number tracking

### 2.4 Writing Community
- Writers' forums/discussions
- Beta reader program signup
- Feedback/review system
- Writing challenges/prompts

---

## 📊 Database Structure (No Migration!)

Books stored in existing `artworks` collection in Firestore:

```
artworks/
├── book_001
│   ├── id: "book_001"
│   ├── userId: "author_123"
│   ├── contentType: "literature"        // ← NEW VALUE
│   ├── title: "My Novel"
│   ├── description: "Synopsis..."
│   ├── imageUrl: "cover.jpg"
│   ├── writingMetadata: {               // ← NEW OPTIONAL FIELD
│   │   ├── genre: "Science Fiction"
│   │   ├── wordCount: 75000
│   │   ├── estimatedReadMinutes: 450
│   │   ├── language: "English"
│   │   ├── themes: ["space", "future"]
│   │   ├── isSerializing: false
│   │   ├── excerpt: "Once upon a time..."
│   │   └── hasMultipleChapters: false
│   ├── isForSale: true
│   ├── price: 9.99
│   ├── tags: ["scifi", "space"]
│   ├── viewCount: 245
│   ├── engagement: {...}
│   └── ... (all other artwork fields work as-is)
```

**Key Points**:
- ✅ WritingMetadata is optional (backward compatible)
- ✅ Uses existing artwork schema
- ✅ No database migration needed
- ✅ Visual artists unaffected

---

## ✅ Phase 1 Success Criteria

After 1-2 weeks you should have:

- [ ] Writer can upload a manuscript/book with title, description, genre, word count
- [ ] Book displays in their artist profile with a "Written Works" section
- [ ] Book appears in ARTbeat search with "Literature" as content type
- [ ] Other users can view the book and leave likes/comments
- [ ] Writer can set price and earn from sales (using existing payment system)
- [ ] Genre filtering works in discovery views
- [ ] Book displays with book-appropriate UI (not gallery-style)
- [ ] Excerpt preview displays if provided

**Minimum Viable Product**: One writer has uploaded a book, it's discoverable, and readers can engage with it.

---

## 📋 Before You Start - Key Questions

Clarify these before beginning implementation:

1. **MVP Scope**: For Phase 1, do you want:
   - Just upload full books (simpler, ~1 week)
   - OR full books + chapter upload support (complex, ~1.5 weeks)
   - **Recommendation**: Start with full books only, add chapters in Phase 2

2. **Pricing Model**:
   - Same subscription tiers as visual artists?
   - Different pricing for writers?
   - **Recommendation**: Same tiers for MVP

3. **Discoverability**:
   - Books mixed in main ARTbeat feed with visual art?
   - Separate "Books & Writing" discovery section?
   - **Recommendation**: Separate section initially

4. **Upload Format**:
   - Paste/upload as plain text?
   - Need formatted upload (DOCX, PDF)?
   - **Recommendation**: Plain text for MVP

---

## 📚 What You'll Have After Implementation

### Writer's Experience
- Create professional author profile (reuses artist profile)
- Upload complete books or serialize in chapters
- Set price and earn revenue
- View analytics (views, sales, earnings)
- Manage subscriptions and payouts
- See reader engagement (likes, comments)

### Reader's Experience
- Discover books by genre, author, themes
- Read excerpt previews
- Leave comments and engagement
- Save favorites
- Support writers through purchases/tips

### ARTbeat Platform
- New community (writers) alongside visual artists
- New revenue stream (book sales)
- Expanded content library
- Cross-pollination opportunity (writers + artists)

---

## 🚀 Getting Started

1. **Review this plan** - Make sure it aligns with your vision
2. **Answer key questions** - Clarify scope and features above
3. **Decide on timeline** - When do you want Phase 1 live?
4. **Set up task tracking** - Break Phase 1 steps into tickets
5. **Start with Step 1.1** - Extend the enum (easiest step to verify approach)

---

## References

- [ArtworkModel](packages/artbeat_artwork/lib/src/models/artwork_model.dart#L37)
- [ArtworkContentType](packages/artbeat_artwork/lib/src/models/artwork_model.dart#L1)
- [Artist Package](packages/artbeat_artist/)
- [Artwork Service](packages/artbeat_artwork/lib/src/services/)
- [Community Features](packages/artbeat_community/)

