import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/gas_station.dart';
import '../repository/gas_hop_service.dart';

class SupabaseMapIntegration extends StatefulWidget {
  const SupabaseMapIntegration({super.key});

  @override
  State<SupabaseMapIntegration> createState() => _SupabaseMapIntegrationState();
}

class _SupabaseMapIntegrationState extends State<SupabaseMapIntegration> {
  final GasHopService _gasHopService = GasHopService();
  
  // State variables
  List<GasStation> _stations = [];
  bool _isLoading = false;
  double _selectedRadius = 5.0; // Default radius

  // Test User Location (e.g., Berlin)
  final double _userLat = 52.5200;
  final double _userLng = 13.4050;

  @override
  void initState() {
    super.initState();
    _loadNearbyStations();
  }

  Future<void> _loadNearbyStations() async {
    setState(() => _isLoading = true);
    
    try {
      final stations = await _gasHopService.fetchNearbyStations(
        userLat: _userLat,
        userLng: _userLng,
        radiusKm: _selectedRadius,
      );
      
      setState(() {
        _stations = stations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stations: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Gas Stations'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Radius Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Radius: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(
                  child: SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 1.0, label: Text('1km')),
                      ButtonSegment(value: 5.0, label: Text('5km')),
                      ButtonSegment(value: 10.0, label: Text('10km')),
                      ButtonSegment(value: 25.0, label: Text('25km')),
                    ],
                    selected: {_selectedRadius},
                    onSelectionChanged: (Set<double> newSelection) {
                      setState(() {
                        _selectedRadius = newSelection.first;
                      });
                      _loadNearbyStations();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Map View
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(_userLat, _userLng),
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.gas_hop',
                ),
                MarkerLayer(
                  markers: _stations.map((station) {
                    return Marker(
                      point: LatLng(station.latitude, station.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showStationDetails(station),
                        child: const Icon(
                          Icons.local_gas_station,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStationDetails(GasStation station) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(station.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('${station.brand} • ${station.distanceKm.toStringAsFixed(2)} km away'),
              const Divider(),
              Text('Address: ${station.street}, ${station.place}'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _priceTile('E5', station.e5),
                  _priceTile('E10', station.e10),
                  _priceTile('Diesel', station.diesel),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _priceTile(String label, double? price) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          price != null ? '€${price.toStringAsFixed(2)}' : 'N/A',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
