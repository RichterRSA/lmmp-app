import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lmm/fsdb.dart';
import 'package:lmm/main.dart';
import 'package:lmm/widgets.dart';

class RTDB {
  static void addBooking(Slot slot) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String date = DateFormat('yyyy-MM-dd').format(slot.date);

    DatabaseReference bookingsRef = FirebaseDatabase.instance.ref('bookings/$date');

    DatabaseReference bookingsList = bookingsRef.push();

    await bookingsList.set({
      "uid": uid,
      "time": slot.time,
    });

    DatabaseReference userRef = FirebaseDatabase.instance.ref('users/$uid');

    DatabaseReference userList = userRef.push();

    await userList.set({
      "date": date,
      "time": slot.time,
    });
  }

  static void removeBooking(Slot slot) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String date = DateFormat('yyyy-MM-dd').format(slot.date);

    DatabaseReference bookingsRef = FirebaseDatabase.instance.ref('bookings/$date');

    DataSnapshot snapshot = (await bookingsRef.orderByChild("uid").equalTo(uid).once()).snapshot;

    for (var child in snapshot.children) {
      Map<dynamic, dynamic> data = child.value as Map<dynamic, dynamic>;
      if (data["time"] == slot.time) {
        child.ref.remove();
      }
    }

    DatabaseReference usersRef = FirebaseDatabase.instance.ref('users/$uid');

    DataSnapshot usersSnapshot = (await usersRef.once()).snapshot;
    for (var child in usersSnapshot.children) {
      Map<dynamic, dynamic> data = child.value as Map<dynamic, dynamic>;
      if (data["date"] == date && data["time"] == slot.time) {
        child.ref.remove();
        break; // Assuming there's only one booking per user per day and time
      }
    }
  }

  static Future<List<Slot>> getMyBookings() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child('users/$uid').get();

    List<Slot> result = List.empty(growable: true);

    if (snapshot.exists) {
      final Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
      for (dynamic val in values.values) {
        Map<dynamic, dynamic> item = val as Map<dynamic, dynamic>;
        String dateString = item['date'].toString();
        int time = item['time'];

        DateTime date = DateTime.parse(dateString);

        result.add(Slot(date, time));
      }
    }

    return result;
  }

  static void joinCurrent() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String date = DateFormat('yyyy-MM-dd mm:ss').format(DateTime.now());

    DatabaseReference liveRef = FirebaseDatabase.instance.ref('live-users');

    if ((await liveRef.orderByChild('uid').equalTo(uid).once()).snapshot.children.isNotEmpty) {
      print('already in list!');
      return;
    }

    DatabaseReference liveList = liveRef.push();

    await liveList.set({
      "uid": uid,
      "time": date,
    });
  }

  static void updateLocation(double lat, double long) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    DataSnapshot snapshot =
        (await FirebaseDatabase.instance.ref('live-users').orderByChild('uid').equalTo(uid).once()).snapshot;

    if (snapshot.value == null) {
      print('could not find user!');
      return;
    }

    Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

    String key = data.keys.first as String;

    DatabaseReference liveRef = FirebaseDatabase.instance.ref('live-users/$key/location');

    await liveRef.set({
      "lat": lat,
      "lon": long,
    });
  }

  static void leaveCurrent() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    DatabaseReference bookingsRef = FirebaseDatabase.instance.ref('live-users');

    DataSnapshot snapshot = (await bookingsRef.orderByChild("uid").equalTo(uid).once()).snapshot;

    for (var child in snapshot.children) {
      child.ref.remove();
    }
  }

  static Future<DatabaseReference> currentChangedRef() async {
    return FirebaseDatabase.instance.ref("live-users");
  }

  static Future<List<LiveUser>> currentUsers() async {
    final usersRef = FirebaseDatabase.instance.ref("live-users");

    List<LiveUser> users = List.empty(growable: true);

    final snapshot = await usersRef.get();

    if (snapshot.exists) {
      final Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
      for (dynamic val in values.values) {
        if (val != null) {
          UserInformation info = await FSDB.getUserInfo(val['uid']);

          double lat = 0.0;
          double lon = 0.0;
          if (val['location'] != null) {
            var loc = val['location'] as Map<dynamic, dynamic>;
            lat = loc['lat'] ?? 0.0;
            lon = loc['lon'] ?? 0.0;
          }

          users.add(LiveUser(
            icon: BitmapDescriptor.defaultMarker, //TODO
            fullName: '${info.name} ${info.surname}',
            uid: val['uid'],
            location: LatLng(lat, lon),
          ));
        }
      }
    }

    return users;
  }
}
