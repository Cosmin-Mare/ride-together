import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ride_together/widgets/custom_button.dart';
import 'package:ride_together/home.dart';
import 'package:ride_together/widgets/custom_text_field.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String errorMessage = "";

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Ride Together', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              SizedBox(height: 80),
              CustomTextField(
                hintText: 'Email',
                controller: emailController,
                isEmail: true,
              ),
              SizedBox(height: 10),
              CustomTextField(
                hintText: 'Password',
                controller: passwordController,
                isPassword: true,
              ),
              SizedBox(height: 10),
              Text(errorMessage, style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
              CustomButton(
                size: Size(20, 40),
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: emailController.text,
                      password: passwordController.text,
                    );
                  } on FirebaseAuthException catch (e) {
                    setState(() {
                      switch (e.code) {
                        case 'invalid-email':
                          errorMessage = "Invalid email";
                          break;
                        case 'wrong-password':
                          errorMessage = "Invalid password";
                          break;
                        case 'user-not-found':
                          errorMessage = "User not found";
                          break;
                        case 'user-disabled':
                          errorMessage = "User disabled";
                          break;
                        case 'too-many-requests':
                          errorMessage = "Too many requests";
                          break;
                        case 'invalid-credential':
                          errorMessage = "Your account uses a different sign-in method";
                          break;
                        default:
                          errorMessage = "An unknown error occurred";
                          break;
                      }
                    });
                      
                  }
                },
                text: "Login",
              ),
              CustomButton(
                size: Size(20, 40),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Signup())),
                text: "Create an account",
              ),
              CustomButton(
                size: Size(20, 40),
                onPressed: () async {
                  GoogleSignIn.instance.initialize(serverClientId: "216937294504-ffol61d6j3hhjuejumcga1sjj94hh96c.apps.googleusercontent.com");
                  final googleSignInResult = await GoogleSignIn.instance.authenticate();
                  final result = await FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(
                    idToken: googleSignInResult.authentication.idToken,
                  ));
                  if(result.user != null){
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
                  }
                },
                text: "Login with Google",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final displayNameController = TextEditingController();
  String errorMessage = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ride Together', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            SizedBox(height: 80),
            CustomTextField(
              hintText: 'Display Name',
              controller: displayNameController,
              isName: true,
            ),
            SizedBox(height: 10),
            CustomTextField(
              hintText: 'Email',
              controller: emailController,
              isEmail: true,
            ),
            SizedBox(height: 10),
            CustomTextField(
              hintText: 'Password',
              controller: passwordController,
              isPassword: true,
            ),
            SizedBox(height: 10),
            CustomTextField(
              hintText: 'Confirm Password',
              controller: confirmPasswordController,
              isPassword: true,
            ),
            SizedBox(height: 10),
            if(errorMessage.isNotEmpty)...[
              Text(errorMessage, style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 10,
              children: [
                CustomButton(
                  size: Size(20, 40),
                  onPressed: () async {
                    try {
                      if(passwordController.text != confirmPasswordController.text){
                        setState(() {
                          errorMessage = "Passwords do not match";
                        });
                        return;
                      }
                      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailController.text,
                        password: passwordController.text,
                      );
                      if(result.user != null){
                        await result.user!.updateDisplayName(displayNameController.text);
                        await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
                          'displayName': displayNameController.text,
                          'email': emailController.text,
                          'password': passwordController.text,
                          'createdAt': DateTime.now(),
                          'updatedAt': DateTime.now(),
                          'uid': result.user!.uid,
                        });
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
                
                      }
                    } on FirebaseAuthException catch (e) {
                      print(e);
                      setState(() {
                        switch (e.code) {
                          case 'invalid-email':
                            errorMessage = "Invalid email";
                            break;
                          case 'weak-password':
                            errorMessage = "Weak password";
                            break;
                          case 'email-already-in-use':
                            errorMessage = "Email already in use";
                            break;
                          case 'operation-not-allowed':
                            errorMessage = "Operation not allowed";
                            break;
                          case 'too-many-requests':
                            errorMessage = "Too many requests";
                            break;
                          case 'invalid-credential':
                            errorMessage = "Your account uses a different sign-in method";
                            break;
                          default:
                            errorMessage = "An unknown error occurred";
                            break;
                        }
                      });
                    }
                  },
                  text: "Sign up",
                ),
                CustomButton(
                  size: Size(20, 40),
                  onPressed: () async {
                    GoogleSignIn.instance.initialize(serverClientId: "216937294504-ffol61d6j3hhjuejumcga1sjj94hh96c.apps.googleusercontent.com");
                    final googleSignInResult = await GoogleSignIn.instance.authenticate();
                    final result = await FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(
                      idToken: googleSignInResult.authentication.idToken,
                    ));
                    if(result.user != null){
                      await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
                        'displayName': result.user!.displayName,
                        'email': result.user!.email,
                        'createdAt': DateTime.now(),
                        'updatedAt': DateTime.now(),
                      });
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
                    }
                                    },
                    text: "Sign up with Google",
                ),
              ],
            ),
            CustomButton(
              size: Size(120, 40),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Login())),
              text: "Login",
            ),
            ],
          ),
        ),
      ),
    );
  }
}