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

  final invalidLatLng = LatLng(0.0, 0.0);
  bool isLoading = false;
  String parkingTypeChoice = 'All';
  late GoogleMapController _googleMapController;

  Directions? _info;

  Marker? _origin;
  Marker? _destination;


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
    if (_origin == null || (_origin != null && _destination != null)) {
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
      });

      ///get directions
      final directions = await DirectionsRepository()
          .getDirections(origin: _origin!.position, destination: pos);
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
      _info = null;
      isLoading = true;
    });

    final parkingLot = await ParkingRepository()
        .getParkingLot(location: pos);

    final directions = await DirectionsRepository()
        .getDirections(origin: pos, destination: parkingLot.latLng);

    setState(() {
      _destination = Marker(
        markerId: const MarkerId('destination'),
        infoWindow: const InfoWindow(title: 'Destination'),
        icon:
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        position: parkingLot.latLng,
      );
      _info = directions;
      isLoading = false;
      _googleMapController.animateCamera(
        _info != null
            ? CameraUpdate.newLatLngBounds(_info!.bounds, 100.0)
            : CameraUpdate.newCameraPosition(_initialCameraPosition),
      );
    });
  }


  ///build
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Spotter'),
        actions: [
          DropdownButton<String>(
            value: parkingTypeChoice,
            icon: const Icon(Icons.arrow_downward),
            iconSize: 24,
            elevation: 16,
            style: const TextStyle(color: Colors.black),
            underline: Container(
              height: 2,
              color: Colors.black12,
            ),
            onChanged: (String? newValue) {
              setState(() {
                parkingTypeChoice = newValue!;
              });
            },
            items: <String>['All', 'Free', 'Metered', 'Paid', 'Street']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          if (_origin != null)
            TextButton(
              onPressed: () => _googleMapController.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _origin!.position,
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
          if (_destination != null)
            TextButton(
              onPressed: () => _googleMapController.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: _destination!.position,
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
            zoomControlsEnabled: true,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: _onMapCreated,
            markers: {
              if (_origin != null) _origin!,
              if (_destination != null) _destination!
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
                  '${_info!.totalDistance}, ${_info!.totalDuration}',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (isLoading)
            Positioned(
              top: 20.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
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
                  'Loading...',
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}