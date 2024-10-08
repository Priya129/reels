import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reelsapp/Routes/routes.dart';
import '../global/app_colors.dart';
import 'auth_services.dart';
import '../global/button.dart';
import '../global/custom_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();
  Uint8List? image;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> selectImage() async {
    try {
      final pickedfile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedfile != null) {
        Uint8List pickedImage = await pickedfile.readAsBytes();
        setState(() {
          image = pickedImage;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<String?> uploadImage() async {
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick an image")),
      );
      return null;
    }
    try {
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child("profilePic/${DateTime.now().millisecondsSinceEpoch}");
      UploadTask uploadTask = storageRef.putData(image!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        var user = await _authService.signUpWithEmailAndPassword(
          emailController.text.trim(),
          passwordController.text.trim(),
          context,
        );
        if (user != null) {
          String? imageUrl = await uploadImage();
          if (imageUrl != null) {
            await _authService.saveUserData(
              user.uid,
              emailController.text.trim(),
              usernameController.text.trim(),
              imageUrl,
              context,
            );
          }
          Routes().navigateToHomePage(context);
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: ${e.message}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.symmetric(vertical: 15.0),
          child: Center(
            child: Text('Register', style: TextStyle(color: AppColors.mainColor, fontSize: 20)),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: GestureDetector(
                      onTap: selectImage,
                      child: CircleAvatar(
                        radius: 64,
                        backgroundImage: image != null
                            ? MemoryImage(image!) as ImageProvider<Object>
                            : const NetworkImage('https://i.stack.imgur.com/l60Hf.png'),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Center(
                    child: Text(
                      "Register with an email...",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            controller: usernameController,
                            hintText: 'Enter your username',
                            isPassword: false,
                          ),
                          const SizedBox(height: 25),
                          CustomTextField(
                            controller: emailController,
                            hintText: 'Enter your email',
                            isPassword: false,
                          ),
                          const SizedBox(height: 25),
                          CustomTextField(
                            controller: passwordController,
                            hintText: 'Enter your password',
                            isPassword: true,
                          ),
                          const SizedBox(height: 25),
                          CustomTextField(
                            controller: repeatPasswordController,
                            hintText: 'Confirm your password',
                            isPassword: true,
                          ),
                          const SizedBox(height: 40.0),
                          _isLoading
                              ? const Center(
                            child: CircularProgressIndicator(color: AppColors.mainColor),
                          )
                              : Button(name: "Sign Up", onPressed: _signUp),
                          const SizedBox(height: 40.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account?", style: TextStyle(color: Colors.grey)),
                              InkWell(
                                onTap: () {
                                  Routes().navigateToSignInScreen(context);
                                },
                                child: const Text(
                                  " Sign in",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
