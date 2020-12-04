import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps for Dartup',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Set<Marker> _markers = {};
  Set<Polygon> _poly = {};
  final Geolocator _geolocator = Geolocator()..forceAndroidLocationManager;
  Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    super.initState();
    setState(() {
      loadMarkers();
      loadPoly();
    });
    _getCurrent();
  }

  static final CameraPosition _moscow = CameraPosition(
    target: LatLng(55.7517769362014, 37.61637210845947),
    zoom: 14.4746,
  );
  static final CameraPosition _home = CameraPosition(
    target: LatLng(55.69839803841039, 37.76223599910736),
    zoom: 14.4746,
  );

  static final CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(55.69277766693856, 37.781639099121094),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  Future loadMarkers() async {
    var jsonData = await rootBundle.loadString('assets/points.json');
    var data = json.decode(jsonData);
    final treeIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(32, 32)), 'assets/icons/tree.png');

    data["coords"].forEach((item) {
      _markers.add(new Marker(
          markerId: MarkerId(item["ID"]),
          position: LatLng(
              double.parse(item["latitude"]), double.parse(item["longitude"])),
          infoWindow: InfoWindow(
            title: item["comment"],
          ),
          //icon: BitmapDescriptor.defaultMarkerWithHue(
          //   BitmapDescriptor.hueGreen)));
          icon: treeIcon));
    });
  }

  Future loadPoly() async {
    List<LatLng> polygonCoords = [];
    var jsonData = await rootBundle.loadString('assets/poly.json');
    var data = json.decode(jsonData);

    data["coords"].forEach((item) {
      polygonCoords.add(new LatLng(
          double.parse(item["latitude"]), double.parse(item["longitude"])));
    });

    _poly.add(new Polygon(
      polygonId: PolygonId(data["ID"]),
      points: polygonCoords,
      strokeColor: Colors.green,
      fillColor: Colors.green.withOpacity(0.5),
      strokeWidth: 2,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: GoogleMap(
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.hybrid,
          markers: Set.from(_markers),
          polygons: Set.from(_poly),
          initialCameraPosition: _moscow,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          onTap: _handleTap,
        ),
        floatingActionButton: Row(
          children: [
            Padding(
                padding: const EdgeInsets.only(left: 20, right: 10),
                child: FloatingActionButton.extended(
                  onPressed: _goToTheLake,
                  label: Text('To the lake!'),
                  icon: Icon(Icons.double_arrow_rounded),
                  backgroundColor: Colors.green,
                )),
            Padding(
                padding: const EdgeInsets.only(left: 10, right: 20),
                child: FloatingActionButton.extended(
                  onPressed: _goHome,
                  label: Text('Return home'),
                  backgroundColor: Colors.green,
                ))
          ],
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
        ));
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  Future<void> _goHome() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_home));
  }

  Future<void> _handleTap(LatLng point) async {
    final treeIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(32, 32)), 'assets/icons/tree.png');
    debugPrint(point.toString());
    setState(() {
      _markers.add(new Marker(
          markerId: MarkerId((_markers.length + 1).toString()),
          position: LatLng(point.latitude, point.longitude),
          infoWindow: InfoWindow(
            title: "new tree, planted by me",
          ),
          icon: treeIcon));
    });
  }

  Future<void> _getCurrent() async {
    _geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) async {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 14.4746,
      )));
    }).catchError((e) {
      print(e);
    });
  }
}
