import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'state/quiz_provider.dart';
import 'widgets/mobile_bottom_nav.dart';
import 'screens/dashboard_screen.dart';
import 'screens/upload_content_screen.dart';
import 'screens/results_feedback_screen.dart';
import 'features/learning/data/local/quiz_database.dart';
import 'features/learning/data/repositories/sqlite_quiz_repository.dart';
import 'features/learning/data/repositories/sqlite_attempt_repository.dart';
import 'features/learning/data/repositories/memory_attempt_repository.dart';
import 'features/learning/data/repositories/memory_knowledge_base_repository.dart';
import 'features/learning/data/repositories/sqlite_knowledge_base_repository.dart';
import 'features/learning/data/repositories/memory_learner_settings_repository.dart';
import 'features/learning/data/repositories/sqlite_learner_settings_repository.dart';
import 'features/learning/data/repositories/memory_source_document_repository.dart';
import 'features/learning/data/repositories/sqlite_source_document_repository.dart';
import 'features/learning/domain/repositories/attempt_repository.dart';
import 'features/learning/domain/repositories/knowledge_base_repository.dart';
import 'features/learning/domain/repositories/learner_settings_repository.dart';
import 'features/learning/domain/repositories/quiz_repository.dart';
import 'features/learning/domain/repositories/source_document_repository.dart';
import 'features/learning/presentation/state/saved_quiz_provider.dart';
import 'features/learning/presentation/state/attempt_history_provider.dart';
import 'features/learning/presentation/state/knowledge_base_provider.dart';
import 'features/learning/presentation/state/learner_settings_provider.dart';
import 'features/learning/presentation/state/source_document_provider.dart';
import 'features/learning/presentation/screens/learner_settings_screen.dart';
import 'features/quiz_generation/data/http_quiz_generation_gateway.dart';
import 'features/quiz_generation/domain/quiz_generation_gateway.dart';
import 'features/quiz_generation/presentation/state/quiz_generation_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await QuizDatabase.open();
  runApp(
    QuizMoiApp(
      quizRepository: SqliteQuizRepository(database),
      attemptRepository: SqliteAttemptRepository(database),
      knowledgeBaseRepository: SqliteKnowledgeBaseRepository(database),
      learnerSettingsRepository: SqliteLearnerSettingsRepository(database),
      sourceDocumentRepository: SqliteSourceDocumentRepository(database),
      quizGenerationGateway: HttpQuizGenerationGateway(
        baseUrl: const String.fromEnvironment(
          'QUIZMOI_API_BASE_URL',
          defaultValue: 'http://10.0.2.2:8000',
        ),
      ),
    ),
  );
}

class QuizMoiApp extends StatelessWidget {
  final QuizRepository quizRepository;
  final AttemptRepository? attemptRepository;
  final KnowledgeBaseRepository? knowledgeBaseRepository;
  final LearnerSettingsRepository? learnerSettingsRepository;
  final SourceDocumentRepository? sourceDocumentRepository;
  final QuizGenerationGateway? quizGenerationGateway;

  const QuizMoiApp({
    super.key,
    required this.quizRepository,
    this.attemptRepository,
    this.knowledgeBaseRepository,
    this.learnerSettingsRepository,
    this.sourceDocumentRepository,
    this.quizGenerationGateway,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAttemptRepository =
        attemptRepository ?? MemoryAttemptRepository();
    final effectiveKnowledgeBaseRepository =
        knowledgeBaseRepository ?? MemoryKnowledgeBaseRepository();
    final effectiveLearnerSettingsRepository =
        learnerSettingsRepository ?? MemoryLearnerSettingsRepository();
    final effectiveSourceDocumentRepository =
        sourceDocumentRepository ?? MemorySourceDocumentRepository();
    final effectiveQuizGenerationGateway =
        quizGenerationGateway ??
        HttpQuizGenerationGateway(baseUrl: 'http://10.0.2.2:8000');
    return MultiProvider(
      providers: [
        Provider<SourceDocumentRepository>.value(
          value: effectiveSourceDocumentRepository,
        ),
        ChangeNotifierProvider(
          create: (_) =>
              SourceDocumentProvider(effectiveSourceDocumentRepository)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              QuizGenerationProvider(gateway: effectiveQuizGenerationGateway),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              LearnerSettingsProvider(effectiveLearnerSettingsRepository)
                ..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              KnowledgeBaseProvider(effectiveKnowledgeBaseRepository)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => AttemptHistoryProvider(
            attemptRepository: effectiveAttemptRepository,
            quizRepository: quizRepository,
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => QuizProvider(
            attemptRepository: attemptRepository,
            onAttemptCompleted: context.read<AttemptHistoryProvider>().load,
          )..restoreInProgress(quizRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SavedQuizProvider(quizRepository)..load(),
        ),
      ],
      child: MaterialApp(
        title: 'quizMoi - French Recall',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        home: const MainNavigationContainer(),
      ),
    );
  }
}

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({super.key});

  @override
  State<MainNavigationContainer> createState() =>
      _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentTabIndex = 1; // Default to 'Review' tab (Dashboard)

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const UploadContentScreen(), // Tab 0: Learn / Create
      DashboardScreen(
        onNavigateTab: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ), // Tab 1: Review (Dashboard)
      const ResultsFeedbackScreen(), // Tab 2: Stats / Results
      const AccountScreen(), // Tab 3: Account
    ];

    return Scaffold(
      body: IndexedStack(index: _currentTabIndex, children: screens),
      bottomNavigationBar: MobileBottomNav(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) => const LearnerSettingsScreen();
}
