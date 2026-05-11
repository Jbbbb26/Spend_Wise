import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:spendwise_trakcer/login.dart'; 
import 'package:spendwise_trakcer/profile.dart'; 
import 'package:spendwise_trakcer/overview_screen.dart'; 
import 'package:spendwise_trakcer/tasks_screen.dart'; // ADD THIS
import 'firebase_options.dart';
import 'package:spendwise_trakcer/budget_screen.dart';
import 'transaction_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SpendWiseApp());
}

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F3826)),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF0F3826)),
              ),
            );
          }
          if (snapshot.hasData) {
            return const SpendWiseOverviewScreen();
          }
          return const SpendWiseLoginScreen();
        },
      ),
      routes: {
  '/login': (context) => const SpendWiseLoginScreen(),
  '/profile': (context) => const SpendWiseProfileScreen(),
  '/overview': (context) => const SpendWiseOverviewScreen(),
  '/tasks': (context) => const SpendWiseTasksScreen(),
  '/budgets': (context) => const SpendWiseBudgetScreen(),
  '/transactions': (context) => const SpendWiseTransactionsScreen(),
},
    );
  }
}