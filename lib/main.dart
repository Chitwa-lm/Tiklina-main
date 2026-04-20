import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/job_store.dart';
import 'services/auth_store.dart';
import 'services/supabase_service.dart';
import 'services/cloudinary_service.dart';
import 'config/supabase_config.dart';
import 'config/cloudinary_config.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Validate configuration
  if (!SupabaseConfig.isConfigured) {
    throw Exception(
      'Supabase configuration is missing. Please check your .env file.'
    );
  }
  
  if (!CloudinaryConfig.isConfigured) {
    throw Exception(
      'Cloudinary configuration is missing. Please check your .env file.'
    );
  }
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Initialize Cloudinary
  CloudinaryService.instance.initialize();
  
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
