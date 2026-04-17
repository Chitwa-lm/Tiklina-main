import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/job_store.dart';
import 'services/auth_store.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: JobStore.instance),
        ChangeNotifierProvider.value(value: AuthStore.instance),
      ],
      child: MaterialApp(
        title: 'Tiklina Waste Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
