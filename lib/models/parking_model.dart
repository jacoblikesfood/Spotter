import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParkingLot {
  final LatLng latLng;
  final bool isFull;

  const ParkingLot({required this.latLng,required this.isFull});



  factory ParkingLot.fromMap(List<dynamic> json){
    final lat = json[0]['lat'];
    final lng = json[0]['lon'];
    final dest = LatLng(lat, lng);

    return ParkingLot(
      latLng: dest,
      isFull: false,
    );
  }
}