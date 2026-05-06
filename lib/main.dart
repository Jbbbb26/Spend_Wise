import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:spendwise_trakcer/login.dart'; 
import 'package:spendwise_trakcer/profile.dart'; 
import 'package:spendwise_trakcer/overview_screen.dart'; 
import 'firebase_options.dart'; // Make sure this import is here

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Uncomment/add these lines:
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
          // 1. Show a loading spinner while Firebase checks the session
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF0F3826)),
              ),
            );
          }

          // 2. If the snapshot has data, the user is logged in
          if (snapshot.hasData) {
            // ---> CHANGED HERE: Return the Overview Screen instead of Profile <---
            return const SpendWiseOverviewScreen();
          }

          // 3. If no user is found, show the Login screen
          return const SpendWiseLoginScreen();
        },
      ),
      
      // Optional: Keep routes if you still need named navigation elsewhere
      routes: {
        '/login': (context) => const SpendWiseLoginScreen(),
        '/profile': (context) => const SpendWiseProfileScreen(),
        // ---> CHANGED HERE: Added the overview screen to your routes <---
        '/overview': (context) => const SpendWiseOverviewScreen(), 
      },
    );
  }
}