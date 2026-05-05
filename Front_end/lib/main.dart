import 'package:LearnLink/screens/learning_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_page.dart';
import 'screens/news_screen.dart';
import 'screens/signup_page.dart';
import 'screens/main_home_screen.dart';
import 'services/auth_services.dart';
import 'utils/constants.dart';


import 'screens/jobs_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const LearnLinkApp());
}

class LearnLinkApp extends StatelessWidget {
  const LearnLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        title: 'LearnLink',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignUpPage(),
          '/home': (context) => const MainHomeScreen(),
          '/jobs': (context) => const JobsScreen(),
          '/news': (context) => const NewsScreen(),
          '/learning': (context) => const LearningScreen()

        },
      ),
    );
  }
}

// Auth Wrapper to handle initial routing
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is signed in, check if they have completed profile
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: Provider.of<AuthService>(context, listen: false).getUserProfile(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // If profile exists, go to home
              if (profileSnapshot.hasData && profileSnapshot.data != null) {
                return const MainHomeScreen();
              }

              // If no profile, they need to complete signup (shouldn't happen normally)
              // In this case, sign them out and show login
              Provider.of<AuthService>(context, listen: false).signOut();
              return const LoginPage();
            },
          );
        }

        // User is not signed in, show login page
        return const LoginPage();
      },
    );
  }
}