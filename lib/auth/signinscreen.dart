import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reelsapp/auth/auth_services.dart';
import 'package:reelsapp/auth/signup_screen.dart';
import 'package:reelsapp/global/custom_text_field.dart';
import '../global/app_colors.dart';
import '../global/button.dart';
import '../video_screen/homepage.dart';
import 'forget_password.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }

    String pattern = r'^[^@]+@[^@]+\.[^@]+';
    if (!RegExp(pattern).hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }



  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      String email = emailController.text.trim();
      String password = passwordController.text.trim();
      try {
        var user = await _authService.signInWithEmailAndPassword(
            email, password, context);
        if (user != null) {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>
              const VideoFeedScreen(),
              )
          );
        }

      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'wrong-password') {
          message = 'Incorrect password. Please try again.';
        } else if (e.code == 'user-not-found') {
          message = 'No user found with this email.Please try again.';
        } else {
          message = 'Sign in failed: ${e.message}';
        }
        setState(() {
          _errorMessage = message;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red, content: Text(_errorMessage!)));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;

    return Scaffold(
        appBar: AppBar(
          title: const Padding(
            padding: EdgeInsets.symmetric(vertical: 15.0),
            child: Text('Log In',
                style: TextStyle(
                  fontSize: 20,
                  color: AppColors.mainColor,
                )),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.asset(
                      "assets/Images/login.png",
                      height: 100,
                      width: 100,
                    )),
              ),
              SizedBox(height: screenHeight * 0.05),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: emailController,
                        hintText: 'Enter your email',
                        isPassword: false,
                        validator: _validateEmail,
                      ),
                      SizedBox(
                        height: screenHeight * 0.03,
                      ),
                      CustomTextField(
                        controller: passwordController,
                        hintText: 'Enter your password',
                        isPassword: true,
                        validator: _validatePassword,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 30.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(),
                            InkWell(
                              onTap: () {
                                 Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) =>
                                    const ForgotPasswordPage(),
                                )
                              );
                              },
                              child: const Text(
                                "Forget Password?",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20.0,
                      ),
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.mainColor,
                              ),
                            )
                          : Button(
                              name: "Log In",
                              onPressed: () {
                                _signIn();
                              }),
                      const SizedBox(
                        height: 20.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(color: Colors.grey),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>
                                  const SignUpScreen(),
                                  )
                              );
                            },
                            child: const Text(
                              "Sign up",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
