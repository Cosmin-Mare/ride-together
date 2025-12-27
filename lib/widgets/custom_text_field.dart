import 'package:flutter/material.dart';
import 'package:ride_together/design_constants.dart';

class CustomTextField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final bool isEmail;
  final bool isPhone;
  final bool isName;
  final bool isAddress;
  final bool isZip;

  const CustomTextField({super.key, this.hintText, this.controller, this.isPassword = false, this.isEmail = false, this.isPhone = false, this.isName = false, this.isAddress = false, this.isZip = false});

  @override
  Widget build(BuildContext context) {
    final double scale = DesignConstants.calculateScale(MediaQuery.of(context).size.width);

    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : isPhone ? TextInputType.phone : isName ? TextInputType.name : isAddress ? TextInputType.streetAddress : isZip ? TextInputType.number : TextInputType.text,
      cursorColor: Colors.black,
      style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hintText,
        
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade100, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),

        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade800, width: 3),
          borderRadius: BorderRadius.circular(20),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 4),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}