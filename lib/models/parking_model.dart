import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParkingLot {
  final String name;
  final String reportedFull;
  final int id;
  final int type;
  final LatLng latLng;

  const ParkingLot({required this.name, required this.reportedFull, required this.id, required this.type, required this.latLng});



  factory ParkingLot.fromMap(Map<String, dynamic> json){
    final String name = json['location_name'];
    final String full = json['date_reported'];
    final id = json['id'];
    final lat = json['lat'];
    final lng = json['lon'];
    final dest = LatLng(lat, lng);
    final type = json['type'];

    return ParkingLot(
      name: name,
      reportedFull: full,
      id: id,
      type: type,
      latLng: dest,
    );
  }
}




class ParkingLotList {

  final List<ParkingLot> parkingLotList;
  final int count;

  const ParkingLotList({required this.parkingLotList, required this.count});

  factory ParkingLotList.fromMap(Map<String, dynamic> json){

    final count = json['locations'].length;
    List<ParkingLot> list = List<ParkingLot>.generate(count, (i) => ParkingLot.fromMap(json['locations'][i]));

    return ParkingLotList(
      parkingLotList: list,
      count: count,
    );
  }
}