import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotter/models/directions_model.dart';
import 'package:spotter/repositories/directions_repository.dart';
import 'package:spotter/models/parking_model.dart';
import 'package:spotter/repositories/parking_repository.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
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

  int lotIterator = 0;
  bool isLoading = false;
  String parkingTypeChoice = 'All';
  late GoogleMapController _googleMapController;

  Directions? _info;

  Position? currentPosition;

  ParkingLotList? parkingLotList;

  Marker? _origin;
  Marker? _destination;

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;


  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }


  ///functions
  void _onMapCreated(GoogleMapController controller) {
    _googleMapController = controller;
  }


  ///gets user location, drops marker, and finds route to closest lot
  _getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        currentPosition = position;
      });
      _findLot(LatLng(position.latitude, position.longitude));
    }).catchError((e) {
      print(e);
    });
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
      _destination = null;
      _info = null;
      isLoading = true;
    });

    //dynamic parkingLotList;

    if(parkingTypeChoice == 'All'){
      parkingLotList = await ParkingRepository()
          .getParkingLot(location: pos);
    } else if (parkingTypeChoice == 'Free'){
      parkingLotList = await ParkingRepository()
          .getParkingLotWithType(location: pos, type: 1);
    } else if (parkingTypeChoice == 'Metered'){
      parkingLotList = await ParkingRepository()
          .getParkingLotWithType(location: pos, type: 2);
    } else if (parkingTypeChoice == 'Paid'){
      parkingLotList = await ParkingRepository()
          .getParkingLotWithType(location: pos, type: 3);
    } else if (parkingTypeChoice == 'Street'){
      parkingLotList = await ParkingRepository()
          .getParkingLotWithType(location: pos, type: 4);
    }

    final directions = await DirectionsRepository()
        .getDirections(origin: pos, destination: parkingLotList!.parkingLotList[lotIterator].latLng);

    setState(() {
      _destination = Marker(
        markerId: const MarkerId('destination'),
        infoWindow: const InfoWindow(title: 'Destination'),
        icon:
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        position: parkingLotList!.parkingLotList[lotIterator].latLng,
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

  void reportFull() async {
   ParkingRepository().postParkingLotFull(id: lotIterator);
   if (lotIterator < parkingLotList!.count) {
     setState(() {
       isLoading = true;
     });
     lotIterator++;
     final directions = await DirectionsRepository()
         .getDirections(origin: _origin!.position,
         destination: parkingLotList!.parkingLotList[lotIterator].latLng);

     setState(() {
       _destination = Marker(
         markerId: const MarkerId('destination'),
         infoWindow: const InfoWindow(title: 'Destination'),
         icon:
         BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
         position: parkingLotList!.parkingLotList[lotIterator].latLng,
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
  }

  void nextLot() async {

    print(DateFormat('EEE, dd MMM yyy hh:mm:ss').parse('Tue, 30 Nov 2021 12:30:00 GMT'));

    if (lotIterator < parkingLotList!.count) {
      setState(() {
        isLoading = true;
      });
      lotIterator++;
      final directions = await DirectionsRepository()
          .getDirections(origin: _origin!.position,
          destination: parkingLotList!.parkingLotList[lotIterator].latLng);

      setState(() {
        _destination = Marker(
          markerId: const MarkerId('destination'),
          infoWindow: const InfoWindow(title: 'Destination'),
          icon:
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          position: parkingLotList!.parkingLotList[lotIterator].latLng,
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
  }

  ///build
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Spotter'),
        actions: [
          TextButton(
            onPressed: _getCurrentLocation,
            style: TextButton.styleFrom(
              primary: Colors.green,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('NEAR ME'),
          ),
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
          if (_destination != null)
            TextButton(
              onPressed: reportFull,
              style: TextButton.styleFrom(
                primary: Colors.red,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('FULL'),
            ),
          if (_destination != null)
            TextButton(
              onPressed: nextLot,
              style: TextButton.styleFrom(
                primary: Colors.blue,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text('NEXT'),
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
          if (_info != null && !isLoading)
            Positioned(
              top: 60.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent.withOpacity(0.75),
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

          if (_info != null && !isLoading)
            Positioned(
              top: 5.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent.withOpacity(0.75),
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
                  'Destination: ${parkingLotList!.parkingLotList[lotIterator].name}\nReported full: ' + '${DateFormat('MM/dd/yyyy HH:mm').format(DateFormat('MM/dd/yyyy HH:mm').parse(DateFormat('MM/dd/yyyy HH:mm').format(DateFormat('EEE, dd MMM yyy hh:mm:ss').parse(parkingLotList!.parkingLotList[lotIterator].reportedFull))).subtract(Duration(hours: 6)))}',
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
                child: const Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
         // if (_info == null && !isLoading)
          //ElevatedButton(onPressed: _getCurrentLocation, child: Text('Find Parking'))

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