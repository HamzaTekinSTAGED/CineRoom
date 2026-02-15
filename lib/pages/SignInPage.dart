import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:newdemo/service/auth.dart';
import 'login_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController emailCont = TextEditingController();
  final TextEditingController passwordCont = TextEditingController();
  final TextEditingController passwordCont2 = TextEditingController();
  final TextEditingController nicknameCont = TextEditingController();
  String? errorMessage;

  Future<void> createUser() async {
    try {
      // Check if the nickname is unique
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('nickname', isEqualTo: nicknameCont.text)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          errorMessage = "Nickname is already taken. Please choose another.";
        });
        return;
      }

      // Create user in Firebase Auth
      await Auth().createUser(
          email: emailCont.text,
          password: passwordCont.text,
          nickname: nicknameCont.text);

      // Redirect to LoginPage after successful registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Sign Up',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/images/backgroundoflogin.png'),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: nicknameCont,
                  decoration: const InputDecoration(
                    hintText: "nickname",
                  ),
                  style:
                      const TextStyle(color: Color.fromARGB(255, 11, 13, 14)),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: emailCont,
                  decoration: const InputDecoration(
                    hintText: "email",
                  ),
                  style:
                      const TextStyle(color: Color.fromARGB(255, 11, 13, 14)),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: passwordCont,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "password",
                  ),
                  style:
                      const TextStyle(color: Color.fromARGB(255, 11, 13, 14)),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: passwordCont2,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "password again",
                  ),
                  style:
                      const TextStyle(color: Color.fromARGB(255, 11, 13, 14)),
                ),
              ),
              const SizedBox(height: 8),
              errorMessage != null
                  ? Text(errorMessage!)
                  : const SizedBox.shrink(),
              ElevatedButton(
                onPressed: () {
                  if (passwordCont.text == passwordCont2.text) {
                    createUser();
                  } else {
                    setState(() {
                      errorMessage = "Passwords do not match";
                    });
                  }
                },
                child: const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
