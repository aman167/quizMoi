import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../models/user_stats_model.dart';

class QuizProvider extends ChangeNotifier {
  UserStats _userStats = UserStats(
    name: 'User',
    level: 'B1 French',
    xp: 1240,
    averageScore: 82.5,
    dailyGoalCurrent: 30,
    dailyGoalTarget: 40,
    streakDays: 3,
  );

  List<KnowledgeBase> _knowledgeBases = [
    KnowledgeBase(
      id: 'kb1',
      title: 'French History Revolution PDF',
      sourceType: 'AI Generated',
      iconName: 'picture_as_pdf',
      questionCount: 25,
      createdDate: 'Apr 24',
    ),
    KnowledgeBase(
      id: 'kb2',
      title: 'Vocab List 3: Subjunctive Mood',
      sourceType: 'Manual Entry',
      iconName: 'text_snippet',
      questionCount: 40,
      createdDate: 'Apr 20',
    ),
    KnowledgeBase(
      id: 'kb3',
      title: 'Le Monde Article Analysis',
      sourceType: 'Web Scrape',
      iconName: 'link',
      questionCount: 12,
      createdDate: 'Apr 18',
    ),
  ];

  Quiz? _currentQuiz;
  int _currentQuestionIndex = 0;
  int _elapsedSeconds = 0;
  bool _quizCompleted = false;

  UserStats get userStats => _userStats;
  List<KnowledgeBase> get knowledgeBases => _knowledgeBases;
  Quiz? get currentQuiz => _currentQuiz;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get elapsedSeconds => _elapsedSeconds;
  bool get quizCompleted => _quizCompleted;

  QuizQuestion? get currentQuestion {
    if (_currentQuiz == null || _currentQuestionIndex >= _currentQuiz!.questions.length) {
      return null;
    }
    return _currentQuiz!.questions[_currentQuestionIndex];
  }

  double get progress {
    if (_currentQuiz == null || _currentQuiz!.questions.isEmpty) return 0.0;
    return (_currentQuestionIndex + 1) / _currentQuiz!.questions.length;
  }

  String get formattedTime {
    final mins = _elapsedSeconds ~/ 60;
    final secs = _elapsedSeconds % 60;
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  void startQuiz(String knowledgeBaseId) {
    List<QuizQuestion> questions = [
      QuizQuestion(
        number: 1,
        prompt: 'Quel est le synonyme de "quotidien" ?',
        options: [
          QuizOption(id: 'a', text: 'Rare'),
          QuizOption(id: 'b', text: 'Journalier'),
          QuizOption(id: 'c', text: 'Ancien'),
          QuizOption(id: 'd', text: 'Nouveau'),
        ],
        correctOptionId: 'b',
      ),
      QuizQuestion(
        number: 2,
        prompt: 'Comment dit-on "to remember" en français ?',
        options: [
          QuizOption(id: 'a', text: 'Oublier'),
          QuizOption(id: 'b', text: 'Se souvenir'),
          QuizOption(id: 'c', text: 'Perdre'),
          QuizOption(id: 'd', text: 'Chercher'),
        ],
        correctOptionId: 'b',
      ),
      QuizQuestion(
        number: 3,
        prompt: 'Complétez : "Il fait ___ aujourd\'hui." (It\'s nice weather)',
        options: [
          QuizOption(id: 'a', text: 'froid'),
          QuizOption(id: 'b', text: 'beau'),
          QuizOption(id: 'c', text: 'nuit'),
          QuizOption(id: 'd', text: 'mal'),
        ],
        correctOptionId: 'b',
      ),
      QuizQuestion(
        number: 4,
        prompt: 'Dans le contexte de l\'article sur le changement climatique, que signifie l\'expression "passer au crible" ?',
        options: [
          QuizOption(id: 'a', text: 'Ignorer complètement un problème.'),
          QuizOption(id: 'b', text: 'Examiner minutieusement et en détail.'),
          QuizOption(id: 'c', text: 'Transmettre une information rapidement.'),
          QuizOption(id: 'd', text: 'Trier des déchets recyclables.'),
        ],
        correctOptionId: 'b',
      ),
      QuizQuestion(
        number: 5,
        prompt: 'Quel est le passé composé de "aller" avec "je" ?',
        options: [
          QuizOption(id: 'a', text: 'J\'ai allé'),
          QuizOption(id: 'b', text: 'Je suis allé'),
          QuizOption(id: 'c', text: 'J\'allais'),
          QuizOption(id: 'd', text: 'Je vais'),
        ],
        correctOptionId: 'b',
      ),
      QuizQuestion(
        number: 6,
        prompt: 'Que signifie "néanmoins" ?',
        options: [
          QuizOption(id: 'a', text: 'Jamais'),
          QuizOption(id: 'b', text: 'Toujours'),
          QuizOption(id: 'c', text: 'Cependant'),
          QuizOption(id: 'd', text: 'Ensuite'),
        ],
        correctOptionId: 'c',
      ),
      QuizQuestion(
        number: 7,
        prompt: 'Complétez : "Elle ___ (se lever) tôt chaque matin."',
        options: [
          QuizOption(id: 'a', text: 'se lève'),
          QuizOption(id: 'b', text: 'se lever'),
          QuizOption(id: 'c', text: 'lève'),
          QuizOption(id: 'd', text: 'se levons'),
        ],
        correctOptionId: 'a',
      ),
      QuizQuestion(
        number: 8,
        prompt: 'Comment dit-on "environment" en français ?',
        options: [
          QuizOption(id: 'a', text: 'L\'environnement'),
          QuizOption(id: 'b', text: 'L\'entourage'),
          QuizOption(id: 'c', text: 'L\'enveloppe'),
          QuizOption(id: 'd', text: 'L\'envoi'),
        ],
        correctOptionId: 'a',
      ),
      QuizQuestion(
        number: 9,
        prompt: 'Quel mot signifie "however" en français ?',
        options: [
          QuizOption(id: 'a', text: 'Pourtant'),
          QuizOption(id: 'b', text: 'Parce que'),
          QuizOption(id: 'c', text: 'Puis'),
          QuizOption(id: 'd', text: 'Pour'),
        ],
        correctOptionId: 'a',
      ),
      QuizQuestion(
        number: 10,
        prompt: 'Complétez : "Nous ___ (devoir) étudier pour l\'examen."',
        options: [
          QuizOption(id: 'a', text: 'devions'),
          QuizOption(id: 'b', text: 'devons'),
          QuizOption(id: 'c', text: 'doivent'),
          QuizOption(id: 'd', text: 'dois'),
        ],
        correctOptionId: 'b',
      ),
    ];

    _currentQuiz = Quiz(
      id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Advanced French Vocabulary',
      source: 'Le Monde Articles (Unit 4)',
      questions: questions,
    );

    _currentQuestionIndex = 0;
    _elapsedSeconds = 765;
    _quizCompleted = false;
    notifyListeners();
  }

  void selectOption(String optionId) {
    if (_currentQuiz == null) return;
    _currentQuiz!.questions[_currentQuestionIndex].selectedOptionId = optionId;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuiz == null) return;
    if (_currentQuestionIndex < _currentQuiz!.questions.length - 1) {
      _currentQuestionIndex++;
    } else {
      _quizCompleted = true;
    }
    notifyListeners();
  }

  void previousQuestion() {
    if (_currentQuiz == null) return;
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void resetQuiz() {
    _currentQuiz = null;
    _currentQuestionIndex = 0;
    _elapsedSeconds = 0;
    _quizCompleted = false;
    notifyListeners();
  }

  void incrementTimer() {
    _elapsedSeconds++;
    notifyListeners();
  }
}
