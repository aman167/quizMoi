import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'state/quiz_provider.dart';
import 'widgets/mobile_bottom_nav.dart';
import 'screens/dashboard_screen.dart';
import 'screens/upload_content_screen.dart';
import 'screens/results_feedback_screen.dart';

void main() {
  runApp(const QuizMoiApp());
}

class QuizMoiApp extends StatelessWidget {
  const QuizMoiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizProvider(),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Settings'),
        centerTitle: true,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Account features are coming later',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'quizMoi currently runs in local demo mode, so no account is required.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
