import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health_tracker/data/repositories/firebase_auth.dart';
import 'package:health_tracker/shared/services/authentication_service.dart';
import 'package:health_tracker/ui/screens/auth/about/about_screen.dart';
import 'package:health_tracker/ui/screens/auth/forgot_password_screen.dart';
import 'package:health_tracker/ui/screens/auth/registration_screen.dart';
import 'package:health_tracker/shared/styles/themes.dart';
import 'package:health_tracker/ui/widgets/button_widget.dart';
import 'package:health_tracker/ui/widgets/textfield_widget.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:sizer/sizer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:health_tracker/shared/utilities/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  void _showErrorToast(String text) {
    try {
      final overlay = Overlay.of(context);
      late OverlayEntry overlayEntry;
      overlayEntry = OverlayEntry(
        builder: (context) {
          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 450),
            tween: Tween(begin: -120.0, end: 40.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Positioned(
                top: value,
                left: 60,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE76B5B),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '!',
                                style: TextStyle(
                                  color: Color(0xFFE76B5B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
      overlay.insert(overlayEntry);
      Future.delayed(const Duration(seconds: 2), () {
        overlayEntry.remove();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(text), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  void _authenticateWithEmailAndPass(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await FirebaseAuthRepo().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted && FirebaseAuth.instance.currentUser != null) {
          Navigator.of(context).pop();
        }
      } on FirebaseAuthException catch (e) {
        final l10n = AppLocalizations.of(context)!;
        String message;
        if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'INVALID_LOGIN_CREDENTIALS') {
          message = l10n.accountOrPasswordIncorrect;
          debugPrint('Login failed: account not found or invalid credentials');
        } else if (e.code == 'wrong-password') {
          message = l10n.wrongPassword;
          debugPrint('Login failed: wrong password for ${_emailController.text.trim()}');
        } else if (e.code == 'invalid-email') {
          message = l10n.invalidEmail;
          debugPrint('Login failed: invalid email format');
        } else {
          message = e.message ?? l10n.loginFailed;
          debugPrint('Login failed: ${e.code} - ${e.message}');
        }
        
        if (mounted) {
          _showErrorToast(message);
        }
      } catch (e) {
        final l10n = AppLocalizations.of(context)!;
        debugPrint('Login failed with unexpected error: $e');
        if (mounted) {
          _showErrorToast(l10n.loginFailed);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            size: 30,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            child: Form(
              key: _formKey,
              child: BounceInDown(
                duration: const Duration(milliseconds: 1500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.welcomeBack,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 20.sp,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 1.5.h,
                    ),
                    Text(
                      l10n.signInToContinue,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 12.sp,
                            letterSpacing: 2,
                          ),
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    MyTextfield(
                      hint: l10n.emailAddress,
                      icon: Icons.email,
                      keyboardtype: TextInputType.emailAddress,
                      validator: (value) {
                        return !Validators.isValidEmail(value!)
                            ? l10n.enterValidEmail
                            : null;
                      },
                      textEditingController: _emailController,
                    ),
                    SizedBox(
                      height: 4.h,
                    ),
                    MyTextfield(
                      hint: l10n.password,
                      icon: Icons.password,
                      keyboardtype: TextInputType.text,
                      obscure: true,
                      validator: (value) {
                        return value!.length < 6
                            ? l10n.enterMinCharacters(6)
                            : null;
                      },
                      textEditingController: _passwordController,
                    ),
                    SizedBox(
                      height: 1.h,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          l10n.forgotPassword,
                          style: TextStyle(
                            fontSize: 8.sp,
                            color: MyThemes.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 2.h,
                    ),
                    ButtonWidget(
                        color: MyThemes.primary,
                        width: 80.w,
                        title: _isLoading ? '...' : l10n.login,
                        func: _isLoading
                            ? null
                            : () async {
                                bool isConnected =
                                    await InternetConnectionChecker().hasConnection;
                                if (isConnected) {
                                  if (!mounted) {
                                    return;
                                  }
                                  _authenticateWithEmailAndPass(context);
                                } else {
                                  _showErrorToast(l10n.checkNetwork);
                                }
                              }),
                    SizedBox(
                      height: 2.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.dontHaveAccount,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontSize: 8.sp, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SignUpScreen()));
                          },
                          child: Text(
                            l10n.signUp,
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                    fontSize: 9.sp,
                                    color: MyThemes.primary,
                                    fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 8.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _myDivider(),
                        const SizedBox(
                          width: 15,
                        ),
                        Text(
                          l10n.or,
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                  fontSize: 9.sp,
                                  color: MyThemes.primary,
                                  fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          width: 15,
                        ),
                        _myDivider(),
                      ],
                    ),
                    SizedBox(
                      height: 4.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                            InkWell(
                              onTap: () async {
                                if (_isLoading) return;
                                setState(() => _isLoading = true);
                                try {
                                  final result = await AuthenticationService().signInWithGoogle();
                                  if (result != null && mounted) {
                                    final uid = FirebaseAuth.instance.currentUser?.uid;
                                    if (uid != null) {
                                      final doc = await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(uid)
                                          .get();
                                      final data = doc.data();
                                      final hasProfile = data != null &&
                                          data['sex'] != null &&
                                          data['weight'] != null &&
                                          data['age'] != null;
                                      if (hasProfile) {
                                        Navigator.of(context).popUntil((route) => route.isFirst);
                                      } else {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) => const AboutYouScreen(fromGoogle: true),
                                          ),
                                        );
                                      }
                                    } else {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) => const AboutYouScreen(fromGoogle: true),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  debugPrint('Google sign-in error: $e');
                                  if (mounted) {
                                    _showErrorToast(l10n.googleLoginFailed(e.toString()));
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                          child: Image.asset(
                            'assets/icons/google.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(
                          width: 40,
                        ),
                        InkWell(
                          onTap: () {
                            _showErrorToast(l10n.comingSoon);
                          },
                          child: Image.asset(
                            'assets/icons/facebook.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container _myDivider() {
    return Container(
      width: 27.w,
      height: 0.2.h,
      color: Theme.of(context).dividerColor,
    );
  }
}
