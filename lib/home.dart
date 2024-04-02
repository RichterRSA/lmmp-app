import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lmm/authentication.dart';
import 'package:lmm/main.dart';
import 'package:lmm/map_page.dart';
import 'package:lmm/overview.dart';
import 'package:loader_overlay/loader_overlay.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int page = 0;

  @override
  void initState() {
    LMMPApp.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: LoaderOverlay(
        child: Scaffold(
          appBar: AppBar(
            actions: [
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      goLogin();
                    },
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(Icons.more_vert),
                ),
              )
            ],
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
          body: [OverviewPage(), const MapPage()][page],
          bottomNavigationBar: BottomNavigationBar(
            showUnselectedLabels: false,
            selectedIconTheme: const IconThemeData(size: 28.0),
            currentIndex: page,
            onTap: (value) {
              setState(() {
                page = value;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Overview'),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
            ],
          ),
        ),
      ),
    );
  }

  void goLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }
}
