import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:newdemo/funtions/build_app_bar.dart';
import 'package:newdemo/service/auth.dart';
import 'HomePage.dart';
import 'SignInPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isloading = false;
  final TextEditingController emailCont = TextEditingController();
  final TextEditingController passwordCont = TextEditingController();
  String? errorMessage;

  Future<void> signIn() async {
    try {
      await Auth().signIn(email: emailCont.text, password: passwordCont.text);
      // Navigate to HomePage after successful login
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CineRoomApp()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        appBar: buildAppBar(),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/images/backgroundoflogin.png'),
              fit: BoxFit.cover,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTextField(emailCont, "email"),
              const SizedBox(height: 10),
              _buildTextField(passwordCont, "password", obscureText: true),
              const SizedBox(height: 10),
              errorMessage != null
                  ? Text(errorMessage!)
                  : const SizedBox.shrink(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                ElevatedButton(
                  onPressed: signIn,
                  child: const Text(
                    "LogIn",
                    style: TextStyle(
                      color: Color.fromARGB(255, 44, 40, 40),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignInPage()),
                    );
                  },
                  child: const Text(
                    "Sign up",
                    style: TextStyle(
                      color: Color.fromARGB(255, 44, 40, 40),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(8.0),
          child: const Text(
            '© 2024 All Rights Reserved',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText,
      {bool obscureText = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          border: const OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }
}
