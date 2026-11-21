import 'package:flutter/material.dart';
import '../models/gas_station.dart';
import '../repository/gas_hop_service.dart';

class FuelStationState extends ChangeNotifier {
  final GasHopService _service;
  
  List<GasStation> _stations = [];
  final Set<String> _favoriteIds = {};

  bool _isLoading = false;
  String? _errorMessage;

  FuelStationState({required GasHopService service}) : _service = service;

  List<GasStation> get allStations => List.unmodifiable(_stations);
  List<GasStation> get favoriteStations => _stations
      .where((station) => _favoriteIds.contains(station.id))
      .toList();
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isFavorite(String stationId) => _favoriteIds.contains(stationId);

  void toggleFavorite(String stationId) {
    if (_favoriteIds.contains(stationId)) {
      _favoriteIds.remove(stationId);
    } else {
      _favoriteIds.add(stationId);
    }
    notifyListeners();
  }

  Future<void> searchNearby({required double lat, required double lng, required double radius}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final results = await _service.fetchNearbyStations(
        userLat: lat, 
        userLng: lng, 
        radiusKm: radius,
      );
      _stations = results;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // refreshFavoritePrices logic will need to be updated to a Supabase RPC
  // or a .select().in_('id', _favoriteIds) query in the future.
  Future<void> refreshFavoritePrices() async {
    if (_favoriteIds.isEmpty) return;
    // Implementation for Supabase price refresh...
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
