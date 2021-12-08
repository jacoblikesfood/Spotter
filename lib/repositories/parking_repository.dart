import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:spotter/.env.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotter/models/directions_model.dart';
import 'package:spotter/models/parking_model.dart';

class ParkingRepository {
  static const String _baseUrl =
      'https://park-me-api-capstone.herokuapp.com/';

  final Dio _dio;

  ParkingRepository({Dio? dio}) : _dio = dio ?? Dio();

  Future <ParkingLotList> getParkingLot({
    required LatLng location,
  }) async {
    final response = await _dio.get(
      _baseUrl + 'locations/' + '${location.latitude}' + '/' + '${location.longitude}',
    );

    return ParkingLotList.fromMap(response.data);
  }

  Future <ParkingLotList> getParkingLotWithType({
    required LatLng location,
    required int type,
  }) async {
    final response = await _dio.get(
      _baseUrl + 'locations/type/' + '${type}' + '/' + '${location.latitude}' + '/' + '${location.longitude}'
    );

    return ParkingLotList.fromMap(response.data);
  }

  void postParkingLotFull({
    required int id,
  }) async {
    final response = await _dio.post(
      _baseUrl + '/locations/report/' + '${id}'
    );
  }
}