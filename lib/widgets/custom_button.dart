import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Function() onPressed;
  final Size? size;
  final double? fontSize;
  final Icon? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.size,
    this.fontSize,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        // Using minimumSize ensures the button fills the SizedBox constraints
        minimumSize: Size(size?.width ?? 0, size?.height ?? 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: icon != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown, // Shrinks text if it doesn't fit
                    child: Text(
                      text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize ?? 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10), // Gap between text and icon
                icon!,
              ],
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize ?? 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}