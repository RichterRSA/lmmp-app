import 'package:cloud_firestore/cloud_firestore.dart';

class FSDB {
  static Future<UserInformation> getUserInfo(String uid) async {
    var db = FirebaseFirestore.instance;

    var data = await db.doc('users/$uid').get();

    if (data.exists) {
      String name = data['name'];
      String surname = data['surname'];
      String picture = data['picture'];

      return UserInformation(uid: uid, name: name, surname: surname, picture: picture);
    } else {
      return UserInformation(uid: uid, name: 'Unknown', surname: '', picture: '');
    }
  }

  static void setUserInfo(UserInformation dat) async {
    var db = FirebaseFirestore.instance;

    Map<String, dynamic> data = {
      'name': dat.name,
      'surname': dat.surname,
      'picture': dat.picture,
    };

    await db.doc('users').set(data);
  }
}

class UserInformation {
  final String uid, name, surname, picture;

  UserInformation({required this.uid, required this.name, required this.surname, required this.picture});
}
