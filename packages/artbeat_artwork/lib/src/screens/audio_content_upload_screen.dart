import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
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
        AppLogger;
import 'package:artbeat_artwork/artbeat_artwork.dart' show ArtworkService;

// Audio processing imports - simplified for now
import 'package:permission_handler/permission_handler.dart';

enum AudioContentUploadStep {
  content,
  basicInfo,
  details,
  review,
}

class AudioContentUploadScreen extends StatefulWidget {
  final String? contentId;

  const AudioContentUploadScreen({
    super.key,
    this.contentId,
  });

  @override
  State<AudioContentUploadScreen> createState() =>
      _AudioContentUploadScreenState();
}

class _AudioContentUploadScreenState extends State<AudioContentUploadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Wizard state
  AudioContentUploadStep _currentStep = AudioContentUploadStep.content;
  int _currentStepIndex = 0;

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _lyricsController;
  late final TextEditingController _albumTitleController;
  late final TextEditingController _albumDescriptionController;
  late final TextEditingController _trackNumberController;
  late final TextEditingController _isrcController;
  late final TextEditingController _composerController;
  late final TextEditingController _producerController;
  late final TextEditingController _studioController;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Services
  final ArtworkService _artworkService = ArtworkService();

  File? _coverImageFile;
  bool _isForSale = false;
  bool _isAlbum = false;
  int _artworkCount = 0;
  SubscriptionTier? _tierLevel;
  final List<String> _genres = [];
  String _contentType = 'Music';
  String _releaseSchedule = 'immediate';

  // Audio management
  File? _audioFile;
  bool _useFileUpload = true; // true for file upload, false for recording
  bool _isRecording = false;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  final Duration _currentPosition = Duration.zero;
  String _recordingTime = '00:00';
  Timer? _recordingTimer;

  // Audio metadata
  String _audioFormat = '';
  int _fileSize = 0;
  final int _bitrate = 0;
  final int _sampleRate = 0;
  bool _isValidAudio = false;

  // Waveform data
  Uint8List? _waveformData;
  bool _isGeneratingWaveform = false;

  final List<String> _availableGenres = [
    'Pop',
    'Rock',
    'Hip Hop',
    'R&B',
    'Jazz',
    'Classical',
    'Electronic',
    'Country',
    'Folk',
    'Reggae',
    'Blues',
    'World Music',
    'Spoken Word',
    'Podcast',
    'Audiobook',
    'Soundtrack',
    'Ambient',
    'Experimental',
  ];

  final List<String> _contentTypes = [
    'Music',
    'Podcast',
    'Audiobook',
    'Soundtrack',
    'Spoken Word'
  ];
  final List<String> _releaseSchedules = [
    'immediate',
    'weekly',
    'bi-weekly',
    'monthly',
    'custom'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _lyricsController = TextEditingController();
    _albumTitleController = TextEditingController();
    _albumDescriptionController = TextEditingController();
    _trackNumberController = TextEditingController();
    _isrcController = TextEditingController();
    _composerController = TextEditingController();
    _producerController = TextEditingController();
    _studioController = TextEditingController();

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!mounted) return;

      setState(() {
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

  // Audio management methods
  Future<void> _selectAudioFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _audioFile = File(result.files.single.path!);
          _useFileUpload = true;
        });
        await _processAudioFile();
      }
    } catch (e) {
      AppLogger.error('Error selecting audio file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'audio_content_upload_file_error'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  Future<void> _processAudioFile() async {
    if (_audioFile == null) return;

    try {
      setState(() => _isGeneratingWaveform = true);

      // Extract basic metadata
      final fileSize = await _audioFile!.length();
      final fileName = _audioFile!.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();

      // Basic validation
      if (!_isValidAudioFormat(extension)) {
        setState(() => _isValidAudio = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('audio_content_upload_unsupported_format'.tr())),
          );
        }
        return;
      }

      // Check file size (50MB for free, 200MB for premium)
      final maxSize = _tierLevel == SubscriptionTier.free
          ? 50 * 1024 * 1024
          : 200 * 1024 * 1024;
      if (fileSize > maxSize) {
        setState(() => _isValidAudio = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('audio_content_upload_file_too_large'.tr(args: [
              maxSize > 1024 * 1024 * 1024
                  ? '${maxSize ~/ (1024 * 1024 * 1024)}GB'
                  : '${maxSize ~/ (1024 * 1024)}MB'
            ]))),
          );
        }
        return;
      }

      // Generate waveform data (simplified - in real implementation would use audio processing library)
      await _generateWaveformData();

      setState(() {
        _fileSize = fileSize;
        _audioFormat = extension.toUpperCase();
        _isValidAudio = true;
        _isGeneratingWaveform = false;
        // Mock duration for now
        _audioDuration = const Duration(minutes: 3, seconds: 45);
      });
    } catch (e) {
      AppLogger.error('Error processing audio file: $e');
      setState(() => _isGeneratingWaveform = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('audio_content_upload_process_error'
                  .tr(args: [e.toString()]))),
        );
      }
    }
  }

  bool _isValidAudioFormat(String extension) {
    const validFormats = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'];
    return validFormats.contains(extension);
  }

  Future<void> _generateWaveformData() async {
    // This is a placeholder - in a real implementation, you would:
    // 1. Use a library like flutter_ffmpeg or audio_waveforms to extract waveform data
    // 2. Process the audio file to generate waveform visualization
    // 3. Store the waveform data for display

    // For now, we'll create a simple mock waveform
    await Future<void>.delayed(
        const Duration(seconds: 2)); // Simulate processing time

    // Mock waveform data - in reality this would be actual audio waveform samples
    final mockWaveform = List.generate(100, (index) => (index % 20) + 10);
    setState(() {
      _waveformData = Uint8List.fromList(mockWaveform);
    });
  }

  Future<void> _togglePlayback() async {
    // Placeholder for audio playback toggle
    setState(() => _isPlaying = !_isPlaying);
    // In a real implementation, this would control audio playback
  }

  Future<void> _stopPlayback() async {
    // Placeholder for stopping audio playback
    setState(() => _isPlaying = false);
    // In a real implementation, this would stop audio playback
  }

  Future<bool> _requestRecordingPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _requestRecordingPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'audio_content_upload_recording_permission_denied'.tr())),
          );
        }
        return;
      }

      // Placeholder for recording start
      // In a real implementation, this would start audio recording
      setState(() {
        _isRecording = true;
        _recordingTime = '00:00';
      });

      // Start timer to update recording time
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          final seconds = timer.tick;
          final minutes = seconds ~/ 60;
          final remainingSeconds = seconds % 60;
          setState(() {
            _recordingTime =
                '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
          });
        }
      });
    } catch (e) {
      AppLogger.error('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('audio_content_upload_recording_failed'.tr())),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      // Placeholder for recording stop
      // In a real implementation, this would stop recording and return the file path
      _recordingTimer?.cancel();

      // Mock recorded file
      final mockPath =
          '/mock/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      setState(() {
        _audioFile = File(mockPath);
        _isRecording = false;
        _useFileUpload = false;
      });
      await _processAudioFile();
    } catch (e) {
      AppLogger.error('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('audio_content_upload_recording_failed'.tr())),
        );
      }
    }
  }

  void _toggleAudioInputMode() {
    setState(() {
      _useFileUpload = !_useFileUpload;
      if (_useFileUpload) {
        _audioFile = null;
        _isRecording = false;
        _recordingTimer?.cancel();
      } else {
        // Switching to recording mode
      }
      _isValidAudio = false;
    });
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
                  'audio_content_upload_image_error'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  Future<void> _uploadAudioContent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_coverImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('audio_content_upload_no_audio_error'.tr())),
      );
      return;
    }

    if (!_isValidAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('audio_content_upload_invalid_content'.tr())),
      );
      return;
    }

    if (!_canUpload) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'audio_content_upload_limit'.tr(),
          ),
        ),
      );
      return;
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');

      // Create artwork using ArtworkService
      final artworkId = await _artworkService.uploadArtwork(
        imageFile: _coverImageFile!,
        title: _titleController.text,
        description: _descriptionController.text,
        medium: 'Audio Content',
        styles: _genres,
        tags: [],
        price: _isForSale ? double.tryParse(_priceController.text) ?? 0.0 : 0.0,
        isForSale: _isForSale,
      );

      // Update artwork metadata for audio content
      final artwork = await _artworkService.getArtworkById(artworkId);
      if (artwork != null) {
        final updatedData = {
          'contentType': 'audio',
          'audioMetadata': {
            'duration': _audioDuration.inMilliseconds,
            'format': _audioFormat,
            'fileSize': _fileSize,
            'bitrate': _bitrate,
            'sampleRate': _sampleRate,
            'isRecorded': !_useFileUpload,
          },
          'albumInfo': _isAlbum
              ? {
                  'title': _albumTitleController.text,
                  'description': _albumDescriptionController.text,
                  'trackNumber': int.tryParse(_trackNumberController.text) ?? 1,
                }
              : null,
          'lyrics':
              _lyricsController.text.isNotEmpty ? _lyricsController.text : null,
          'isrc': _isrcController.text.isNotEmpty ? _isrcController.text : null,
          'composer': _composerController.text.isNotEmpty
              ? _composerController.text
              : null,
          'producer': _producerController.text.isNotEmpty
              ? _producerController.text
              : null,
          'recordingDate': DateTime.now()
              .toIso8601String(), // Would be user input in real implementation
          'studio':
              _studioController.text.isNotEmpty ? _studioController.text : null,
          'releaseSchedule': _releaseSchedule,
          'waveformData': _waveformData,
        };

        await _firestore
            .collection('artwork')
            .doc(artworkId)
            .update(updatedData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('audio_content_upload_success'.tr())),
        );
        Navigator.of(context).pop(artworkId);
      }
    } catch (e) {
      AppLogger.error('Error uploading audio content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('audio_content_upload_error'.tr(args: [e.toString()]))),
        );
      }
    } finally {
      if (mounted) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: EnhancedUniversalHeader(
          title: 'audio_content_upload_title'.tr(),
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
                  'audio_content_upload_limit'.tr(),
                  style: TextStyle(color: Colors.orange[800]),
                ),
              ),
            Expanded(
              child: Stepper(
                currentStep: _currentStepIndex,
                onStepContinue: _onStepContinue,
                onStepCancel: _onStepCancel,
                onStepTapped: _onStepTapped,
                controlsBuilder: _buildStepperControls,
                steps: [
                  Step(
                    title: Text('audio_content_upload_step_content'.tr()),
                    subtitle:
                        Text('audio_content_upload_step_content_desc'.tr()),
                    content: _buildContentStep(),
                    isActive: _currentStepIndex >= 0,
                    state: _getStepState(0),
                  ),
                  Step(
                    title: Text('audio_content_upload_step_basic_info'.tr()),
                    subtitle:
                        Text('audio_content_upload_step_basic_info_desc'.tr()),
                    content: _buildBasicInfoStep(),
                    isActive: _currentStepIndex >= 1,
                    state: _getStepState(1),
                  ),
                  Step(
                    title: Text('audio_content_upload_step_details'.tr()),
                    subtitle:
                        Text('audio_content_upload_step_details_desc'.tr()),
                    content: _buildDetailsStep(),
                    isActive: _currentStepIndex >= 2,
                    state: _getStepState(2),
                  ),
                  Step(
                    title: Text('audio_content_upload_step_review'.tr()),
                    subtitle:
                        Text('audio_content_upload_step_review_desc'.tr()),
                    content: _buildReviewStep(),
                    isActive: _currentStepIndex >= 3,
                    state: _getStepState(3),
                  ),
                ],
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
      child: Row(
        children: [
          if (_currentStepIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: details.onStepCancel,
                child: Text('audio_content_upload_back'.tr()),
              ),
            ),
          if (_currentStepIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStepIndex == 3
                  ? _uploadAudioContent
                  : details.onStepContinue,
              child: Text(_currentStepIndex == 3
                  ? 'audio_content_upload_button'.tr()
                  : 'audio_content_upload_continue'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStepIndex < 3) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStepIndex += 1;
          _currentStep = AudioContentUploadStep.values[_currentStepIndex];
        });
      }
    }
  }

  void _onStepCancel() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex -= 1;
        _currentStep = AudioContentUploadStep.values[_currentStepIndex];
      });
    }
  }

  void _onStepTapped(int stepIndex) {
    if (stepIndex <= _currentStepIndex) {
      setState(() {
        _currentStepIndex = stepIndex;
        _currentStep = AudioContentUploadStep.values[stepIndex];
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case AudioContentUploadStep.content:
        return _audioFile != null && _isValidAudio;
      case AudioContentUploadStep.basicInfo:
        return _titleController.text.isNotEmpty &&
            _descriptionController.text.isNotEmpty &&
            _coverImageFile != null;
      case AudioContentUploadStep.details:
        return _genres.isNotEmpty;
      case AudioContentUploadStep.review:
        return true;
    }
  }

  Widget _buildContentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'audio_content_upload_content_step_title'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'audio_content_upload_content_step_description'.tr(),
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Content type
        Text(
          'audio_content_upload_content_type_label'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _contentType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            labelText: 'audio_content_upload_content_type_label'.tr(),
            labelStyle: const TextStyle(color: Colors.black87),
          ),
          style: const TextStyle(color: Colors.black87),
          items: _contentTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _contentType = value ?? 'Music';
            });
          },
        ),
        const SizedBox(height: 24),

        // Audio input mode toggle
        Text(
          'audio_content_upload_content_section'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _toggleAudioInputMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _useFileUpload ? ArtbeatColors.primaryGreen : Colors.grey,
                ),
                child: Text('audio_content_upload_file_mode'.tr()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _toggleAudioInputMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_useFileUpload
                      ? ArtbeatColors.primaryGreen
                      : Colors.grey,
                ),
                child: Text('audio_content_upload_recording_mode'.tr()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Audio input area
        if (_useFileUpload) ...[
          GestureDetector(
            onTap: _selectAudioFile,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _audioFile != null
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
                      _audioFile != null ? Icons.audio_file : Icons.file_upload,
                      size: 32,
                      color: _audioFile != null
                          ? ArtbeatColors.primaryGreen
                          : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _audioFile != null
                          ? _audioFile!.path.split('/').last
                          : 'audio_content_upload_select_file'.tr(),
                      style: TextStyle(
                        color: _audioFile != null
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
          // Recording interface
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  _isRecording
                      ? 'audio_content_upload_recording_time'
                          .tr(args: [_recordingTime])
                      : 'audio_content_upload_recording_hint'.tr(),
                  style: TextStyle(
                    color: _isRecording ? Colors.red : Colors.grey[600],
                    fontWeight:
                        _isRecording ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          _isRecording ? _stopRecording : _startRecording,
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                      label: Text(_isRecording
                          ? 'audio_content_upload_stop_recording'.tr()
                          : 'audio_content_upload_start_recording'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording
                            ? Colors.red
                            : ArtbeatColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Audio preview and metadata
        if (_audioFile != null && _isValidAudio) ...[
          const SizedBox(height: 24),
          Text(
            'Audio Preview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Waveform visualization placeholder
                if (_isGeneratingWaveform) ...[
                  const SizedBox(
                    height: 60,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  Text('audio_content_upload_waveform_loading'.tr()),
                ] else if (_waveformData != null) ...[
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        'Waveform visualization placeholder',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Playback controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _isPlaying ? _stopPlayback : _togglePlayback,
                      icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                      iconSize: 32,
                      color: ArtbeatColors.primaryGreen,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_formatDuration(_currentPosition)} / ${_formatDuration(_audioDuration)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Metadata display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMetadataItem(
                      'audio_content_upload_duration_label'.tr(),
                      _formatDuration(_audioDuration),
                    ),
                    _buildMetadataItem(
                      'audio_content_upload_file_size_label'.tr(),
                      _formatFileSize(_fileSize),
                    ),
                    _buildMetadataItem(
                      'audio_content_upload_format_label'.tr(),
                      _audioFormat,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).round()} MB';
    return '${(bytes / (1024 * 1024 * 1024)).round()} GB';
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'audio_content_upload_basic_info_step_title'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'audio_content_upload_basic_info_step_description'.tr(),
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Cover image
        Text(
          'audio_content_upload_cover_image_label'.tr(),
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
                ? Image.file(
                    _coverImageFile!,
                    fit: BoxFit.cover,
                  )
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
                          'audio_content_upload_cover_image_hint'.tr(),
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
            labelText: 'audio_content_upload_title_label'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'audio_content_upload_title_required'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'audio_content_upload_description_label'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 4,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'audio_content_upload_description_required'.tr();
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
          'audio_content_upload_details_step_title'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'audio_content_upload_details_step_description'.tr(),
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Genres
        Text(
          'audio_content_upload_genres_label'.tr(),
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

        // Album information
        CheckboxListTile(
          title: Text('audio_content_upload_album_checkbox'.tr()),
          subtitle: Text('audio_content_upload_album_hint'.tr()),
          value: _isAlbum,
          onChanged: (value) {
            setState(() {
              _isAlbum = value ?? false;
            });
          },
        ),
        if (_isAlbum) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _albumTitleController,
            decoration: InputDecoration(
              labelText: 'audio_content_upload_album_title_label'.tr(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _albumDescriptionController,
            decoration: InputDecoration(
              labelText: 'audio_content_upload_album_description_label'.tr(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _trackNumberController,
            decoration: InputDecoration(
              labelText: 'audio_content_upload_track_number_label'.tr(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: 24),

        // Lyrics
        TextFormField(
          controller: _lyricsController,
          decoration: InputDecoration(
            labelText: 'audio_content_upload_lyrics_label'.tr(),
            hintText: 'audio_content_upload_lyrics_hint'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 6,
        ),
        const SizedBox(height: 24),

        // Additional metadata
        Text(
          'Additional Information (Optional)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _isrcController,
                decoration: InputDecoration(
                  labelText: 'audio_content_upload_isrc_label'.tr(),
                  hintText: 'audio_content_upload_isrc_hint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _composerController,
                decoration: InputDecoration(
                  labelText: 'audio_content_upload_composer_label'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _producerController,
                decoration: InputDecoration(
                  labelText: 'audio_content_upload_producer_label'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _studioController,
                decoration: InputDecoration(
                  labelText: 'audio_content_upload_studio_label'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Release schedule
        Text(
          'audio_content_upload_schedule_label'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _releaseSchedule,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            labelText: 'audio_content_upload_schedule_label'.tr(),
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
        const SizedBox(height: 24),

        // For sale
        CheckboxListTile(
          title: Text('audio_content_upload_for_sale_checkbox'.tr()),
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
              labelText: 'audio_content_upload_price_label'.tr(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixText: '\$ ',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_isForSale && (value?.isEmpty ?? true)) {
                return 'audio_content_upload_price_required'.tr();
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
          'audio_content_upload_review_step_title'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'audio_content_upload_review_step_description'.tr(),
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Audio preview
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'audio_content_upload_content_preview'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_audioFile != null) ...[
                  Text('File: ${_audioFile!.path.split('/').last}'),
                  const SizedBox(height: 8),
                  Text('Duration: ${_formatDuration(_audioDuration)}'),
                  Text('Format: $_audioFormat'),
                  Text('Size: ${_formatFileSize(_fileSize)}'),
                ] else ...[
                  Text('art_walk_no_audio_file_selected'.tr()),
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
                  'audio_content_upload_basic_info_summary'.tr(),
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
                Text('Title: ${_titleController.text}'),
                Text('Description: ${_descriptionController.text}'),
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
                  'audio_content_upload_details_summary'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Genres: ${_genres.join(", ")}'),
                if (_isAlbum) ...[
                  Text('Album: ${_albumTitleController.text}'),
                  Text('Track: ${_trackNumberController.text}'),
                ],
                if (_lyricsController.text.isNotEmpty) ...[
                  const Text('Lyrics: Available'),
                ],
                Text(
                    'Schedule: ${_releaseSchedule.replaceAll('_', ' ').toUpperCase()}'),
                if (_isForSale) ...[
                  Text('Price: \$${_priceController.text}'),
                ],
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
    _lyricsController.dispose();
    _albumTitleController.dispose();
    _albumDescriptionController.dispose();
    _trackNumberController.dispose();
    _isrcController.dispose();
    _composerController.dispose();
    _producerController.dispose();
    _studioController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }
}
