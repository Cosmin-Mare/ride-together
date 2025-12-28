import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Function() onPressed;
  final Size? size;
  final double? fontSize;
  final Icon? icon;

  const CustomButton({super.key, required this.text, required this.onPressed, this.size, this.fontSize, this.icon});

  @override
Widget build(BuildContext context) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: size?.width ?? 20, 
        vertical: size?.height ?? 10
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    child: icon != null 
      ? Row(
          mainAxisSize: MainAxisSize.min, // Fix 1: Don't take full width
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fix 2: Wrap text in Flexible if it's very long
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: fontSize ?? 16, 
                  fontWeight: FontWeight.bold
                ),
                overflow: TextOverflow.ellipsis, // Prevents text from pushing icon off-screen
              ),
            ),
            const SizedBox(width: 8), // Add a small gap between text and icon
            icon!,
          ],
        ) 
      : Text(
          text, 
          style: TextStyle(
            color: Colors.white, 
            fontSize: fontSize ?? 16, 
            fontWeight: FontWeight.bold
          )
        ),
  );
}
  }