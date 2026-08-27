import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../state/quiz_provider.dart';
import 'active_testing_screen.dart';
import '../features/learning/presentation/screens/manual_quiz_editor_screen.dart';
import '../features/learning/domain/entities/learning_entities.dart';
import '../features/learning/presentation/state/learner_settings_provider.dart';
import '../features/quiz_generation/presentation/state/quiz_generation_provider.dart';
import '../features/source_ingestion/data/android_pdf_source_picker.dart';
import '../features/source_ingestion/domain/pdf_source_picker.dart';

class UploadContentScreen extends StatefulWidget {
  final PdfSourcePicker? pdfSourcePicker;

  const UploadContentScreen({super.key, this.pdfSourcePicker});

  @override
  State<UploadContentScreen> createState() => _UploadContentScreenState();
}

class _UploadContentScreenState extends State<UploadContentScreen> {
  int _selectedTab = 0; // 0: Quiz, 1: Flashcards, 2: Notes
  bool _optionsExpanded = false;
  bool _isImportingPdf = false;
  final TextEditingController _textController = TextEditingController();
  SelectedPdfSource? _importedPdf;
  String? _pdfImportError;

  PdfSourcePicker get _pdfSourcePicker =>
      widget.pdfSourcePicker ?? const AndroidPdfSourcePicker();

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is planned for a later phase.')),
    );
  }

  Future<void> _previewSource() async {
    FocusScope.of(context).unfocus();
    final generation = context.read<QuizGenerationProvider>();
    final cefrLevel = context
        .read<LearnerSettingsProvider>()
        .settings
        .cefrLevel;
    final prepared = _importedPdf == null
        ? generation.prepareSource(
            text: _textController.text,
            cefrLevel: cefrLevel,
          )
        : generation.preparePdf(
            sourceTitle: _importedPdf!.title,
            fileName: _importedPdf!.fileName,
            pdfBytes: _importedPdf!.bytes,
            cefrLevel: cefrLevel,
          );
    if (!prepared) {
      return;
    }
    final textRequest = generation.request;
    final pdfRequest = generation.pdfRequest;
    final sourceTitle = textRequest?.sourceTitle ?? pdfRequest!.sourceTitle;
    final sourceSummary = textRequest == null
        ? '${_formatBytes(pdfRequest!.pdfBytes.length)} PDF • ${pdfRequest.cefrLevel} • 10 multiple-choice questions'
        : '${textRequest.sourceText.length} characters • ${textRequest.cefrLevel} • 10 multiple-choice questions';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Preview your source'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sourceTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sourceSummary,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                textRequest == null
                    ? 'The full PDF will go to your local quizMoi backend, which sends it to OpenAI so the model can read its text and pages. Your API key stays on the backend.'
                    : 'Confirm that this is the study material you want to send to the local quizMoi backend.',
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: SingleChildScrollView(
                    child: textRequest == null
                        ? Row(
                            children: [
                              const Icon(Icons.picture_as_pdf, size: 32),
                              const SizedBox(width: 12),
                              Expanded(child: Text(pdfRequest!.fileName)),
                            ],
                          )
                        : Text(textRequest.sourceText),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Quiz'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _generateAndReview();
    }
  }

  Future<void> _generateAndReview() async {
    final generation = context.read<QuizGenerationProvider>();
    final generated = await generation.generate();
    if (!generated || !mounted) return;

    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (context) => ManualQuizEditorScreen(
          draftQuiz: generation.draftQuiz,
          sourceDocument: generation.sourceDocument,
        ),
      ),
    );
    if (!mounted) return;
    if (result == QuizEditorAction.regenerate) {
      await _generateAndReview();
      return;
    }
    if (result is QuizDefinition) {
      generation.markSaved();
      context.read<QuizProvider>().startSavedQuiz(result);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ActiveTestingScreen()),
      );
      if (mounted) generation.reset();
    }
  }

  void _startDemoQuiz() {
    context.read<QuizProvider>().startQuiz('demo');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActiveTestingScreen()),
    );
  }

  Future<void> _importPdf() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isImportingPdf = true;
      _pdfImportError = null;
    });
    try {
      final imported = await _pdfSourcePicker.pickPdf();
      if (!mounted || imported == null) return;
      context.read<QuizGenerationProvider>().reset();
      setState(() => _importedPdf = imported);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${imported.fileName} selected. Preview it before sending it for quiz generation.',
          ),
        ),
      );
    } on PdfSelectionException catch (error) {
      if (mounted) setState(() => _pdfImportError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _pdfImportError =
              'The PDF could not be imported. Your existing text was not changed.';
        });
      }
    } finally {
      if (mounted) setState(() => _isImportingPdf = false);
    }
  }

  void _removeImportedPdf() {
    context.read<QuizGenerationProvider>().reset();
    setState(() {
      _importedPdf = null;
      _pdfImportError = null;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generation = context.watch<QuizGenerationProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.onSurfaceVariant),
          onPressed: () => _showComingSoon('The app menu'),
        ),
        title: const Text(
          'quizMoi',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryContainer,
              child: const Text(
                'U',
                style: TextStyle(
                  color: AppColors.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Header Section
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_fix_high,
                color: AppColors.onPrimary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create Quiz',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Generate AI-powered quizzes from your content',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            // Content Type Tabs Segmented Bar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  _buildTabButton(0, Icons.quiz, 'Quiz'),
                  _buildTabButton(1, Icons.style, 'Flashcards'),
                  _buildTabButton(2, Icons.description, 'Notes'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main Upload Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quiz Options Accordion Header
                  InkWell(
                    onTap: () {
                      setState(() {
                        _optionsExpanded = !_optionsExpanded;
                      });
                    },
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.settings_suggest,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Quiz Options: Questions, Difficulty, Question Types',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            _optionsExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_optionsExpanded)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Options: 10 Questions • Medium Difficulty • Multiple Choice',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),

                  // Manual Creation Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withValues(
                        alpha: 0.5,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: AppColors.tertiary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Want to build your own quiz from scratch?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.tertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ManualQuizEditorScreen(),
                              ),
                            ),
                            child: const Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Create Manually',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.tertiary,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 12,
                                  color: AppColors.tertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Card Inner Form Area
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Quiz from Any Content',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.science_outlined, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Phase 4 can send a confirmed PDF through your local quizMoi backend so OpenAI can read its text and page images. Your API key stays on the computer.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Text Area Input
                        Stack(
                          children: [
                            TextField(
                              controller: _textController,
                              maxLines: 6,
                              textInputAction: TextInputAction.newline,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'French study text',
                                hintText:
                                    'Paste at least 200 characters of French or bilingual study material.',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.outlineVariant,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.outlineVariant,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.fromLTRB(
                                  14,
                                  14,
                                  14,
                                  50,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Row(
                                children: [
                                  _buildCircleIconButton(
                                    Icons.upload_file,
                                    'Import PDF',
                                    onPressed: _importPdf,
                                    enabled: !_isImportingPdf,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCircleIconButton(
                                    Icons.photo_camera,
                                    'Scan with Camera',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_isImportingPdf) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(),
                          const SizedBox(height: 8),
                          const Text('Opening the Android PDF picker…'),
                        ],
                        if (_importedPdf != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _importedPdf!.fileName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${_formatBytes(_importedPdf!.fileSizeBytes)} • Ready for AI reading',
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _removeImportedPdf,
                                  tooltip: 'Remove imported PDF',
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_pdfImportError != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_pdfImportError!)),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),

                        // Tips
                        Text(
                          'TIPS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTipItem(
                          'Type or paste any text content (e.g., French literature excerpts)',
                        ),
                        _buildTipItem(
                          'Import PDFs up to 10 MB; OpenAI can read both text and scanned page images',
                        ),
                        _buildTipItem(
                          'The first prototype creates 10 medium multiple-choice questions',
                        ),

                        const SizedBox(height: 24),

                        // Generate Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                generation.isGenerating || _isImportingPdf
                                ? null
                                : _previewSource,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text(
                                  generation.isGenerating
                                      ? 'Generating Quiz…'
                                      : 'Preview & Generate',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (generation.isGenerating)
                                  const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  const Icon(Icons.auto_awesome, size: 20),
                              ],
                            ),
                          ),
                        ),
                        if (generation.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline),
                                const SizedBox(width: 8),
                                Expanded(child: Text(generation.errorMessage!)),
                                if (generation.canRetry)
                                  TextButton(
                                    onPressed: generation.isGenerating
                                        ? null
                                        : _generateAndReview,
                                    child: const Text('Retry'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: generation.isGenerating
                              ? null
                              : _startDemoQuiz,
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Try Offline Demo Quiz'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        if (index != 0) {
          _showComingSoon(label);
          return;
        }
        setState(() {
          _selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? AppColors.onPrimary
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleIconButton(
    IconData icon,
    String tooltip, {
    VoidCallback? onPressed,
    bool enabled = true,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppColors.onSurface),
        padding: EdgeInsets.zero,
        onPressed: enabled ? onPressed ?? () => _showComingSoon(tooltip) : null,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildTipItem(String tipText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              tipText,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
