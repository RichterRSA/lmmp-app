import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lmm/fsdb.dart';
import 'overview.dart';

class Slot {
  late DateTime date;
  late int time;

  Slot(DateTime dat, int tim) {
    date = DateTime(dat.year, dat.month, dat.day);
    time = tim;
  }

  static String getDateText(DateTime date) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);

    String result = '';

    date = DateTime(date.year, date.month, date.day);

    if (date == today) {
      result += 'Today';
    } else if (date == tomorrow) {
      result += 'Tomorrow';
    } else {
      return DateFormat('EEEE, d MMM').format(date);
    }

    result += DateFormat(', d MMM').format(date);

    return result;
  }

  static String getTimeText(int slot) {
    int start = slot * 2 + 1;
    int end = (slot + 1) * 2 + 1;

    DateTime startTime = DateTime(0, 0, 0, start);
    DateTime endTime = DateTime(0, 0, 0, end);

    return '${DateFormat('HH:00').format(startTime)}-${DateFormat('HH:00').format(endTime)}';
  }

  static int getCurrentSlot() {
    int now = DateTime.now().hour;
    return ((now - 1) / 2).floor();
  }
}

class SlotWidget extends StatelessWidget {
  final Slot slot;
  const SlotWidget({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      OverviewPage.instance.removeSlot(slot);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Remove',
                      style: GoogleFonts.quicksand(
                        fontSize: 20.0,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            Slot.getDateText(slot.date),
            textAlign: TextAlign.start,
            style: GoogleFonts.quicksand(
              fontSize: 20.0,
            ),
          ),
          Text(
            Slot.getTimeText(slot.time),
            textAlign: TextAlign.start,
            style: GoogleFonts.quicksand(
              fontSize: 20.0,
            ),
          ),
        ],
      ),
    );
  }
}

class UserWidget extends StatelessWidget {
  late final String uid;
  UserWidget(String id, {super.key}) {
    uid = id;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FSDB.getUserInfo(uid),
      initialData: UserInformation(uid: uid, name: 'Loading', surname: '', picture: ''),
      builder: (context, snapshot) => Container(
        padding: const EdgeInsets.all(10.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.0),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.grey,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        snapshot.hasData ? '${snapshot.data?.name} ${snapshot.data?.surname}' : 'Loading',
                        style: GoogleFonts.quicksand(
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.message),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
