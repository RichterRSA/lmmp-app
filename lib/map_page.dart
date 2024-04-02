import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lmm/main.dart';
import 'package:string_to_color/string_to_color.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  Set<Marker> markers = {};
  late Timer _locationUpdateTimer;

  @override
  void initState() {
    trackLiveUsers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(-25.749456164059843, 28.317630545680338),
          zoom: 15.0,
        ),
        buildingsEnabled: false,
        onLongPress: (argument) => drawHoldMarker(argument),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: markers,
      ),
    );
  }

  Future<void> drawHoldMarker(LatLng point) async {
    String markerIdValue = 'tap_marker';
    MarkerId markerId = MarkerId(markerIdValue);

    markers.add(Marker(
      markerId: markerId,
      position: point,
      icon: await BitmapDescriptor.fromAssetImage(ImageConfiguration.empty, 'assets/images/pin.png'),
      anchor: const Offset(0.5, 1.0),
      visible: true,
    ));

    if (mounted) {
      setState(() {});
    }

    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: point,
      zoom: await controller.getZoomLevel(),
    )));
  }

  void trackLiveUsers() {
    print('track!');
    LMMPApp.updateLiveUsers();
    updateMarkers();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      print('calling update!');
      LMMPApp.updateLiveUsers();
      updateMarkers();
    });
  }

  void updateMarkers() async {
    print('updating markers: ${LMMPApp.liveUsers.value.length} users');

    if (markers.isNotEmpty) {
      markers.removeWhere((element) => element.markerId.value.startsWith('uid-'));
    }
    for (LiveUser user in LMMPApp.liveUsers.value) {
      BitmapDescriptor icon = await getUserImage(user.fullName);

      markers.add(Marker(
        markerId: MarkerId('uid-${user.uid}'),
        icon: icon,
        position: user.location,
      ));
    }
    setState(() {});
  }

  @override
  void dispose() {
    LMMPApp.liveUsers.removeListener(() {
      updateMarkers();
    });
    _locationUpdateTimer.cancel();
    super.dispose();
  }
}

Marker createLocationMarker(String uid, BitmapDescriptor icon, LatLng point) {
  Marker result = Marker(
    markerId: MarkerId('location-$uid'),
    anchor: const Offset(0.5, 0.5),
    visible: true,
    icon: icon,
    position: point,
  );

  return result;
}

Future<BitmapDescriptor> getUserImage(String name) async {
  return await CircleAvatar(
    foregroundColor: Colors.white,
    backgroundColor: ColorUtils.stringToColor(name),
    child: Text(name.toUpperCase()[0]),
  ).toBitmapDescriptor();
}
