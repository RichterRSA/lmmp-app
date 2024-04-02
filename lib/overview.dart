import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lmm/main.dart';
import 'package:lmm/rtdb.dart';
import 'package:lmm/widgets.dart';

class OverviewPage extends StatefulWidget {
  static late OverviewPage instance;
  ValueNotifier<List<Slot>> slots = ValueNotifier(List.empty(growable: true));

  OverviewPage({super.key}) {
    instance = this;
  }

  void removeSlot(Slot slot) {
    RTDB.removeBooking(slot);
    if (slots.value.contains(slot)) {
      slots.value.remove(slot);
      var old = slots.value;
      slots.value = List.empty();
      slots.value = old;
    }
  }

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  ValueNotifier<int> selectedDate = ValueNotifier<int>(-1), selectedTime = ValueNotifier<int>(-1);
  ValueNotifier<bool> canBook = ValueNotifier(false);
  int slot = 0;

  StreamSubscription<DatabaseEvent>? liveAdded, liveRemoved;

  @override
  void initState() {
    getSlots();
    getLive();
    Timer.periodic(const Duration(seconds: 5), (Timer t) {
      if (Slot.getCurrentSlot() != slot) {
        slot = Slot.getCurrentSlot();
        if (mounted) {
          setState(() {});
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await getSlots();
      },
      child: ValueListenableBuilder(
        valueListenable: LMMPApp.liveUsers,
        builder: (context, value, child) => ListView(
          children: [
            Card(
              margin: const EdgeInsets.all(20.0),
              elevation: 2.0,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                          child: Text(
                            'On patrol',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.quicksand(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          Slot.getTimeText(Slot.getCurrentSlot()),
                          textAlign: TextAlign.start,
                          style: GoogleFonts.quicksand(fontSize: 20.0, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        showLive();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Slots:',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.quicksand(
                              fontSize: 20.0,
                            ),
                          ),
                          Text(
                            '${value.length}/3',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.quicksand(
                              fontSize: 20.0,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    ElevatedButton(
                      style: const ButtonStyle(
                        surfaceTintColor: MaterialStatePropertyAll(Colors.white),
                      ),
                      onPressed: () {},
                      child: Text(
                        'Report activity',
                        style: GoogleFonts.quicksand(
                          fontSize: 20.0,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: const ButtonStyle(
                        surfaceTintColor: MaterialStatePropertyAll(Colors.white),
                      ),
                      onPressed: () {
                        (LMMPApp.isLive()) ? leaveCurrent() : joinCurrent();
                      },
                      child: Text(
                        (LMMPApp.isLive()) ? 'Leave' : 'Join',
                        style: (LMMPApp.isLive())
                            ? GoogleFonts.quicksand(
                                fontSize: 20.0,
                                color: Colors.red,
                              )
                            : GoogleFonts.quicksand(
                                fontSize: 20.0,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 2.0,
              margin: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                      child: Text(
                        'My slots',
                        textAlign: TextAlign.start,
                        style: GoogleFonts.quicksand(
                          fontSize: 24.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: widget.slots,
                      builder: (context, value, child) => Column(
                        children: (widget.slots.value.isNotEmpty)
                            ? [for (Slot s in value) SlotWidget(slot: s)]
                            : [
                                Text(
                                  'No slots booked yet!',
                                  textAlign: TextAlign.start,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 20.0,
                                  ),
                                ),
                              ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    ElevatedButton(
                      style: const ButtonStyle(
                        surfaceTintColor: MaterialStatePropertyAll(Colors.white),
                      ),
                      onPressed: () {
                        setState(() {
                          selectedDate.value = -1;
                          selectedTime.value = -1;
                        });
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return bookDialog();
                          },
                        );
                      },
                      child: Text(
                        'Book',
                        style: GoogleFonts.quicksand(
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Dialog bookDialog() {
    return Dialog(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'Book',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      fontSize: 20.0,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          List<String> dates = List.empty(
                            growable: true,
                          );

                          DateTime now = DateTime.now();
                          DateTime today = DateTime(now.year, now.month, now.day);

                          for (int i = 0; i <= 7; i++) {
                            dates.add(Slot.getDateText(today.add(Duration(days: i))));
                          }

                          return Dialog(
                            elevation: 1.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      'Select Date',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 24.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SizedBox(
                                      height: 240.0,
                                      child: ListView(
                                        children: [
                                          for (String date in dates)
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  selectedDate.value = dates.indexOf(date);
                                                  selectedTime.value = -1;
                                                });

                                                checkCanBook();

                                                Navigator.pop(context);
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text(
                                                  date,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.quicksand(
                                                    fontSize: 20.0,
                                                  ),
                                                ),
                                              ),
                                            )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: ValueListenableBuilder(
                      valueListenable: selectedDate,
                      builder: (context, value, child) => Text(
                        (selectedDate.value == -1)
                            ? 'Select'
                            : Slot.getDateText(DateTime.now().add(Duration(days: value))),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Time',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      fontSize: 20.0,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          List<String> times = List.empty(
                            growable: true,
                          );

                          for (int i = (selectedDate.value == 0) ? Slot.getCurrentSlot() + 1 : 0; i < 12; i++) {
                            times.add(Slot.getTimeText(i));
                          }

                          return Dialog(
                            elevation: 1.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      'Select Time',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 24.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SizedBox(
                                      height: 240.0,
                                      child: ListView(
                                        children: [
                                          for (String time in times)
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  selectedTime.value = times.indexOf(time);
                                                });

                                                checkCanBook();

                                                Navigator.pop(context);
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text(
                                                  time,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.quicksand(
                                                    fontSize: 20.0,
                                                  ),
                                                ),
                                              ),
                                            )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: ValueListenableBuilder(
                      valueListenable: selectedTime,
                      builder: (context, value, child) => Text(
                        (selectedTime.value == -1) ? 'Select' : Slot.getTimeText(value),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            ValueListenableBuilder(
              valueListenable: canBook,
              builder: (context, value, child) => ElevatedButton(
                onPressed: (value && selectedDate.value > -1 && selectedTime.value > -1)
                    ? () {
                        book();
                        Navigator.pop(context);
                      }
                    : null,
                child: Text(
                  'Book',
                  style: GoogleFonts.quicksand(
                    fontSize: 20.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getSlots() async {
    widget.slots.value.clear();
    for (Slot s in await RTDB.getMyBookings()) {
      widget.slots.value.add(s);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void book() {
    Slot s = Slot(DateTime.now().add(Duration(days: selectedDate.value)), selectedTime.value);
    setState(() {
      widget.slots.value.add(s);
    });
    RTDB.addBooking(s);
  }

  void checkCanBook() {
    setState(() {
      canBook.value = selectedDate.value > -1 && selectedTime.value > -1;
    });
  }

  void joinCurrent() {
    RTDB.joinCurrent();
    LMMPApp.startLocationTracking();
  }

  void leaveCurrent() {
    RTDB.leaveCurrent();
    LMMPApp.stopLocationTracking();
  }

  void getLive() async {
    print('getLive');
    // liveAdded = LMMPApp.onLiveUserAdded?.listen((event) async {
    //   print('noice');
    //   if (mounted) {
    //     setState(() {});
    //   }
    // }, onError: (e) => print('oh no! $e'));
    // liveRemoved = LMMPApp.onLiveUserRemoved?.listen((event) async {
    //   print('cool');
    //   if (mounted) {
    //     setState(() {});
    //   }
    // });

    if (LMMPApp.isLive() && !LMMPApp.isLocationTracking()) {
      joinCurrent();
    }
  }

  void showLive() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'On patrol',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 250.0,
                child: ValueListenableBuilder(
                  valueListenable: LMMPApp.liveUsers,
                  builder: (context, value, child) => ListView(
                    children: [for (LiveUser s in value) UserWidget(s.fullName)],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
