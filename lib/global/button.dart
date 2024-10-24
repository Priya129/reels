import 'package:flutter/material.dart';
import 'app_colors.dart';

class Button extends StatelessWidget {
  final String name;
  final VoidCallback onPressed;

  const Button({
    super.key,
    required this.name,
    required this.onPressed,
});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(AppColors.mainColor),
          fixedSize: WidgetStateProperty.all<Size>(const Size(500,50)),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            )
          )
        ),

        child: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        )
    );
  }
}