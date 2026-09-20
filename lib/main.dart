import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paywise/providers/loan_provider.dart';
import 'package:paywise/providers/settings_provider.dart';
import 'package:paywise/services/notification_service.dart';
import 'package:paywise/Screens/splash_screen.dart';
import 'package:paywise/Screens/login_screen.dart';
import 'package:paywise/Screens/register_screen.dart';
import 'package:paywise/Screens/main_shell.dart';
import 'package:paywise/Screens/add_loan_screen.dart';
import 'package:paywise/Screens/loan_details_screen.dart';
import 'package:paywise/Screens/loan_history_screen.dart';
import 'package:paywise/Screens/profile_screen.dart';
import 'package:paywise/Screens/edit_info_screen.dart';
import 'package:paywise/Screens/welcome_screen.dart';
import 'package:paywise/Screens/privacy_policy_screen.dart';
import 'package:paywise/theme/glass_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:paywise/services/auth_service.dart';
import 'package:paywise/widgets/undo_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Completely disable all debug logs in release mode
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    // Enable offline disk persistence so Firestore serves cached data instantly on startup
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      debugPrint("Firebase Init Error: $e");
    }
  }

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint("Notification Init Error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoanProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsProvider, ThemeMode>(
      selector: (_, settings) => settings.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'PayWise',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          themeAnimationDuration: Duration.zero,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Color(0xFF1E1E1E),
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: SmoothPageTransitionsBuilder(),
                TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
                TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
                TargetPlatform.windows: SmoothPageTransitionsBuilder(),
              },
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: SmoothPageTransitionsBuilder(),
                TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
                TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
                TargetPlatform.windows: SmoothPageTransitionsBuilder(),
              },
            ),
          ),
          home: const SplashWrapper(),
          onGenerateRoute: (settings) {
            final Map<String, WidgetBuilder> routes = {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/dashboard': (context) => const MainShell(),
              '/add_loan': (context) => const AddLoanScreen(),
              '/loan_details': (context) => const LoanDetailsScreen(),
              '/loan_history': (context) => const LoanHistoryScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/edit_info': (context) => const EditInfoScreen(),
              '/welcome': (context) => const WelcomeScreen(),
              '/privacy_policy': (context) => const PrivacyPolicyScreen(),
            };

            final builder = routes[settings.name];
            if (builder != null) {
              return _buildPageRoute(builder(context), settings);
            }
            return null;
          },
        );
      },
    );
  }

  static Route<dynamic> _buildPageRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0.0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}

// ── Splash Wrapper: Shows animated splash, then transitions to AuthWrapper ──
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _splashComplete = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashComplete) {
      return SplashScreen(
        onComplete: () {
          if (mounted) {
            setState(() => _splashComplete = true);
          }
        },
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: const AuthWrapper(key: ValueKey('auth')),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _isLocked = true;
  bool _hasCheckedBiometrics = false;
  bool _loansInitialized = false; 
  String? _checkedUserId;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && settings.biometricEnabled && !_isAuthenticating) {
        setState(() {
          _isLocked = true;
          _hasCheckedBiometrics = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && settings.biometricEnabled && _isLocked && !_isAuthenticating) {
        _checkBiometricLock();
      }
    }
  }

  Future<void> _checkAccountDeletionStatus(User user) async {
    if (_checkedUserId == user.uid) return;
    _checkedUserId = user.uid;

    final authService = AuthService();
    final status = await authService.checkDeletionStatus(user.uid);

    if (status['deletionScheduled'] == true) {
      final bool isExpired = status['isExpired'] == true;
      final DateTime? scheduledDate = status['scheduledDate'] as DateTime?;

      if (isExpired) {
        try {
          await authService.purgeUserDataAndAccount(user.uid);
          await authService.signOut();
          final rootCtx = navigatorKey.currentContext;
          if (rootCtx != null && rootCtx.mounted) {
            Provider.of<LoanProvider>(rootCtx, listen: false).clearUserData();
            UndoToastManager.showErrorToast(
              context: rootCtx,
              title: "Account Permanently Deleted",
              subtitle: "Your 7-day grace period expired and account data was erased.",
            );
          }
        } catch (e) {
          debugPrint("Scheduled purge error: $e");
          await authService.signOut();
        }
      } else {
        if (mounted) {
          final String dateStr = scheduledDate != null
              ? "${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}"
              : "soon";

          GlassTheme.showGlassDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => GlassAlertDialog(
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A36B1).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restore_rounded, color: Color(0xFF2A36B1), size: 30),
              ),
              title: const Text(
                "Restore Scheduled Account?",
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              content: Text(
                "Welcome back! Your account was scheduled for deletion on $dateStr.\n\nWould you like to restore your account and cancel deletion?",
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await authService.signOut();
                    if (mounted) {
                      Provider.of<LoanProvider>(context, listen: false).clearUserData();
                    }
                  },
                  child: const Text("Keep Scheduled & Log Out", style: TextStyle(color: Color(0xFFDC2626))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A36B1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await authService.cancelAccountDeletion(user.uid);
                    final rootCtx = navigatorKey.currentContext;
                    if (rootCtx != null && rootCtx.mounted) {
                      UndoToastManager.showSuccessToast(
                        context: rootCtx,
                        title: "Account Restored!",
                        subtitle: "Deletion cancelled. Welcome back to PayWise!",
                      );
                    }
                  },
                  child: const Text("Restore Account", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkBiometricLock();
  }

  Future<void> _checkBiometricLock() async {
    if (_hasCheckedBiometrics || _isAuthenticating) return;

    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && settings.biometricEnabled) {
        _isAuthenticating = true;
        bool authenticated = false;
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          authenticated = await settings.authenticate();
        } catch (e) {
          debugPrint("Biometric Check Failed: $e");
          authenticated = false; // FAIL CLOSED: Never bypass biometric lock on error
        } finally {
          _isAuthenticating = false;
        }
        
        if (mounted) {
          setState(() {
            _isLocked = !authenticated;
            _hasCheckedBiometrics = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLocked = false;
            _hasCheckedBiometrics = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Biometric Check Error: $e");
      if (mounted) {
        setState(() {
          _isLocked = false;
          _hasCheckedBiometrics = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedBiometrics) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (streamContext, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAccountDeletionStatus(user);
          });

          if (_isLocked) {
             return Scaffold(
               body: Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.lock, size: 80, color: Colors.indigo),
                     const SizedBox(height: 20),
                     const Text("App Locked", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 20),
                     ElevatedButton(
                       onPressed: () {
                         _hasCheckedBiometrics = false;
                         _checkBiometricLock();
                       }, 
                       child: const Text("Unlock with Biometrics")
                     ),
                      TextButton(
                        onPressed: () async {
                          final loanProv = Provider.of<LoanProvider>(context, listen: false);
                          await AuthService().signOut();
                          loanProv.clearUserData();
                          if (mounted) {
                            setState(() { _isLocked = false; });
                          }
                        }, 
                        child: const Text("Log Out")
                      )
                    ],
                  ),
                ),
              );
           }
           
           if (!_loansInitialized || _checkedUserId != user.uid) {
              _checkedUserId = user.uid;
              _loansInitialized = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<LoanProvider>(context, listen: false).initLoans();
              });
           }

           return const MainShell();
        }
        
        _loansInitialized = false;
        _checkedUserId = null;
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (futureCtx, prefsSnap) {
            if (!prefsSnap.hasData) {
              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: const Center(child: CircularProgressIndicator()),
              );
            }
            final hasSeenWelcome = prefsSnap.data!.getBool('hasSeenWelcome') ?? false;
            if (!hasSeenWelcome) {
              return const WelcomeScreen();
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}

class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideTween = Tween<Offset>(
      begin: const Offset(0.06, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic));

    final fadeTween = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOut));

    return SlideTransition(
      position: animation.drive(slideTween),
      child: FadeTransition(
        opacity: animation.drive(fadeTween),
        child: child,
      ),
    );
  }
}