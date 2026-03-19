# Written Artwork Library Initiative - Implementation Plan

**Status**: Ready for Implementation  
**Created**: February 3, 2026  
**Approach**: Hybrid Option (Extend + Enhance)
**Timeline**: 3-6 weeks total
**Participants**: Writer/Author, ARTbeat Platform Team  

---

## 🎯 Vision

Enable writers and authors to showcase their written works on ARTbeat's local community platform, giving them the same visibility and discovery tools that visual artists currently enjoy.

**Recommended Approach**: Leverage existing artwork infrastructure while adding writing-specific enhancements layer-by-layer. Fast initial implementation (1-2 weeks) gets writers visible, with phased feature additions.

---

## � Why Hybrid Approach (Option 3)?

1. **Fast Entry** - Writers visible within 1-2 weeks
2. **Reuses Strengths** - Leverage working artist/commerce system  
3. **Growth Path** - Expand features without disruption
4. **Low Risk** - Non-invasive to existing visual art features
5. **Community Benefit** - Brings new creative community to platform
6. **Economics** - Same revenue opportunities for writers
7. **Zero Migration** - Backward compatible, no database restructuring

---

## 📊 Current ARTbeat Setup (Leveraging)

### Existing Architecture (Strengths to Leverage)

**Modular Package System** (13 packages):
- `artbeat_artwork` - Core artwork management system
- `artbeat_artist` - Professional artist tools & profiles
- `artbeat_community` - Social features & networking
- `artbeat_capture` - Media capture & upload tools
- `artbeat_events` - Event management
- `artbeat_core` - Shared utilities & base models

**Current Artwork Capabilities**:
- Multiple content types: Visual art, videos, audio files
- Multimedia support: Primary image + multiple images/videos/audio
- Metadata fields: Title, description, medium, styles, dimensions, materials, tags
- Artist management: Profiles with verification, subscriptions, analytics
- Engagement tracking: Views, likes, comments, ratings
- Collections/Portfolios: Group related artworks
- Art Walks: Location-based discovery
- Serialization fields already exist: `isSerializing`, `totalChapters`, `releasedChapters`
- Commerce features: Pricing, sales tracking, commissions, auctions

**Current ArtworkModel Fields** (from artbeat_artwork):
```
- id, userId, artistProfileId
- title, description
- imageUrl, additionalImageUrls, videoUrls, audioUrls
- medium, styles, dimensions, materials
- tags, hashtags, keywords
- price, isForSale, isSold
- yearCreated, commissionRate
- isFeatured, isPublic
- viewCount, engagementStats (likes, comments)
- createdAt, updatedAt
- moderationStatus, contentType (enum: 'visual' | 'audio' | etc)
- Serialization support: isSerializing, totalChapters, releasedChapters, readingMetadata, serializationConfig
```

### Content Type System

ARTbeat already has an `ArtworkContentType` enum that includes support beyond just visual:
- Currently recognizes: visual, audio, and serialized content
- Extensible design allows adding 'literature', 'poetry', 'written', etc.

---

## � Quick Comparison (Context)

---

## 🎨 User Experience Considerations

### For Writers

**What they need**:
- Easy upload of manuscript/chapters
- Ability to serialize (chapter releases)
- Genre/category tagging
- Reading time estimates
- Visibility to local community
- Direct engagement metrics (readers, comments)
- Fair compensation/earnings model
- Professional profile showcasing their work

### For Readers

**What they expect**:
- Easy discovery by genre, author, series
- Preview/excerpt reading
- Bookmark chapters
- Reading progress tracking
- Comments/feedback on chapters
- Different UI from visual art (less gallery-like)

---

## 📋 Complete Implementation Roadmap

### **Phase 1: Foundation (1-2 weeks) - GET WRITERS VISIBLE**

Goal: Writers can upload books to ARTbeat and they're discoverable.

#### Step 1.1: Extend Content Type System
**File**: `/packages/artbeat_artwork/lib/src/models/artwork_model.dart`

```dart
enum ArtworkContentType {
  visual('visual'),
  audio('audio'),
  video('video'),
  literature('literature'),  // ← NEW
  poetry('poetry'),           // ← NEW
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

**What to do**:
- Add `literature` and `poetry` enum values
- Update `fromString()` method to handle new types
- Update serialization/deserialization

**Time**: 30 mins
**Affected files**: 1
**Dependencies**: None

---

#### Step 1.2: Create WritingMetadata Model
**New File**: `/packages/artbeat_core/lib/src/models/writing_metadata.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_utils.dart';

class WritingMetadata {
  final String? genre;                    // Fiction, Poetry, Essay, etc.
  final int? wordCount;
  final int? estimatedReadMinutes;
  final String? language;                 // English, Spanish, etc.
  final List<String> themes;              // Tags for themes
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
}
```

**What to do**:
- Create new file with WritingMetadata class
- Implement JSON serialization/deserialization
- Export from models package

**Time**: 1 hour
**Affected files**: 2 (new file + models/models.dart)
**Dependencies**: artbeat_core base classes

---

#### Step 1.3: Extend ArtworkModel
**File**: `/packages/artbeat_artwork/lib/src/models/artwork_model.dart`

Add to constructor and class:
```dart
class ArtworkModel {
  // ... existing fields ...
  
  /// Optional metadata for written works
  final WritingMetadata? writingMetadata;
  
  ArtworkModel({
    // ... existing params ...
    this.writingMetadata,
  });

  // Update fromFirestore factory method
  factory ArtworkModel.fromFirestore(Map<String, dynamic> data) {
    return ArtworkModel(
      // ... existing field parsing ...
      writingMetadata: data['writingMetadata'] != null
          ? WritingMetadata.fromJson(data['writingMetadata'] as Map<String, dynamic>)
          : null,
    );
  }

  // Update toFirestore method
  Map<String, dynamic> toFirestore() {
    return {
      // ... existing fields ...
      if (writingMetadata != null) 'writingMetadata': writingMetadata!.toJson(),
    };
  }

  // Update copyWith method
  ArtworkModel copyWith({
    // ... existing params ...
    WritingMetadata? writingMetadata,
  }) {
    return ArtworkModel(
      // ... existing field assignments ...
      writingMetadata: writingMetadata ?? this.writingMetadata,
    );
  }
}
```

**What to do**:
- Add `writingMetadata` field
- Update constructor
- Update factory methods (fromFirestore, fromJson)
- Update serialization methods (toFirestore, toJson)
- Update copyWith method

**Time**: 1.5 hours
**Affected files**: 1
**Dependencies**: WritingMetadata model

---

#### Step 1.4: Update Upload/Create UI
**File**: `/lib/screens/` (where artists upload)

When user selects content type:
```dart
// In upload screen, add contentType selection
if (selectedContentType == ArtworkContentType.literature) {
  // Show literature-specific fields
  TextField(
    label: 'Genre (Fiction, Poetry, Essay, etc.)',
    onChanged: (value) => writingMetadata.genre = value,
  ),
  TextField(
    label: 'Word Count',
    keyboardType: TextInputType.number,
  ),
  CheckboxListTile(
    title: Text('Is this a serialized work? (Released in chapters)'),
    value: writingMetadata.isSerializing,
    onChanged: (value) => writingMetadata.isSerializing = value ?? false,
  ),
  TextField(
    label: 'Excerpt / Preview Text (first 500 words)',
    minLines: 5,
  ),
}
```

**What to do**:
- Detect when contentType is literature
- Show additional fields for WritingMetadata
- Capture writing-specific information during upload

**Time**: 2 hours
**Affected files**: 1-2 (upload screens)
**Dependencies**: ContentType enum extension

---

#### Step 1.5: Update Artwork Display
**File**: `/packages/artbeat_artwork/lib/src/widgets/` or `/lib/widgets/`

```dart
// Artwork detail screen - show different UI for literature
if (artwork.contentType == ArtworkContentType.literature) {
  // Show as book/text
  Column(
    children: [
      if (artwork.writingMetadata != null) ...[
        ListTile(
          title: Text('Genre'),
          subtitle: Text(artwork.writingMetadata!.genre ?? 'Not specified'),
        ),
        if (artwork.writingMetadata!.wordCount != null)
          ListTile(
            title: Text('Word Count'),
            subtitle: Text('${artwork.writingMetadata!.wordCount} words'),
          ),
        if (artwork.writingMetadata!.estimatedReadMinutes != null)
          ListTile(
            title: Text('Estimated Read Time'),
            subtitle: Text('${artwork.writingMetadata!.estimatedReadMinutes} minutes'),
          ),
        if (artwork.writingMetadata!.excerpt != null)
          Padding(
            padding: EdgeInsets.all(16),
            child: SelectableText(artwork.writingMetadata!.excerpt!),
          ),
      ],
    ],
  );
} else {
  // Show as visual art (existing UI)
}
```

**What to do**:
- Add conditional rendering based on contentType
- Show WritingMetadata when present
- Display excerpt if available
- Keep existing visual art UI unchanged

**Time**: 2 hours
**Affected files**: 2-3 (detail screens, gallery views)
**Dependencies**: None

---

#### Step 1.6: Update Artist Profile
**File**: `/packages/artbeat_artist/lib/src/widgets/artist_profile_screen.dart`

```dart
// In artist profile, add section for written works
if (hasWrittenWorks) {
  SizedBox(height: 24),
  SectionTitle('📚 Written Works'),
  // Show books similar to artworks but with book-like layout
  ListView.builder(
    itemCount: writtenWorks.length,
    itemBuilder: (context, index) {
      final work = writtenWorks[index];
      return Card(
        child: ListTile(
          leading: work.imageUrl != null ? Image.network(work.imageUrl!) : Icon(Icons.book),
          title: Text(work.title),
          subtitle: work.writingMetadata?.genre != null
              ? Text('${work.writingMetadata!.genre} • ${work.writingMetadata?.wordCount ?? 0} words')
              : null,
          onTap: () => navigateToWorkDetail(work),
        ),
      );
    },
  ),
}
```

**What to do**:
- Add section to display written works in artist profile
- Use book-appropriate icons/layout
- Link to full work details

**Time**: 1.5 hours
**Affected files**: 1-2
**Dependencies**: WritingMetadata display

---

#### Step 1.7: Update Search/Discovery
**File**: `/packages/artbeat_artwork/lib/src/services/artwork_service.dart`

```dart
// Add filter to artwork queries
Future<List<ArtworkModel>> searchWrittenWorks(String query) async {
  return _firestore
      .collection('artworks')
      .where('contentType', isEqualTo: 'literature')
      .where('isPublic', isEqualTo: true)
      // Search in title, description, genre
      .get()
      .then((snapshot) => snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc.data()))
          .toList());
}

Future<List<ArtworkModel>> getWrittenWorksByGenre(String genre) async {
  return _firestore
      .collection('artworks')
      .where('contentType', isEqualTo: 'literature')
      .where('writingMetadata.genre', isEqualTo: genre)
      .get()
      .then((snapshot) => snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc.data()))
          .toList());
}
```

**What to do**:
- Add helper methods for literature queries
- Add filters to existing search
- Support genre filtering

**Time**: 1 hour
**Affected files**: 1-2
**Dependencies**: Firestore service

---

### **Phase 1 Summary**
| Task | Time | Complexity |
|------|------|-----------|
| 1.1: Extend ContentType | 30 min | Low |
| 1.2: WritingMetadata model | 1 hour | Low |
| 1.3: Extend ArtworkModel | 1.5 hours | Medium |
| 1.4: Upload UI | 2 hours | Medium |
| 1.5: Display UI | 2 hours | Medium |
| 1.6: Artist Profile | 1.5 hours | Low |
| 1.7: Search/Discovery | 1 hour | Low |
| **Total Phase 1** | **~9.5 hours** | **Achievable in 1-2 dev days** |

**Deliverable**: Writers can upload books/works and they're discoverable and visible in profiles.

---

### **Phase 2: Writing Features (2-4 weeks) - ENHANCE WRITING EXPERIENCE**

#### Step 2.1: Chapter Management
**New File**: `/packages/artbeat_artwork/lib/src/models/chapter_model.dart`

```dart
class ChapterModel {
  final String id;
  final String workId;          // Reference to parent work
  final int chapterNumber;
  final String title;
  final String content;         // Full text or excerpt
  final int wordCount;
  final DateTime publishedAt;
  final bool isPublished;       // Draft vs published
  final int viewCount;
  final EngagementStats engagement;

  ChapterModel({
    required this.id,
    required this.workId,
    required this.chapterNumber,
    required this.title,
    required this.content,
    required this.wordCount,
    required this.publishedAt,
    this.isPublished = true,
    this.viewCount = 0,
    required this.engagement,
  });

  // Serialization methods...
}
```

**Create chapter service** to manage chapter CRUD operations.

---

#### Step 2.2: Genre/Theme System
Create a genre taxonomy for filtering and discovery.

**File**: `/packages/artbeat_core/lib/src/models/genre_model.dart`

```dart
class GenreModel {
  final String id;
  final String name;
  final String description;
  final List<String> subgenres;  // Fantasy -> High Fantasy, Urban Fantasy
  final int workCount;

  const GenreModel({
    required this.id,
    required this.name,
    required this.description,
    required this.subgenres,
    this.workCount = 0,
  });
}
```

---

#### Step 2.3: Reading Metadata Expansion
Add to WritingMetadata:
- Series information (Book 1 of 5)
- Co-author relationships
- Beta reader status
- Content warnings
- Maturity rating

---

#### Step 2.4: Writing Community Features
- Writers' discussion forums
- Beta reader signup
- Feedback/review system
- Writing challenges

---

### **Phase 3: Advanced Features (Future)**
- Export to EPUB/PDF
- Reading progress sync
- Series management
- Co-author support
- Paid serialization (Patreon-like)
- Audio narration support

---

## 🛠️ Technical Details

### Database Schema Changes (Minimal)

Only need to add to Firestore `artworks` collection:

```dart
// Example document for a book
{
  id: "book_001",
  userId: "author_123",
  contentType: "literature",  // NEW value
  title: "My Novel Title",
  description: "Synopsis here...",
  imageUrl: "cover.jpg",
  
  // Writing-specific (optional metadata)
  writingMetadata: {
    genre: "Science Fiction",
    wordCount: 75000,
    estimatedReadMinutes: 450,
    language: "English",
    themes: ["space", "future", "humanity"],
    isSerializing: true,
    totalChapters: 12,
    releasedChapters: 5,
    excerpt: "First 500 words...",
    chapters: [
      { id: "ch_1", title: "Chapter 1", wordCount: 5000, publishedAt: timestamp },
      // ...
    ]
  },
  
  // Existing fields work as-is
  medium: "Novel",
  styles: ["Science Fiction", "Hard SF"],
  isForSale: true,
  price: 9.99,
  tags: ["scifi", "space", "indie"],
  // ... all other artwork fields
}
```

### Code Impact

**Minimal changes required**:
1. Extend enums (1 file)
2. Add WritingMetadata model (1 new file)
3. Update ArtworkModel (add optional field)
4. Update serialization methods (existing methods)
5. Conditional UI rendering (existing components)
6. Search/filter logic enhancements

**No database migrations** (backward compatible)

---

## 🚀 Why Option 3?

1. **Fast Entry** - Writers visible within 1-2 weeks
2. **Reuses Strengths** - Leverage working artist/commerce system
3. **Growth Path** - Can expand without disruption
4. **Low Risk** - Non-invasive to existing visual art features
5. **Community Benefit** - Brings new creative community to platform
6. **Economics** - Same revenue opportunities for writers

---

## ❓ Open Questions for Discussion

1. **Priority**: How soon do you want this live? (affects option choice)

2. **Scope**: Should we start with just uploading full works or chapter-by-chapter from day one?

3. **Pricing Model**: 
   - Same subscription tiers as visual artists?
   - Different pricing for serialized content?
   - Pay-per-chapter options?

4. **Community Integration**:
   - Should written works appear in main ARTbeat feed?
   - Separate "Writing" discovery section?
   - Mixed with visual art in collections?

5. **Features**:
   - Do you want chapter-level comments immediately or later?
   - Reading list/series support needed upfront?
   - Export capabilities (EPUB, PDF) in Phase 1 or Phase 3?

6. **Discoverability**:
   - How should genre tagging work?
   - Should there be curated book lists?
   - "Writers in your area" feature?

7. **Content Moderation**:
   - Adult content policies for mature books?
   - How does this differ from visual art moderation?

---

## 📝 Next Steps

1. **Review & Discuss**: Go through options, ask clarifying questions
2. **Decision**: Select implementation approach
3. **Scope Definition**: Detail exact Phase 1 scope
4. **Acceptance Criteria**: Define what "done" looks like
5. **Timeline**: Commit to delivery dates
6. **Kickoff**: Begin implementation

---

## 📚 Success Metrics

Phase 1 success (1-2 weeks):
- [ ] Writer can upload a manuscript/book
- [ ] Book appears in their artist profile with metadata
- [ ] Book is discoverable in ARTbeat search
- [ ] Basic engagement (views, comments) works
- [ ] Writer earns revenue if priced for sale

Phase 2 success (2-4 weeks):
- [ ] Writers can upload multi-chapter serialized works
- [ ] Chapter management UI functional
- [ ] Genre/theme discovery working
- [ ] At least 3 writers using the feature
- [ ] Community engagement (beta readers, feedback)

---

## References

- Current ArtworkModel: `/packages/artbeat_artwork/lib/src/models/artwork_model.dart`
- Artist profiles: `/packages/artbeat_artist/`
- Community features: `/packages/artbeat_community/`
- Existing serialization: Fields already in ArtworkModel
- Content type enum: `/packages/artbeat_artwork/lib/src/models/artwork_model.dart`

