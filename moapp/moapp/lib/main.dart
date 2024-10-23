import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shrine/map_page.dart';
import 'package:shrine/login.dart';
import 'package:shrine/profile.dart';
import 'package:shrine/pose_detector_view.dart';
import 'package:camera/camera.dart';
import 'app_state.dart';
import 'firebase_options.dart';
import 'home.dart';
import 'user_info_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 카메라 리스트를 초기화
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    print('Error initializing cameras: $e');
  }

  runApp(ChangeNotifierProvider(
    create: (context) => ApplicationState(),
    builder: ((context, child) =>
        Consumer<ApplicationState>(builder: (context, appState, _) {
          return App(cameras: cameras);
        })),
  ));
}

Future<void> checkUserData(uid, email, name, BuildContext context) async {
  DocumentSnapshot doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  print(doc.exists);
  if (!doc.exists) {
    context.go('/userinfo');
  } else {
    context.go('/');
  }
}

Future<void> checkAnonData(uid, BuildContext context) async {
  DocumentSnapshot doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (!doc.exists) {
    context.go('/userinfo');
  } else {
    context.go('/');
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          Consumer<ApplicationState>(builder: (context, appState, _) {
        return HomePage();
      }),
      routes: [
        GoRoute(path: 'profile', builder: (context, state) => const Profile()),
        GoRoute(
          path: 'wishlist',
          builder: (context, state) => PoseDetectorView(),
        ),
        GoRoute(path: 'add', builder: (context, state) => MapScreen()),
      ],
    ),
    GoRoute(
      path: "/login",
      builder: (context, state) => StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              final user = snapshot.data!;
              if (user.isAnonymous) {
                checkAnonData(user.uid, context);
                return const HomePage();
              } else {
                checkUserData(user.uid, user.email, user.displayName, context);
                return const HomePage();
              }
            } else {
              return const LoginPage();
            }
          } else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    ),
    GoRoute(
      path: '/userinfo',
      builder: (context, state) =>
          UserInfoPage(user: FirebaseAuth.instance.currentUser!),
    ),
  ],
);

class App extends StatelessWidget {
  final List<CameraDescription> cameras;

  const App({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Meetup',
      theme: ThemeData(
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
              highlightColor: Colors.deepPurple,
            ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
