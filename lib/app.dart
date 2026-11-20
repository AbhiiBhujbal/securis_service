
import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/service_home_page.dart';
import 'services/auth_service.dart';

class SecurisServiceApp extends StatelessWidget {
  const SecurisServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Securis Service',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2457D6),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7FC),
          foregroundColor: Color(0xFF18233B),
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const LoginScreen();
        }

        if (snapshot.data != true) {
          return const LoginScreen();
        }

        return FutureBuilder<List<String>>(
          future: Future.wait([
            AuthService.getRole(),
            AuthService.getTechnicianName(),
          ]),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (userSnapshot.hasError ||
                userSnapshot.data == null) {
              return const LoginScreen();
            }

            final savedRole = userSnapshot.data![0];
            final savedTechnicianName = userSnapshot.data![1];

            return ServiceHomePage(
              initialRole: savedRole,
              technicianName: savedTechnicianName,
            );
          },
        );
      },
    );
  }
}
