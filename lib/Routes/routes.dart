import 'package:flutter/material.dart';
import 'package:reelsapp/auth/signinscreen.dart';
import 'package:reelsapp/auth/signup_screen.dart';
import '../manpage.dart';


class Routes {


  void navigateToSignUpScreen(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => SignUpScreen()),
    );
  }

  void navigateToHomePage(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MainPage()),
    );
  }


  void navigateToSignInScreen(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) =>   SignInScreen()),
    );
  }


}