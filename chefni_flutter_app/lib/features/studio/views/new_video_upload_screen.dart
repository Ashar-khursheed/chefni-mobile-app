import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/repositories/studio_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chefni_ui.dart';
import '../../recipe_card/views/recipe_card_screen.dart';

/// Which part of the flow the screen is showing.
enum _Stage { pick, uploading, processing, done, failed }

class NewVideoUploadScreen extends StatefulWidget {
  const NewVideoUploadScreen({super.key});

  @override
  State<NewVideoUploadScreen> createState() => _NewVideoUploadScreenState();
}

class _NewVideoUploadScreenState extends State<NewVideoUploadScreen> {
  final TextEditingController _title = TextEditingController();

  _Stage _stage = _Stage.pick;

  /// Reads uniformly as a byte stream on every platform — mobile, desktop
  /// and web alike — so there is no path-vs-bytes branch to maintain.
  PlatformFile? _picked;

  String? _fileName;
  int? _fileSizeBytes;

  bool get _hasFile => _picked != null;
  double _uploadProgress = 0;
  UserVideo? _video;
  String? _error;
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await FilePicker.pickFile(type: FileType.video);
      if (picked == null) return; // cancelled

      final size = picked.lengthSync() ?? await picked.length();
      if (size == null) {
        setState(() => _error = 'That file could not be read. Try another.');
        return;
      }

      setState(() {
        _picked = picked;
        _fileName = picked.name;
        _fileSizeBytes = size;
        _error = null;
        // A filename usually beats an empty title as a starting point.
        if (_title.text.trim().isEmpty) {
          _title.text = _titleFromFileName(picked.name);
        }
      });
    } on PlatformException catch (e) {
      setState(() => _error = 'Could not open the file picker: ${e.message}');
    }
  }

  static String _titleFromFileName(String name) {
    final withoutExtension = name.contains('.')
        ? name.substring(0, name.lastIndexOf('.'))
        : name;
    return withoutExtension.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  }

  Future<void> _startUpload() async {
    final title = _title.text.trim();
    final name = _fileName;
    final picked = _picked;
    final totalBytes = _fileSizeBytes;

    if (!_hasFile || title.isEmpty || name == null || picked == null || totalBytes == null) {
      return;
    }

    final byteStream = picked.readAsByteStream();

    setState(() {
      _stage = _Stage.uploading;
      _uploadProgress = 0;
      _error = null;
    });

    try {
      final video = await ServiceScope.of(context).studio.uploadVideo(
            byteStream: byteStream,
            totalBytes: totalBytes,
            filename: name,
            title: title,
            onProgress: (p) {
              if (mounted) setState(() => _uploadProgress = p);
            },
          );

      if (!mounted) return;
      setState(() {
        _video = video;
        _stage = _Stage.processing;
      });
      _startPolling(video.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.failed;
        _error = e.message;
      });
    }
  }

  /// The server processes out of band, so the screen polls until the record
  /// reaches a terminal state.
  void _startPolling(int videoId) {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final video = await ServiceScope.of(context).studio.videoStatus(videoId);
        if (!mounted) return;

        setState(() => _video = video);

        if (video.isSettled) {
          timer.cancel();
          setState(() {
            _stage = video.status == VideoStatus.ready ? _Stage.done : _Stage.failed;
            _error = video.status == VideoStatus.failed ? video.failureReason : null;
          });
        }
      } on ApiException {
        // A dropped poll is not fatal — the next tick retries.
      }
    });
  }

  void _reset() {
    _poll?.cancel();
    setState(() {
      _stage = _Stage.pick;
      _picked = null;
      _fileName = null;
      _fileSizeBytes = null;
      _video = null;
      _error = null;
      _uploadProgress = 0;
      _title.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  ChefniCircleButton(
                    icon: Icons.close,
                    size: 38,
                    iconSize: 19,
                    // Leaving mid-upload would abandon the request; the video
                    // keeps processing server-side either way.
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 14),
                  Text('New video', style: AppTheme.display(size: 21)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: _buildStage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case _Stage.pick:
        return _buildPicker();
      case _Stage.uploading:
        return _buildUploading();
      case _Stage.processing:
        return _buildProcessing();
      case _Stage.done:
        return _buildDone();
      case _Stage.failed:
        return _buildFailed();
    }
  }

  // ── Stage: choose a file ────────────────────────────────────────────────

  Widget _buildPicker() {
    final hasFile = _hasFile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
          decoration: BoxDecoration(
            color: AppTheme.tintTeal,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.tealPrimary.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(
                hasFile ? Icons.check_circle_outline : Icons.file_upload_outlined,
                size: 48,
                color: AppTheme.tealDeep,
              ),
              const SizedBox(height: 14),
              Text(
                hasFile ? 'Video selected' : 'Upload your cooking video',
                textAlign: TextAlign.center,
                style: AppTheme.display(size: 17),
              ),
              const SizedBox(height: 8),
              Text(
                hasFile
                    ? '$_fileName${_fileSizeBytes != null ? ' · ${_mb(_fileSizeBytes!)}' : ''}'
                    : 'Chefni compresses it into a 1-minute reel and builds a recipe '
                        'card from what you say while cooking.',
                textAlign: TextAlign.center,
                style: AppTheme.body(size: 12.5, color: AppTheme.mutedText, height: 1.45),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tealPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _pickVideo,
                  child: Text(
                    hasFile ? 'Choose a different video' : 'Choose video',
                    style: AppTheme.display(size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          _buildNotice(_error!, AppTheme.alertRed, Icons.error_outline),
        ],
        if (hasFile) ...[
          const SizedBox(height: 26),
          Text('Title', style: AppTheme.display(size: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            maxLength: 255,
            decoration: InputDecoration(
              hintText: 'e.g. Karachi Beef Nihari',
              hintStyle: AppTheme.body(size: 13.5, color: AppTheme.mutedText),
              filled: true,
              fillColor: AppTheme.bgWhite,
              counterText: '',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.tealPrimary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 22),
          ChefniPrimaryButton(
            label: 'Upload and process',
            onPressed: _title.text.trim().isEmpty ? null : _startUpload,
          ),
          const SizedBox(height: 12),
          Text(
            'Your raw video is deleted from the server once the reel is made. '
            'Only the reel and recipe card are kept.',
            textAlign: TextAlign.center,
            style: AppTheme.body(size: 11.5, color: AppTheme.mutedText, height: 1.4),
          ),
        ],
      ],
    );
  }

  // ── Stage: uploading bytes ──────────────────────────────────────────────

  Widget _buildUploading() {
    final percent = (_uploadProgress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Uploading', style: AppTheme.display(size: 18)),
        const SizedBox(height: 6),
        Text(
          _fileName ?? '',
          style: AppTheme.body(size: 13, color: AppTheme.mutedText),
        ),
        const SizedBox(height: 22),
        _buildProgressBar(_uploadProgress, AppTheme.tealPrimary),
        const SizedBox(height: 10),
        Text(
          '$percent%'
          '${_fileSizeBytes != null ? ' of ${_mb(_fileSizeBytes!)}' : ''}',
          style: AppTheme.display(size: 13, color: AppTheme.tealDeep),
        ),
        const SizedBox(height: 20),
        Text(
          'Keep this screen open until the upload finishes.',
          style: AppTheme.body(size: 12.5, color: AppTheme.mutedText, height: 1.4),
        ),
      ],
    );
  }

  // ── Stage: server-side pipeline ─────────────────────────────────────────

  Widget _buildProcessing() {
    final video = _video;
    final progress = (video?.progress ?? 0) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Processing', style: AppTheme.display(size: 18)),
        const SizedBox(height: 6),
        Text(
          video?.title ?? '',
          style: AppTheme.body(size: 13, color: AppTheme.mutedText),
        ),
        const SizedBox(height: 22),
        _buildProgressBar(progress, AppTheme.coralPrimary),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.coralPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                video?.status.label ?? 'Starting…',
                style: AppTheme.display(size: 13, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNotice(
          'This runs on our servers, so you can leave this screen. Your video '
          'will appear in Studio when it is ready.',
          AppTheme.tealDeep,
          Icons.info_outline,
        ),
      ],
    );
  }

  // ── Stage: finished ─────────────────────────────────────────────────────

  Widget _buildDone() {
    final video = _video!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 26),
            const SizedBox(width: 10),
            Text('Reel ready', style: AppTheme.display(size: 19)),
          ],
        ),
        const SizedBox(height: 18),
        ChefniCard(
          radius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(video.title, style: AppTheme.display(size: 15)),
              const SizedBox(height: 12),
              if (video.sizeSummary != null)
                _buildStatRow('Compressed', video.sizeSummary!,
                    trailing: video.compressionPercent != null
                        ? '${video.compressionPercent!.toStringAsFixed(0)}% of original'
                        : null),
              if (video.durationLabel != null)
                _buildStatRow('Reel length', video.durationLabel!),
              if (video.resolution != null)
                _buildStatRow('Resolution', '${video.resolution} · 9:16'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // A note here means the reel worked but the recipe card did not.
        if (video.failureReason != null)
          _buildNotice(video.failureReason!, AppTheme.accentGold, Icons.info_outline),
        if (video.hasRecipeCard) ...[
          const SizedBox(height: 6),
          ChefniPrimaryButton(
            label: 'View recipe card',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecipeCardScreen(cardId: video.recipeCardId!),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        TextButton(
          onPressed: _reset,
          child: Text(
            'Upload another video',
            style: AppTheme.display(size: 13.5, color: AppTheme.tealDeep),
          ),
        ),
      ],
    );
  }

  // ── Stage: failed ───────────────────────────────────────────────────────

  Widget _buildFailed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.alertRed, size: 26),
            const SizedBox(width: 10),
            Text("That didn't work", style: AppTheme.display(size: 19)),
          ],
        ),
        const SizedBox(height: 16),
        _buildNotice(
          _error ?? 'The video could not be processed.',
          AppTheme.alertRed,
          Icons.error_outline,
        ),
        const SizedBox(height: 22),
        ChefniPrimaryButton(label: 'Try again', onPressed: _reset),
      ],
    );
  }

  // ── Shared pieces ───────────────────────────────────────────────────────

  Widget _buildProgressBar(double value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: AppTheme.chipNeutral,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTheme.body(size: 12.5, color: AppTheme.mutedText),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: AppTheme.display(size: 13, weight: FontWeight.w700)),
                if (trailing != null)
                  Text(
                    trailing,
                    style: AppTheme.body(size: 11.5, color: AppTheme.successGreen),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice(String message, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTheme.body(size: 12.5, color: AppTheme.darkText, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  static String _mb(int bytes) => '${(bytes / 1048576).toStringAsFixed(1)} MB';
}
