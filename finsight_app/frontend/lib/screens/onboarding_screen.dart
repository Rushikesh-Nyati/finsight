import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart'; // ADD THIS IMPORT
import '../providers/transaction_provider.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          _buildWelcomeScreen(),
          _buildPermissionsScreen(),
          _buildInitialSyncScreen(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 120,
            color: Colors.blue,
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to FinSight',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Track your spending automatically',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Plan for your goals',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '100% Private and Secure',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsScreen() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.security,
            size: 120,
            color: Colors.green,
          ),
          const SizedBox(height: 32),
          const Text(
            'Privacy First',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'FinSight needs permission to read your SMS messages to automatically categorize your financial transactions.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'This process happens entirely on your device, and your data never leaves your phone.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _requestSMSPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text(
              'Grant Permission',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialSyncScreen() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sync,
                size: 120,
                color: Colors.orange,
              ),
              const SizedBox(height: 32),
              const Text(
                'Analyzing your financial history...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (transactionProvider.isLoading)
                const CircularProgressIndicator()
              else if (transactionProvider.error != null)
                Column(
                  children: [
                    const Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${transactionProvider.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _startInitialSync();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _startInitialSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 16),
                  ),
                  child: const Text(
                    'Start Analysis',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestSMSPermission() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('SMS permission is required for the app to work properly'),
          ),
        );
      }
    }
  }

  Future<void> _startInitialSync() async {
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    // await transactionProvider.syncSMSTransactions();
    await transactionProvider.syncSMSData();

    if (transactionProvider.error == null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }
}
