import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lmm/home.dart';
import 'package:lmm/main.dart';
import 'package:loader_overlay/loader_overlay.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  VoidCallback? _loggedInListener;
  final _formKey = GlobalKey<FormState>();
  String? email, password;
  var register = false;

  @override
  void initState() {
    super.initState();
    _loggedInListener = () {
      if (LMMPApp.loggedIn.value && mounted) {
        goHome();
      }
    };
    LMMPApp.loggedIn.addListener(_loggedInListener!);
  }

  @override
  void dispose() {
    LMMPApp.loggedIn.removeListener(_loggedInListener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoaderOverlay(
      overlayColor: Colors.white,
      child: Scaffold(
        appBar: AppBar(
          elevation: 10.0,
          centerTitle: true,
          title: Text(
            'LMMP',
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              fontSize: 24.0,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              Text(
                (register) ? 'Register' : 'Sign in',
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.bold,
                  fontSize: 32.0,
                ),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                validator: (value) {
                  if (EmailValidator.validate(value ?? '')) {
                    return null;
                  } else {
                    return 'invalid address.';
                  }
                },
                onChanged: (value) => email = value,
                decoration: InputDecoration(
                  labelText: 'email address',
                  labelStyle: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                onChanged: (value) {
                  _formKey.currentState?.validate();
                  setState(() {
                    password = value;
                  });
                },
                validator: (value) {
                  if (!register) {
                    return null;
                  }

                  value ??= '';
                  if (value.isEmpty) {
                    return 'cannot be empty.';
                  }
                  if (value.length < 8) {
                    return 'password too short.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'password',
                  labelStyle: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(height: 20.0),
              (register)
                  ? TextFormField(
                      onChanged: (_) => _formKey.currentState?.validate(),
                      validator: (value) {
                        if (value == password) {
                          return null;
                        }
                        return 'passwords do not match.';
                      },
                      decoration: InputDecoration(
                        labelText: 'confirm password',
                        labelStyle: GoogleFonts.quicksand(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    )
                  : Container(),
              const SizedBox(height: 40.0),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    context.loaderOverlay.show();
                  });
                  if (await (register ? tryRegister() : tryLogin())) {
                    goHome();
                  } else {
                    showSnack('Invalid email or password.');
                    setState(() {
                      context.loaderOverlay.hide();
                    });
                  }
                },
                child: Text(
                  (register) ? 'Register' : 'Sign in',
                  style: GoogleFonts.quicksand(
                    fontSize: 20.0,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  register = !register;
                }),
                child: Text(
                  (register) ? 'sign in instead' : 'register instead',
                  style: GoogleFonts.quicksand(
                    fontSize: 18.0,
                    color: Colors.blue[800],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(),
      ),
    );
  }

  Future<bool> tryRegister() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential user =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email!, password: password!);

        if (user.user == null) {
          if (mounted) {
            // Check if the State is still mounted
            showSnack('Could not register.');
          }
        } else {
          return true;
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          // Check if the State is still mounted
          if (e.code == 'weak-password') {
            showSnack('The password provided is too weak.');
          } else if (e.code == 'email-already-in-use') {
            showSnack('The account already exists for that email.');
          }
        }
      } catch (e) {
        print(e);
      }
    }
    return false;
  }

  Future<bool> tryLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential user =
            await FirebaseAuth.instance.signInWithEmailAndPassword(email: email!, password: password!);

        if (user.user == null) {
          if (mounted) {
            // Check if the State is still mounted
            showSnack('Could not sign in');
          }
        } else {
          return true;
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          // Check if the State is still mounted
          if (e.code == 'user-not-found') {
            showSnack('No user found for that email.');
          } else if (e.code == 'wrong-password') {
            showSnack('Wrong password provided for that user.');
          }
        }
      } catch (e) {
        if (mounted) {
          // Check if the State is still mounted
          showSnack('Something went wrong.');
        }
      }
    }
    return false;
  }
}
