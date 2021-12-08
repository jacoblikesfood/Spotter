import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParkingLot {
  final LatLng latLng;
  final bool isFull;

  const ParkingLot({required this.latLng,required this.isFull});



  factory ParkingLot.fromMap(Map<String, dynamic> json){
    final dest = LatLng(36.062070, -94.184470);

    return ParkingLot(
      latLng: dest,
      isFull: false,
    );
  }
}