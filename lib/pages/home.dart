import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_map_flutter/credentials.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.title});
  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? address, dateTime;
  LatLng destination = LatLng(6.647027, 3.374165);
  late GoogleMapController controllerMap;
  List<LatLng> polyLineCoordinates = [];
  Map<String, Marker> pointer = {};
  LocationData? currentLocation;
  Location location = Location();

  @override
  void didChangeDependencies() {
    getTwoPoints();
    getCurrentLocation();
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBody: true,
        body: currentLocation == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Unable to fetch location !",
                      style: TextStyle(fontSize: 18),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          didChangeDependencies();
                        },
                        child: Text('Refresh')),
                  ],
                ),
              )
            : Stack(
                children: [
                  GoogleMap(
                    compassEnabled: true,
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 8, 0),
                    initialCameraPosition: CameraPosition(
                      target: LatLng(currentLocation!.latitude!,
                          currentLocation!.longitude!),
                      zoom: 14.5,
                    ),
                    myLocationEnabled: true,
                    polylines: {
                      Polyline(
                          polylineId: PolylineId('routes'),
                          points: polyLineCoordinates,
                          color: Colors.blue,
                          width: 5)
                    },
                    onMapCreated: (controller) {
                      controllerMap = controller;
                      addPointer(
                          'current',
                          LatLng(currentLocation!.latitude!,
                              currentLocation!.longitude!));
                      addPointer('2id', destination);
                    },
                    markers: pointer.values.toSet(),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: EdgeInsets.only(left: 15, top: 10),
                      margin: EdgeInsets.fromLTRB(30, 0, 30, 100),
                      height: 70,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.withOpacity(0.6)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (currentLocation != null)
                            Text(
                              "Latitude: ${currentLocation!.latitude}, Longitude: ${currentLocation!.longitude}",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
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

  /// Function to handle pointer
  void addPointer(String id, LatLng location) {
    var point = Marker(
        markerId: MarkerId(id),
        position: location,
        infoWindow: InfoWindow(
            title: "Title of the Location",
            snippet: "Description of the location"));
    pointer[id] = point;
    setState(() {});
  }

  /// Function to handle coordinates
  void getTwoPoints() async {
    try {
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        google_map_key,
        PointLatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        PointLatLng(destination.latitude, destination.longitude),
      );
      if (result.points.isNotEmpty) {
        result.points.forEach((PointLatLng e) {
          polyLineCoordinates.add(LatLng(e.latitude, e.longitude));
        });
        setState(() {});
      }
    } catch (e) {}
  }

  /// Get current Location
  void getCurrentLocation() async {
    final hasPermission = await handleLocationPermission();
    try {
      if (!hasPermission) return;
      LocationData result =
          await location.getLocation().then((value) => currentLocation = value);
    } catch (e) {}
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    PermissionStatus permission;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Location.instance.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await Location.instance.requestPermission();
      if (permission == PermissionStatus.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == PermissionStatus.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }
}
