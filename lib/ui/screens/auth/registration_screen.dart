import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health_tracker/data/repositories/firebase_auth.dart';
import 'package:health_tracker/shared/utilities/utils.dart';
import 'package:health_tracker/ui/screens/auth/login_screen.dart';
import 'package:health_tracker/shared/constants/consts_variables.dart';
import 'package:health_tracker/shared/styles/themes.dart';
import 'package:health_tracker/ui/widgets/button_widget.dart';
import 'package:health_tracker/ui/widgets/textfield_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:sizer/sizer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:health_tracker/shared/utilities/validators.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  Sex? _sex = Sex.male;
  Uint8List? _image;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  selectImage() async {
    Uint8List image = await pickImage(ImageSource.gallery);
    setState(() {
      _image = image;
    });
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
          physics: const ScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            child: Form(
              key: _formKey,
              child: BounceInDown(
                duration: const Duration(milliseconds: 1500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SizedBox(
                    //   height: 8.h,
                    // ),
                    Text(l10n.hey,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 20.sp,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 1.5.h,
                    ),
                    Text(
                      l10n.createNewAccount,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 12.sp,
                            letterSpacing: 2,
                            // fontWeight: FontWeight.bold
                          ),
                    ),
                    SizedBox(
                      height: 6.h,
                    ),
                    Center(
                      child: Stack(
                        children: [
                          _image != null
                              ? CircleAvatar(
                                  radius: 54,
                                  backgroundImage: MemoryImage(_image!),
                                  backgroundColor: Colors.red,
                                )
                              : const CircleAvatar(
                                  radius: 54,
                                  backgroundImage: NetworkImage(
                                      'https://i.stack.imgur.com/l60Hf.png'),
                                  backgroundColor: Colors.red,
                                ),
                          Positioned(
                            bottom: -10,
                            left: 70,
                            child: IconButton(
                              onPressed: selectImage,
                              icon: const Icon(Icons.add_a_photo),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 2.h,
                    ),
                    MyTextfield(
                      hint: l10n.username,
                      icon: Icons.person,
                      keyboardtype: TextInputType.emailAddress,
                      validator: (value) {
                        return value!.length < 3 ? l10n.invalidName : null;
                      },
                      textEditingController: _nameController,
                    ),
                    SizedBox(
                      height: 2.h,
                    ),
                    Row(
                      children: [
                        Radio<Sex>(
                          value: Sex.male,
                          groupValue: _sex,
                          onChanged: (Sex? value) {
                            setState(() {
                              _sex = value;
                            });
                          },
                          activeColor: Colors.red,
                        ),
                        Text(l10n.male),
                        Radio<Sex>(
                          value: Sex.female,
                          groupValue: _sex,
                          onChanged: (Sex? value) {
                            setState(() {
                              _sex = value;
                            });
                          },
                          activeColor: Colors.red,
                        ),
                        Text(l10n.female),
                      ],
                    ),
                    SizedBox(
                      height: 2.h,
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
                      height: 4.h,
                    ),
                    ButtonWidget(
                        color: MyThemes.primary,
                        width: 80.w,
                        title: _isLoading ? '...' : l10n.createAccount.toUpperCase(),
                        func: _isLoading
                            ? null
                            : () async {
                                bool isConnected =
                                    await InternetConnectionChecker().hasConnection;

                                if (isConnected) {
                                  if (!mounted) {
                                    return;
                                  }
                                  await _signUpWithEmailAndPass(context);
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
                          l10n.alreadyHaveAccount,
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
                                    builder: (context) => const LoginScreen()));
                          },
                          child: Text(
                            l10n.login,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
                left: 0,
                right: 0,
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
                                  fontSize: 14,
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

  Future<void> _signUpWithEmailAndPass(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await FirebaseAuthRepo().register(
          username: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          sex: _sex!,
          file: _image,
        );
        
        if (mounted && FirebaseAuth.instance.currentUser != null) {
          Navigator.of(context).pop();
        }
      } on FirebaseAuthException catch (e) {
        final l10n = AppLocalizations.of(context)!;
        String message;
        if (e.code == 'weak-password') {
          message = l10n.weakPassword;
          debugPrint('Registration failed: weak password');
        } else if (e.code == 'email-already-in-use') {
          message = l10n.emailAlreadyInUse;
          debugPrint('Registration failed: email ${_emailController.text.trim()} already in use');
        } else if (e.code == 'invalid-email') {
          message = l10n.invalidEmail;
          debugPrint('Registration failed: invalid email format');
        } else {
          message = e.message ?? l10n.registrationFailed;
          debugPrint('Registration failed: ${e.code} - ${e.message}');
        }
        
        if (mounted) {
          _showErrorToast(message);
        }
      } catch (e) {
        final l10n = AppLocalizations.of(context)!;
        debugPrint('Registration failed with unexpected error: $e');
        if (mounted) {
          _showErrorToast(l10n.registrationFailed);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
