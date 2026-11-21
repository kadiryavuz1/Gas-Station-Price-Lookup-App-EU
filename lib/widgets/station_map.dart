import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/gas_station.dart';

class StationMap extends StatefulWidget {
  final List<GasStation> stations;
  final Function(GasStation) onStationTap;
  final String preferredFuelType; // "Gasoline", "Diesel", or "LPG"

  const StationMap({
    super.key,
    required this.stations,
    required this.onStationTap,
    this.preferredFuelType = 'Gasoline',
  });

  @override
  State<StationMap> createState() => _StationMapState();
}

class _StationMapState extends State<StationMap> with TickerProviderStateMixin {
  late final MapController _mapController;
  double _currentRotation = 0.0;
  final LatLng _testCenter = const LatLng(51.3653, 6.78083);
  GasStation? _selectedStation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom, double destRotation) {
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween = Tween<double>(
        begin: _mapController.camera.zoom, end: destZoom);
    final rotationTween = Tween<double>(
        begin: _mapController.camera.rotation, end: destRotation);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.moveAndRotate(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
        rotationTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  double _getPriceForType(GasStation station) {
    switch (widget.preferredFuelType) {
      case 'Diesel':
        return station.dieselPrice;
      case 'E10':
        return station.e10Price;
      case 'Gasoline':
      default:
        return station.gasolinePrice;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _testCenter,
            initialZoom: 13.0,
            onPositionChanged: (position, hasGesture) {
              if (position.rotation != _currentRotation) {
                setState(() {
                  _currentRotation = position.rotation;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.gas_hop',
            ),
            MarkerLayer(
              markers: widget.stations.map((station) {
                final bool isSelected = _selectedStation?.id == station.id;
                final double price = _getPriceForType(station);

                return Marker(
                  point: station.location,
                  width: 80,
                  height: 40,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStation = station;
                      });
                      _animatedMapMove(station.location, 15.0, _mapController.camera.rotation);
                      widget.onStationTap(station);
                    },
                    child: _PriceTagBadge(
                      price: price.toStringAsFixed(2),
                      isSelected: isSelected,
                    ),
                  ),
                );
              }).toList(),
            ),
            // User Location Marker
            MarkerLayer(
              markers: [
                Marker(
                  point: _testCenter,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Map Controls
        Positioned(
          right: 16,
          bottom: 210, // Increased from 120 to stay well above the 25% sheet peek
          child: Column(
            children: [
              if (_currentRotation != 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: FloatingActionButton.small(
                    heroTag: 'compass_btn',
                    onPressed: () {
                      _animatedMapMove(_mapController.camera.center, _mapController.camera.zoom, 0);
                    },
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Transform.rotate(
                      angle: -_currentRotation * (pi / 180),
                      child: const Icon(Icons.explore),
                    ),
                  ),
                ),
              FloatingActionButton(
                heroTag: 'location_btn',
                onPressed: () {
                  _animatedMapMove(_testCenter, 14.0, _mapController.camera.rotation);
                },
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.my_location,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceTagBadge extends StatelessWidget {
  final String price;
  final bool isSelected;

  const _PriceTagBadge({
    required this.price,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected 
            ? Colors.deepPurple 
            : const Color(0xFF004D40), // Deep Petrol Blue/Green
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isSelected ? Colors.white : Colors.transparent,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '\$$price',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
