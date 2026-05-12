import 'package:flutter/material.dart';

class MapData {
  final String name;
  final double realSizeMeter;
  MapData(this.name, this.realSizeMeter);
}

final List<MapData> pubgMaps = [
  MapData("대형 (8x8km)", 8000),
  MapData("중형 (4x4km)", 4000),
  MapData("소형 (2x2km)", 2000),
];

final Map<int, Color> squadColors = {
  1: Colors.yellow,
  2: Colors.orange,
  3: Colors.blue,
  4: Colors.green,
};