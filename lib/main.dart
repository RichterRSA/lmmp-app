import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lmm/authentication.dart';
import 'package:lmm/rtdb.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  runApp(LMMPApp());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseAuth.instance.userChanges().listen((User? user) {
    if (user == null) {
      LMMPApp.loggedIn.value = false;
    } else {
      LMMPApp.loggedIn.value = true;
    }
  });

  FirebaseDatabase.instance.databaseURL = 'https://lmmp-app-default-rtdb.europe-west1.firebasedatabase.app';
}

class LMMPApp extends StatefulWidget {
  static late LMMPApp _instance;
  LMMPApp({super.key}) {
    _instance = this;
  }

  static final ValueNotifier<bool> loggedIn = ValueNotifier<bool>(false);
  static Stream<DatabaseEvent>? onLiveUserAdded;
  static Stream<DatabaseEvent>? onLiveUserRemoved;
  StreamSubscription<Position>? _positionStream;
  bool _isLive = false;
  bool _locationTrackingStarted = false;
  static ValueNotifier<List<LiveUser>> liveUsers = ValueNotifier(List.empty(growable: true));

  static Future<void> init() async {
    final usersRef = await RTDB.currentChangedRef();

    onLiveUserAdded = usersRef.onChildAdded;
    onLiveUserRemoved = usersRef.onChildRemoved;

    onLiveUserAdded?.listen((event) async {
      print('user added!');
      liveUsers.value.clear();
      liveUsers.value = await RTDB.currentUsers();
      _instance._isLive =
          liveUsers.value.where((element) => element.uid == FirebaseAuth.instance.currentUser!.uid).isNotEmpty;
    });
    onLiveUserRemoved?.listen((event) async {
      print('user removed!');
      liveUsers.value.clear();
      liveUsers.value = await RTDB.currentUsers();
      _instance._isLive =
          liveUsers.value.where((element) => element.uid == FirebaseAuth.instance.currentUser!.uid).isNotEmpty;
    });
  }

  static void updateLiveUsers() async {
    liveUsers.value = await RTDB.currentUsers();
  }

  static bool isLive() {
    return _instance._isLive;
  }

  static void startLocationTracking() async {
    if (_instance._locationTrackingStarted) {
      return;
    } else {
      _instance._locationTrackingStarted = true;
    }
    print('start tracking');

    LocationPermission permission;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied, we cannot request permissions.');
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _instance._positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position? position) {
      print(position == null ? 'Unknown' : '${position.latitude.toString()}, ${position.longitude.toString()}');
      if (position != null) {
        RTDB.updateLocation(position.latitude, position.longitude);
      }
    });
  }

  static void stopLocationTracking() async {
    _instance._locationTrackingStarted = false;
    await _instance._positionStream?.cancel();
  }

  static bool isLocationTracking() {
    return _instance._locationTrackingStarted;
  }

  @override
  State<LMMPApp> createState() => _LMMPAppState();
}

class _LMMPAppState extends State<LMMPApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LMM Patrols',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LiveUser {
  final BitmapDescriptor icon;
  final String fullName, uid;
  final LatLng location;

  LiveUser({required this.icon, required this.fullName, required this.uid, required this.location});
}
