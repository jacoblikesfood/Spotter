import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotter/models/directions_model.dart';
import 'package:spotter/repositories/directions_repository.dart';
import 'package:spotter/models/parking_model.dart';
import 'package:spotter/repositories/parking_repository.dart';
import 'package:http/http.dart' as http;

class MapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: mapView(),
    );
  }
}

class mapView extends StatefulWidget {
  @override
  _mapViewState createState() => _mapViewState();
}

class _mapViewState extends State<mapView> {

  ///temp map starting point
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(36.082157, -94.171852),
    zoom: 11.5
  );

  bool showDistance = false;
  final invalidLatLng = LatLng(0.0, 0.0);

  late GoogleMapController _googleMapController;

  Directions? _info /*= Directions(
    bounds: LatLngBounds(
      southwest: LatLng(0.0, 0.0),
      northeast: LatLng(0.0, 0.0),
    ),
    polylinePoints: List.empty(),
    totalDistance: 'hi',
    totalDuration: 'hello',
  )*/;

  Marker _origin = Marker(
    markerId: const MarkerId('origin'),
    infoWindow: const InfoWindow(title: 'Origin'),
    icon:
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    position: LatLng(0.0, 0.0),
  );
  Marker _destination = Marker(
      markerId: const MarkerId('destination'),
      infoWindow: const InfoWindow(title: 'Destination'),
      icon:
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      position: LatLng(0.0, 0.0),
  );


  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }


  ///functions
  void _onMapCreated(GoogleMapController controller) {
    _googleMapController = controller;
  }

  void _addMarker(LatLng pos) async {
    if (_origin.position == invalidLatLng || (_origin.position != invalidLatLng && _destination.position != invalidLatLng)) {
      setState(() {
        _origin = Marker(
          markerId: const MarkerId('origin'),
          infoWindow: const InfoWindow(title: 'Origin'),
          icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          position: pos,
        );
        _destination = Marker(
          markerId: const MarkerId('destination'),
          infoWindow: const InfoWindow(title: 'Destination'),
          icon:
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          position: invalidLatLng,
        );

        showDistance = false;

        ///reset info
        _info = null as Directions;
      });
    } else {
      setState(() {
        _destination = Marker(
          markerId: const MarkerId('destination'),
          infoWindow: const InfoWindow(title: 'Destination'),
          icon:
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          position: pos,
        );
        showDistance = true;
      });

      ///get directions
      final directions = await DirectionsRepository()
          .getDirections(origin: _origin.position, destination: pos);
      setState(() => _info = directions);
    }
  }


  ///parking lot api call
  void _findLot(LatLng pos) async {
    setState(() {
      _origin = Marker(
        markerId: const MarkerId('origin'),
        infoWindow: const InfoWindow(title: 'Origin'),
        icon:
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        position: pos,
      );
    });

    final parkingLot = await ParkingRepository()
        .getParkingLot(location: pos);

    final directions = await DirectionsRepository()
        .getDirections(origin: pos, destination: parkingLot.latLng);

    setState(() => _info = directions);
  }


  ///build
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Spotter'),
        actions: [
          if (_origin.position != invalidLatLng)
            TextButton(
              onPressed: () => _googleMapController.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _origin.position,
                    zoom: 14.5,
                    tilt: 50.0,
                  ),
                ),
              ),
              style: TextButton.styleFrom(
                primary: Colors.green,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('ORIGIN'),
            ),
          if (_destination.position != invalidLatLng)
            TextButton(
              onPressed: () => _googleMapController.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _destination.position,
                    zoom: 14.5,
                    tilt: 50.0,
                  ),
                ),
              ),
              style: TextButton.styleFrom(
                primary: Colors.blue,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('DEST'),
            ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
            GoogleMap(
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: _onMapCreated,
            markers: {
              if (_origin.position != invalidLatLng) _origin,
              if (_destination.position != invalidLatLng) _destination
            },
            polylines: {
              if (_info != null)
                Polyline(
                  polylineId: const PolylineId('overview_polyline'),
                  color: Colors.red,
                  width: 5,
                  points: _info!.polylinePoints
                    .map((e) => LatLng(e.latitude, e.longitude))
                    .toList(),
                ),
            },
            onLongPress: _findLot,
          ),
          if (_info != null)
            Positioned(
              top: 20.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: const[
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 6.0,
                    )
                  ],
                ),
                child: Text(
                  '${_info!.totalDistance}, ${_info!.totalDuration}',   ///    ${_info.totalDistance}, ${_info.totalDuration}
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.black,
          onPressed: () => _googleMapController.animateCamera(
            _info != null
                ? CameraUpdate.newLatLngBounds(_info!.bounds, 100.0)
                : CameraUpdate.newCameraPosition(_initialCameraPosition),
          ),
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }
}