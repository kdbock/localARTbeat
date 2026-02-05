import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show
        SubscriptionTier,
        ArtbeatColors,
        EnhancedUniversalHeader,
        MainLayout,
        AppLogger,
        FirestoreUtils,
        WritingMetadata;
import 'package:artbeat_artwork/artbeat_artwork.dart'
    show ArtworkService, ChapterService;
import '../widgets/upload_limit_upsell_dialog.dart';

// Rich text editing imports
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

enum WrittenContentUploadStep { content, chapters, basicInfo, details, review }

class WrittenContentUploadScreen extends StatefulWidget {
  final String? contentId;

  const WrittenContentUploadScreen({super.key, this.contentId});

  @override
  State<WrittenContentUploadScreen> createState() =>
      _WrittenContentUploadScreenState();
}

class _WrittenContentUploadScreenState
    extends State<WrittenContentUploadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Wizard state
  WrittenContentUploadStep _currentStep = WrittenContentUploadStep.content;
  int _currentStepIndex = 0;

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _tagController;
  late final TextEditingController _authorNoteController;
  late final TextEditingController _chaptersController;
  late final TextEditingController _volumeController;
  late final TextEditingController _chapterController;
  late final TextEditingController _seriesController;
  late final TextEditingController _isbnController;
  late final TextEditingController _publisherController;
  late final TextEditingController _editionController;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Services
  final ArtworkService _artworkService = ArtworkService();
  final ChapterService _chapterService = ChapterService();

  File? _coverImageFile;
  bool _isForSale = false;
  bool _isSerialized = false;
  bool _isLoading = false;
  bool _isExtractingChapters = false;
  int _artworkCount = 0;
  SubscriptionTier? _tierLevel;
  String? _userType;
  final List<String> _genres = [];
  final List<String> _tags = [];
  String _contentType = 'Book';
  String? _selectedGenre; // Store the primary genre
  int _totalChaptersPlanned = 1;
  String _releaseSchedule = 'immediate';

  // Content management
  File? _contentFile;
  String _contentText = '';
  bool _useFileUpload = true; // true for file upload, false for text input
  bool _useRichText = false; // true for rich text editor, false for plain text
  final List<Map<String, dynamic>> _chapters = []; // For serialized content

  // Rich text editor (markdown-based)
  final TextEditingController _richTextController = TextEditingController();

  // Validation
  int _wordCount = 0;
  int _estimatedReadingTime = 0;
  bool _isValidContent = false;

  final List<String> _availableGenres = [
    'Fiction',
    'Non-Fiction',
    'Romance',
    'Mystery',
    'Thriller',
    'Science Fiction',
    'Fantasy',
    'Horror',
    'Poetry',
    'Essay',
    'Biography',
    'Self-Help',
    'Children',
    'Young Adult',
  ];

  final List<String> _contentTypes = [
    'Book',
    'Serial Story',
    'Webtoon',
    'Audiobook',
  ];
  final List<String> _releaseSchedules = [
    'immediate',
    'weekly',
    'bi-weekly',
    'monthly',
    'custom',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _tagController = TextEditingController();
    _authorNoteController = TextEditingController();
    _chaptersController = TextEditingController(text: '1');
    _volumeController = TextEditingController();
    _chapterController = TextEditingController();
    _seriesController = TextEditingController();
    _isbnController = TextEditingController();
    _publisherController = TextEditingController();
    _editionController = TextEditingController();

    // Initialize rich text controller
    _richTextController.addListener(_onRichTextChanged);

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!mounted) return;

      setState(() {
        _userType = FirestoreUtils.safeString(userDoc.get('userType'));
        _tierLevel = SubscriptionTier.values.firstWhere(
          (tier) => tier.name == userDoc.get('subscriptionTier'),
          orElse: () => SubscriptionTier.free,
        );
      });

      final artworkDocs = await _firestore
          .collection('artwork')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      if (mounted) {
        setState(() {
          _artworkCount = artworkDocs.count ?? 0;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading user data: $e');
    }
  }

  bool get _canUpload {
    // Admins have unlimited uploads
    if (_userType == 'admin') return true;

    int limit = 3;
    switch (_tierLevel) {
      case SubscriptionTier.free:
        limit = 3;
        break;
      case SubscriptionTier.starter:
        limit = 25;
        break;
      case SubscriptionTier.creator:
        limit = 100;
        break;
      case SubscriptionTier.business:
      case SubscriptionTier.enterprise:
        limit = 999999;
        break;
      default:
        limit = 3;
    }
    return _artworkCount < limit;
  }

  // Content management methods
  Future<void> _selectContentFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _contentFile = File(result.files.single.path!);
          _contentText = '';
        });
        await _processContentFile();
      }
    } catch (e) {
      AppLogger.error('Error selecting content file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'written_content_upload_file_error'.tr(args: [e.toString()]),
            ),
          ),
        );
      }
    }
  }

  Future<void> _processContentFile() async {
    if (_contentFile == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing file...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    setState(() => _isExtractingChapters = true);

    try {
      String content = '';

      if (_contentFile!.path.toLowerCase().endsWith('.pdf')) {
        // PDF Processing
        final PdfDocument document = PdfDocument(
          inputBytes: await _contentFile!.readAsBytes(),
        );

        final int pageCount = document.pages.count;

        // Try high-level extraction first (faster)
        final extractor = PdfTextExtractor(document);
        String extractedText = '';
        
        try {
          extractedText = extractor.extractText();
        } catch (e) {
          AppLogger.error('High-level extraction failed: $e');
        }

        // If high-level extraction is poor, fallback to optimized page-by-page
        final initialWordCount = extractedText.trim().split(RegExp(r'\s+')).length;
        if ((extractedText.trim().length < 2000 || initialWordCount < pageCount * 5) && pageCount > 0) {
          final buffer = StringBuffer();
          for (int i = 0; i < pageCount; i++) {
            try {
              final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
              buffer.write(pageText);
              buffer.write('\n\n'); // Ensure page breaks and help regex matching
            } catch (e) {
              AppLogger.error('Error extracting page $i: $e');
            }
            // Yield to UI thread frequently to keep UI responsive
            if (i % 5 == 0) await Future<void>.delayed(const Duration(milliseconds: 10));
          }
          extractedText = buffer.toString();
        }

        content = extractedText;
        document.dispose();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Read $pageCount pages from PDF.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Plain text/markdown - handle encoding issues for professional manuscripts
        try {
          // Try UTF-8 first
          content = await _contentFile!.readAsString(encoding: utf8);
        } catch (e) {
          try {
            // Fallback to Latin-1/ISO-8859-1 which is common for legacy text files
            content = await _contentFile!.readAsString(encoding: latin1);
          } catch (e2) {
            // Last resort: read as bytes and convert lossily
            final bytes = await _contentFile!.readAsBytes();
            content = String.fromCharCodes(bytes);
          }
        }
      }

      await _validateAndProcessContent(content);

      if (mounted) {
        final wordCount = content.trim().split(RegExp(r'\s+')).length;
        if (wordCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully extracted $wordCount words.'),
              backgroundColor: ArtbeatColors.primaryGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Warning: No text could be extracted from this PDF.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      // Attempt automatic chapter extraction if it's a novel/long work
      _extractChaptersFromText(content);

      // Force move to Review Chapters step if content was uploaded
      if (mounted) {
        setState(() {
          _currentStepIndex = 1;
          _currentStep = WrittenContentUploadStep.chapters;
        });
        
        // If extraction was very poor, warn the user
        final wordCount = content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        if (wordCount < 200 && _contentFile != null && _contentFile!.path.toLowerCase().endsWith('.pdf')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Warning: Very little text found in PDF. It might be an image-based scan.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error processing content file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExtractingChapters = false);
      }
    }
  }

  void _extractChaptersFromText(String content) {
    AppLogger.info('Starting chapter extraction from ${content.length} characters');
    
    // Broadened Regex to find chapter markers more reliably in various PDF formats
    final chapterRegex = RegExp(
      r'(?:^|\n)\s*((?:CHAPTER|PART|BOOK|PROLOGUE|EPILOGUE|SECTION|VOLUME)\b.*)',
      multiLine: true,
      caseSensitive: false,
    );

    // Secondary regex for cases where it's just a number or Roman numeral on its own line
    final secondaryRegex = RegExp(
      r'(?:^|\n)\s*(\b(?:\d+|[IVXLCDM]+)\b)\s*$',
      multiLine: true,
      caseSensitive: false,
    );

    var matches = chapterRegex.allMatches(content).toList();
    AppLogger.info('Primary matches found: ${matches.length}');

    // If no standard markers found, try the secondary numeric-only markers
    if (matches.isEmpty) {
      matches = secondaryRegex.allMatches(content).toList();
      AppLogger.info('Secondary matches found: ${matches.length}');
    }

    if (matches.isEmpty) {
      AppLogger.info('No chapter markers found, falling back to single chapter');
      // Diagnostic fallback: if text is long but no chapters found, notify user
      if (content.length > 5000 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No chapter markers detected. Try adding "Chapter" before your titles.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (content.trim().length < 500 && mounted) {
        // Warning for likely image-only PDFs
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Very little text found. If this is a novel, your PDF might be an image scan. Try uploading a .txt or .md file.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Fallback: Just one big chapter if nothing found
      final singleChapter = {
        'number': 1,
        'title': _titleController.text.isNotEmpty
            ? _titleController.text
            : 'Chapter 1',
        'content': content,
        'wordCount': content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
        'readingTime': (content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length / 200).ceil(),
      };

      if (mounted) {
        setState(() {
          _chapters.clear();
          _chapters.add(singleChapter);
          _isSerialized = false;
          _totalChaptersPlanned = 1;
        });
      }
      return;
    }

    final List<Map<String, dynamic>> extractedChapters = [];

    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : content.length;

      // Use group(1) to get the title without leading newlines/whitespace
      String chapterTitle = matches[i].group(1)?.trim() ?? 'Chapter ${i + 1}';

      // If the title is just a number or Roman numeral, prepend "Chapter " for better display
      if (RegExp(r'^\s*(?:\d+|[IVXLCDM]+)\s*$').hasMatch(chapterTitle)) {
        chapterTitle = 'Chapter $chapterTitle';
      }

      final chapterContent = content.substring(start, end).trim();
      final words = chapterContent.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);

      extractedChapters.add({
        'number': i + 1,
        'title': chapterTitle,
        'content': chapterContent,
        'wordCount': words.length,
        'readingTime': (words.length / 200).ceil(),
      });
    }

    if (mounted) {
      setState(() {
        _chapters.clear();
        _chapters.addAll(extractedChapters);
        _isSerialized = extractedChapters.length > 1;
        _totalChaptersPlanned = extractedChapters.length;
        _chaptersController.text = _totalChaptersPlanned.toString();
      });
    }

    AppLogger.info('Successfully extracted ${extractedChapters.length} chapters');
    if (mounted && extractedChapters.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Extracted ${extractedChapters.length} chapters automatically.',
          ),
          backgroundColor: ArtbeatColors.primaryGreen,
        ),
      );
    }
  }

  Future<void> _validateAndProcessContent(String content) async {
    // Basic validation
    if (content.trim().isEmpty) {
      setState(() => _isValidContent = false);
      return;
    }

    // Calculate word count and reading time
    final words = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final wordCount = words.length;
    final readingTime = (wordCount / 200).ceil(); // ~200 words per minute

    // Plagiarism prevention: Check for duplicate content
    final contentHash = _generateContentHash(content);
    final isDuplicate = await _checkForDuplicateContent(contentHash);

    setState(() {
      _wordCount = wordCount;
      _estimatedReadingTime = readingTime;
      _isValidContent = !isDuplicate && wordCount > 10; // Minimum 10 words
      if (_useFileUpload) {
        _contentText = content;
      }
    });

    if (isDuplicate && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('written_content_upload_duplicate_warning'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _generateContentHash(String content) {
    // Simple hash for duplicate detection
    return content.hashCode.toString();
  }

  Future<bool> _checkForDuplicateContent(String contentHash) async {
    try {
      // Check recent uploads for similar content
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final recentArtworks = await _firestore
          .collection('artwork')
          .where('userId', isEqualTo: userId)
          .where('contentType', isEqualTo: 'written')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      for (final doc in recentArtworks.docs) {
        final existingHash = doc.data()['contentHash'];
        if (existingHash == contentHash) {
          return true;
        }
      }
      return false;
    } catch (e) {
      AppLogger.error('Error checking for duplicate content: $e');
      return false;
    }
  }

  void _toggleContentInputMode() {
    setState(() {
      _useFileUpload = !_useFileUpload;
      if (_useFileUpload) {
        _contentText = '';
      } else {
        _contentFile = null;
      }
      _isValidContent = false;
    });
  }

  void _toggleRichTextMode() {
    setState(() {
      _useRichText = !_useRichText;
      if (_useRichText) {
        // Switch to rich text mode - copy content to rich text controller
        _richTextController.text = _contentText;
      } else {
        // Switch to plain text mode - copy content back
        _contentText = _richTextController.text;
      }
    });
  }

  void _onRichTextChanged() {
    if (_useRichText) {
      _contentText = _richTextController.text;
      _validateAndProcessContent(_contentText);
    }
  }

  void _insertMarkdownFormatting(String prefix, String suffix) {
    final controller = _richTextController;
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) return;

    final beforeText = text.substring(0, selection.start);
    final selectedText = text.substring(selection.start, selection.end);
    final afterText = text.substring(selection.end);

    final newText = '$beforeText$prefix$selectedText$suffix$afterText';
    controller.text = newText;

    // Update cursor position
    final newCursorPos =
        selection.start + prefix.length + selectedText.length + suffix.length;
    controller.selection = TextSelection.collapsed(offset: newCursorPos);
  }

  Future<void> _selectCoverImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _coverImageFile = File(image.path);
        });
      }
    } catch (e) {
      AppLogger.error('Error selecting cover image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'written_content_upload_image_error'.tr(args: [e.toString()]),
            ),
          ),
        );
      }
    }
  }

  Future<void> _uploadContent() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('written_content_upload_validation_error'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_coverImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('written_content_upload_no_image_error'.tr())),
      );
      return;
    }

    if (!_isValidContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('written_content_upload_invalid_content'.tr())),
      );
      return;
    }

    if (!_canUpload) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => UploadLimitUpsellDialog(
          userId: _auth.currentUser?.uid ?? '',
          currentTier: _tierLevel ?? SubscriptionTier.free,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    AppLogger.info('Starting content upload process...');

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');

      // Create artwork using ArtworkService
      AppLogger.info('Step 1: Uploading basic artwork data and cover image...');
      final artworkId = await _artworkService.uploadArtwork(
        imageFile: _coverImageFile!,
        title: _titleController.text,
        description: _descriptionController.text,
        medium: 'Written Work',
        styles: _genres,
        tags: _tags,
        price: _isForSale ? double.tryParse(_priceController.text) ?? 0.0 : 0.0,
        isForSale: _isForSale,
      );
      AppLogger.info('Artwork created with ID: $artworkId');

      // Create WritingMetadata for this work
      AppLogger.info('Step 2: Preparing writing metadata...');
      final writingMetadata = WritingMetadata(
        genre: _selectedGenre,
        wordCount: _wordCount,
        estimatedReadMinutes: _estimatedReadingTime,
        language: 'English',
        themes: _genres,
        isSerializing: _isSerialized,
        excerpt: _contentText.length > 500
            ? _contentText.substring(0, 500)
            : _contentText,
        firstPublishedDate: DateTime.now(),
        hasMultipleChapters: _isSerialized || _chapters.length > 1,
        isbn: _isbnController.text.isNotEmpty ? _isbnController.text : null,
        seriesName:
            _seriesController.text.isNotEmpty ? _seriesController.text : null,
        volumeNumber: _volumeController.text.isNotEmpty
            ? int.tryParse(_volumeController.text)
            : null,
        publisher:
            _publisherController.text.isNotEmpty
                ? _publisherController.text
                : null,
        edition:
            _editionController.text.isNotEmpty ? _editionController.text : null,
      );

      // Update artwork metadata for written content
      AppLogger.info('Step 3: Updating artwork with writing metadata...');
      final updatedData = {
        'contentType': 'written',
        'writingMetadata': writingMetadata.toJson(),
        'isSerializing': _isSerialized,
        'totalChapters': _isSerialized ? _chapters.length : 1,
        'releasedChapters': 0,
        'readingMetadata': {
          'wordCount': _wordCount,
          'estimatedReadingTime': _estimatedReadingTime,
          'language': 'en',
          'contentFormat': _useFileUpload ? 'file' : 'text',
        },
        'serializationConfig': _isSerialized
            ? {
                'releaseSchedule': _releaseSchedule,
                'startDate': DateTime.now().toIso8601String(),
              }
            : null,
        'contentHash': _generateContentHash(_contentText),
        'authorNote': _authorNoteController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('artwork')
          .doc(artworkId)
          .update(updatedData);
      AppLogger.info('Artwork metadata updated successfully');

      // Create chapters
      AppLogger.info('Step 4: Creating chapters (${_chapters.length})...');
      if (_chapters.isNotEmpty) {
        await _createChaptersForArtwork(artworkId);
      } else if (!_isSerialized) {
        AppLogger.info('No chapters found, creating single chapter for complete work...');
        // Create single chapter for complete work
        await _chapterService.createChapter(
          artworkId: artworkId,
          chapterNumber: 1,
          title: _titleController.text,
          description: _descriptionController.text,
          content: _contentText,
          estimatedReadingTime: _estimatedReadingTime,
          wordCount: _wordCount,
          releaseDate: DateTime.now(),
          tags: _tags,
        );
      }

      AppLogger.info('Upload process completed successfully!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('written_content_upload_success'.tr()),
            backgroundColor: ArtbeatColors.primaryGreen,
          ),
        );
        Navigator.of(context).pop(artworkId);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error uploading content: $e');
      AppLogger.error('Stack trace: $stackTrace');
      if (mounted) {
        final errorStr = e.toString();

        // Check for upload limit error to show upsell dialog
        if (errorStr.contains('maximum number of artworks') ||
            errorStr.contains('upload limit')) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => UploadLimitUpsellDialog(
              userId: _auth.currentUser?.uid ?? '',
              currentTier: _tierLevel ?? SubscriptionTier.free,
            ),
          );
          return;
        }

        // Robust error message display for other errors
        final String errorMsg = errorStr.replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'written_content_upload_error'.tr(args: [errorMsg]),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Upload Error'),
                    content: SingleChildScrollView(
                      child: Text('$e\n\n$stackTrace'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createChaptersForArtwork(String artworkId) async {
    if (_chapters.isEmpty) return;

    for (final chapter in _chapters) {
      await _chapterService.createChapter(
        artworkId: artworkId,
        chapterNumber: chapter['number'] as int,
        title: chapter['title'] as String,
        description: (chapter['content'] as String).substring(
          0,
          100.clamp(0, (chapter['content'] as String).length),
        ),
        content: chapter['content'] as String,
        estimatedReadingTime: chapter['readingTime'] as int,
        wordCount: chapter['wordCount'] as int,
        releaseDate: DateTime.now().add(
          Duration(days: 7 * ((chapter['number'] as int) - 1)),
        ),
        tags: _tags,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: EnhancedUniversalHeader(
          title: 'written_content_upload_title'.tr(),
          showLogo: false,
          showBackButton: true,
        ),
        body: Column(
          children: [
            if (!_canUpload)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'written_content_upload_limit'.tr(),
                  style: TextStyle(color: Colors.orange[800]),
                ),
              ),
            Expanded(
              child: Form(
                key: _formKey,
                child: Stepper(
                  currentStep: _currentStepIndex,
                  onStepContinue: _onStepContinue,
                  onStepCancel: _onStepCancel,
                  onStepTapped: _onStepTapped,
                  controlsBuilder: _buildStepperControls,
                  steps: [
                    Step(
                      title: Text('written_content_upload_step_content'.tr()),
                      subtitle: Text(
                        'written_content_upload_step_content_desc'.tr(),
                      ),
                      content: _buildContentStep(),
                      isActive: _currentStepIndex >= 0,
                      state: _getStepState(0),
                    ),
                    Step(
                      title: const Text('Review Chapters'),
                      subtitle: const Text('Manage extracted sections for your novel'),
                      content: _buildChaptersStep(),
                      isActive: _currentStepIndex >= 1,
                      state: _getStepState(1),
                    ),
                    Step(
                      title: Text('written_content_upload_step_basic_info'.tr()),
                      subtitle: Text(
                        'written_content_upload_step_basic_info_desc'.tr(),
                      ),
                      content: _buildBasicInfoStep(),
                      isActive: _currentStepIndex >= 2,
                      state: _getStepState(2),
                    ),
                    Step(
                      title: Text('written_content_upload_step_details'.tr()),
                      subtitle: Text(
                        'written_content_upload_step_details_desc'.tr(),
                      ),
                      content: _buildDetailsStep(),
                      isActive: _currentStepIndex >= 3,
                      state: _getStepState(3),
                    ),
                    Step(
                      title: Text('written_content_upload_step_review'.tr()),
                      subtitle: Text(
                        'written_content_upload_step_review_desc'.tr(),
                      ),
                      content: _buildReviewStep(),
                      isActive: _currentStepIndex >= 4,
                      state: _getStepState(4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  StepState _getStepState(int stepIndex) {
    if (stepIndex < _currentStepIndex) {
      return StepState.complete;
    } else if (stepIndex == _currentStepIndex) {
      return StepState.editing;
    } else {
      return StepState.indexed;
    }
  }

  Widget _buildStepperControls(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          if (_currentStepIndex > 0)
            SizedBox(
              width: 100,
              child: OutlinedButton(
                onPressed: details.onStepCancel,
                child: Text('written_content_upload_back'.tr()),
              ),
            ),
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: (_isLoading || _isExtractingChapters)
                  ? null
                  : (_currentStepIndex == 4
                      ? _uploadContent
                      : details.onStepContinue),
              child: (_isLoading || _isExtractingChapters)
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _currentStepIndex == 4
                          ? 'written_content_upload_button'.tr()
                          : 'written_content_upload_continue'.tr(),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateWordCount() {
    final text = _useRichText ? _richTextController.text : _contentText;
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    setState(() {
      _wordCount = words;
      _estimatedReadingTime = (words / 200).ceil(); // Average reading speed
    });
  }

  void _onStepContinue() {
    if (_currentStepIndex < 4) {
      // Validate step-specific logic
      final bool isStepValid = _validateCurrentStep();

      // For form validation, only validate if we're on step 3+ and only validate
      // fields that are on step 3 (basicInfo). Don't validate future steps yet.
      final bool isFormValid = _currentStepIndex == 2
          ? (_titleController.text.isNotEmpty &&
              _descriptionController.text.isNotEmpty &&
              _coverImageFile != null)
          : (_currentStepIndex >= 3
              ? (_formKey.currentState?.validate() ?? true)
              : true);

      if (isFormValid && isStepValid) {
        setState(() {
          _currentStepIndex += 1;
          _currentStep = WrittenContentUploadStep.values[_currentStepIndex];
        });
      } else {
        // Show specific feedback if step validation failed but form might be valid
        if (!isStepValid) {
          _showStepValidationError();
        }
      }
    }
  }

  void _showStepValidationError() {
    String message = 'Please complete all required fields';
    
    switch (_currentStep) {
      case WrittenContentUploadStep.content:
        message = _useFileUpload 
            ? 'Please select a content file' 
            : 'Please enter your content text';
        break;
      case WrittenContentUploadStep.chapters:
        message = 'Please ensure at least one chapter is defined';
        break;
      case WrittenContentUploadStep.basicInfo:
        if (_coverImageFile == null) {
          message = 'Please upload a cover image';
        } else if (_titleController.text.isEmpty) {
          message = 'Please enter a title';
        } else if (_descriptionController.text.isEmpty) {
          message = 'Please enter a description';
        }
        break;
      case WrittenContentUploadStep.details:
        if (_selectedGenre == null || _selectedGenre!.isEmpty) {
          message = 'Please select a primary genre';
        } else if (_genres.isEmpty) {
          message = 'Please select at least one genre/theme';
        }
        break;
      default:
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onStepCancel() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex -= 1;
        _currentStep = WrittenContentUploadStep.values[_currentStepIndex];
      });
    }
  }

  void _onStepTapped(int stepIndex) {
    if (stepIndex <= _currentStepIndex) {
      setState(() {
        _currentStepIndex = stepIndex;
        _currentStep = WrittenContentUploadStep.values[stepIndex];
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case WrittenContentUploadStep.content:
        return (_useFileUpload && _contentFile != null) ||
            (!_useFileUpload &&
                (_contentText.isNotEmpty ||
                    _richTextController.text.isNotEmpty));
      case WrittenContentUploadStep.chapters:
        return _chapters.isNotEmpty;
      case WrittenContentUploadStep.basicInfo:
        return _titleController.text.isNotEmpty &&
            _descriptionController.text.isNotEmpty &&
            _coverImageFile != null;
      case WrittenContentUploadStep.details:
        return _genres.isNotEmpty && (_selectedGenre?.isNotEmpty ?? false);
      case WrittenContentUploadStep.review:
        return true;
    }
  }

  Widget _buildChaptersStep() {
    if (_isExtractingChapters) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing document and extracting chapters...'),
            ],
          ),
        ),
      );
    }

    if (_chapters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(Icons.auto_stories, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No chapters extracted yet. Upload a PDF or add content to begin.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _chapters.add({
                      'number': 1,
                      'title': 'Chapter 1',
                      'content': _contentText,
                      'wordCount': _wordCount,
                      'readingTime': _estimatedReadingTime,
                    });
                  });
                },
                child: const Text('Add Single Chapter Manually'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              'Extracted Chapters (${_chapters.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _chapters.add({
                    'number': _chapters.length + 1,
                    'title': 'Chapter ${_chapters.length + 1}',
                    'content': '',
                    'wordCount': 0,
                    'readingTime': 0,
                  });
                });
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Chapter', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Review and edit the chapter titles and order before uploading.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _chapters.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final chapter = _chapters[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: ArtbeatColors.primaryGreen.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      '${chapter['number']}',
                      style: const TextStyle(
                        color: ArtbeatColors.primaryGreen,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          initialValue: chapter['title'] as String?,
                          decoration: const InputDecoration(
                            labelText: 'Chapter Title',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (value) {
                            _chapters[index]['title'] = value;
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Words: ${chapter['wordCount']} | Est. Read: ${chapter['readingTime']}m',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _chapters.removeAt(index);
                        // Re-number
                        for (int i = 0; i < _chapters.length; i++) {
                          _chapters[i]['number'] = i + 1;
                        }
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'written_content_upload_content_step_title'.tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'written_content_upload_content_step_description'.tr(),
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Content type
        Text(
          'written_content_upload_content_type_label'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _contentType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            labelText: 'written_content_upload_content_type_label'.tr(),
            labelStyle: const TextStyle(color: Colors.black87),
          ),
          style: const TextStyle(color: Colors.black87),
          items: _contentTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _contentType = value ?? 'Book';
            });
          },
        ),
        const SizedBox(height: 24),

        // Content input mode toggle
        Text(
          'written_content_upload_content_section'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _toggleContentInputMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _useFileUpload
                      ? ArtbeatColors.primaryGreen
                      : Colors.grey,
                ),
                child: Text('written_content_upload_file_mode'.tr()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _toggleContentInputMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_useFileUpload
                      ? ArtbeatColors.primaryGreen
                      : Colors.grey,
                ),
                child: Text('written_content_upload_text_mode'.tr()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Content input area
        if (_useFileUpload) ...[
          GestureDetector(
            onTap: _selectContentFile,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _contentFile != null
                      ? ArtbeatColors.primaryGreen
                      : Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _contentFile != null
                          ? Icons.file_present
                          : Icons.file_upload,
                      size: 32,
                      color: _contentFile != null
                          ? ArtbeatColors.primaryGreen
                          : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _contentFile != null
                          ? _contentFile!.path.split('/').last
                          : 'written_content_upload_select_file'.tr(),
                      style: TextStyle(
                        color: _contentFile != null
                            ? ArtbeatColors.primaryGreen
                            : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          // Rich text toggle
          Center(
            child: ElevatedButton.icon(
              onPressed: _toggleRichTextMode,
              icon: Icon(_useRichText ? Icons.text_fields : Icons.format_bold),
              label: Text(
                _useRichText
                    ? 'written_content_upload_plain_text_mode'.tr()
                    : 'written_content_upload_rich_text_mode'.tr(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _useRichText
                    ? ArtbeatColors.primaryGreen
                    : Colors.grey[300],
                foregroundColor: _useRichText ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_useRichText) ...[
            // Rich text editor
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Formatting toolbar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.format_bold),
                            onPressed: () =>
                                _insertMarkdownFormatting('**', '**'),
                            tooltip: 'Bold',
                          ),
                          IconButton(
                            icon: const Icon(Icons.format_italic),
                            onPressed: () => _insertMarkdownFormatting('*', '*'),
                            tooltip: 'Italic',
                          ),
                          IconButton(
                            icon: const Icon(Icons.title),
                            onPressed: () => _insertMarkdownFormatting('# ', ''),
                            tooltip: 'Header',
                          ),
                          IconButton(
                            icon: const Icon(Icons.link),
                            onPressed: () =>
                                _insertMarkdownFormatting('[', '](url)'),
                            tooltip: 'Link',
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Editor area
                  Expanded(
                    child: TextField(
                      controller: _richTextController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                        hintText: 'Start writing your content...',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            TextFormField(
              initialValue: _contentText,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: 'written_content_upload_content_label'.tr(),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged: (value) {
                _contentText = value;
                _updateWordCount();
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'written_content_upload_basic_info_step_title'.tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'written_content_upload_basic_info_step_description'.tr(),
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Cover image
        Text(
          'written_content_upload_cover_image_label'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectCoverImage,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: _coverImageFile != null
                    ? ArtbeatColors.primaryGreen
                    : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _coverImageFile != null
                ? Image.file(_coverImageFile!, fit: BoxFit.cover)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: _coverImageFile != null
                              ? ArtbeatColors.primaryGreen
                              : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'written_content_upload_cover_image_hint'.tr(),
                          style: TextStyle(
                            color: _coverImageFile != null
                                ? ArtbeatColors.primaryGreen
                                : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),

        // Title
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'written_content_upload_title_label'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'written_content_upload_title_required'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'written_content_upload_description_label'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 4,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'written_content_upload_description_required'.tr();
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'written_content_upload_details_step_title'.tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'written_content_upload_details_step_description'.tr(),
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Novel identifiers
        Text(
          'Novel Identifiers',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _isbnController,
          decoration: InputDecoration(
            labelText: 'ISBN',
            hintText: 'Enter 13-digit ISBN if available',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _publisherController,
                decoration: InputDecoration(
                  labelText: 'Publisher',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _editionController,
                decoration: InputDecoration(
                  labelText: 'Edition',
                  hintText: 'e.g. First Edition',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Series info
        Text(
          'Series Information',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _seriesController,
                decoration: InputDecoration(
                  labelText: 'Series Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _volumeController,
                decoration: InputDecoration(
                  labelText: 'Volume #',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Author note
        TextFormField(
          controller: _authorNoteController,
          decoration: InputDecoration(
            labelText: 'written_content_upload_author_note_label'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 24),

        // Primary Genre Selection
        Text('Primary Genre', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _selectedGenre,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            labelText: 'Select Primary Genre',
            hintText: 'Choose the main genre for this work',
          ),
          items: _availableGenres.map((genre) {
            return DropdownMenuItem(value: genre, child: Text(genre));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGenre = value;
              // Automatically add primary genre to themes if not already there
              if (value != null && !_genres.contains(value)) {
                _genres.add(value);
              }
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a primary genre';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        // Additional Themes
        Text(
          'written_content_upload_genres_label'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _availableGenres.map((genre) {
            final isSelected = _genres.contains(genre);
            return FilterChip(
              label: Text(genre),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _genres.add(genre);
                  } else {
                    _genres.remove(genre);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Serialized content
        CheckboxListTile(
          title: Text('written_content_upload_serialized_checkbox'.tr()),
          subtitle: Text('written_content_upload_serialized_hint'.tr()),
          value: _isSerialized,
          onChanged: (value) {
            setState(() {
              _isSerialized = value ?? false;
            });
          },
        ),
        if (_isSerialized) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _chaptersController,
            decoration: InputDecoration(
              labelText: 'written_content_upload_chapters_label'.tr(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _totalChaptersPlanned = int.tryParse(value) ?? 1;
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'written_content_upload_schedule_label'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _releaseSchedule,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              labelText: 'written_content_upload_schedule_label'.tr(),
              labelStyle: const TextStyle(color: Colors.black87),
            ),
            style: const TextStyle(color: Colors.black87),
            items: _releaseSchedules.map((schedule) {
              return DropdownMenuItem(
                value: schedule,
                child: Text(schedule.replaceAll('_', ' ').toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _releaseSchedule = value ?? 'immediate';
              });
            },
          ),
        ],
        const SizedBox(height: 24),

        // For sale
        CheckboxListTile(
          title: Text('written_content_upload_for_sale_checkbox'.tr()),
          value: _isForSale,
          onChanged: (value) {
            setState(() {
              _isForSale = value ?? false;
            });
          },
        ),
        if (_isForSale) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: 'written_content_upload_price_label'.tr(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixText: '\$ ',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_isForSale && (value?.isEmpty ?? true)) {
                return 'written_content_upload_price_required'.tr();
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'written_content_upload_review_step_title'.tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'written_content_upload_review_step_description'.tr(),
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Content preview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'written_content_upload_content_preview'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_useFileUpload && _contentFile != null) ...[
                  Text('File: ${_contentFile!.path.split('/').last}'),
                ] else if (_useRichText &&
                    _richTextController.text.isNotEmpty) ...[
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: MarkdownBody(
                        data: _richTextController.text,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 14),
                          h1: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          h2: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else if (_contentText.isNotEmpty) ...[
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: Text(_contentText),
                    ),
                  ),
                ] else ...[
                  Text('art_walk_no_content_provided'.tr()),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Basic info summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'written_content_upload_basic_info_summary'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_coverImageFile != null) ...[
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.file(_coverImageFile!, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Title: ${_titleController.text}',
                  softWrap: true,
                ),
                Text(
                  'Description: ${_descriptionController.text}',
                  softWrap: true,
                ),
                Text('Type: $_contentType'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Details summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'written_content_upload_details_summary'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_isbnController.text.isNotEmpty)
                  Text('ISBN: ${_isbnController.text}'),
                if (_publisherController.text.isNotEmpty)
                  Text(
                    'Publisher: ${_publisherController.text}',
                    softWrap: true,
                  ),
                if (_editionController.text.isNotEmpty)
                  Text('Edition: ${_editionController.text}', softWrap: true),
                if (_seriesController.text.isNotEmpty)
                  Text(
                    'Series: ${_seriesController.text} ${_volumeController.text.isNotEmpty ? "Vol. ${_volumeController.text}" : ""}',
                    softWrap: true,
                  ),
                if (_authorNoteController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Author Note: ${_authorNoteController.text}',
                    softWrap: true,
                  ),
                ],
                const SizedBox(height: 8),
                Text('Genres: ${_genres.join(", ")}', softWrap: true),
                Text('Total Chapters: ${_chapters.length}'),
                if (_isSerialized)
                  Text(
                    'Schedule: ${_releaseSchedule.replaceAll('_', ' ').toUpperCase()}',
                  ),
                if (_isForSale) ...[Text('Price: \$${_priceController.text}')],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _tagController.dispose();
    _authorNoteController.dispose();
    _chaptersController.dispose();
    _volumeController.dispose();
    _chapterController.dispose();
    _seriesController.dispose();
    _isbnController.dispose();
    _publisherController.dispose();
    _editionController.dispose();
    super.dispose();
  }
}
