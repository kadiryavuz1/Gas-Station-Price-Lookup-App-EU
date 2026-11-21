import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gas_station.dart';

class GasHopService {
  final _client = Supabase.instance.client;

  Future<List<GasStation>> fetchNearbyStations({
    required double userLat,
    required double userLng,
    required double radiusKm,
  }) async {
    print('DEBUG: Supabase RPC Request -> get_nearby_stations');
    print('DEBUG: Params -> {user_lat: $userLat, user_lng: $userLng, max_distance_km: $radiusKm}');
    
    try {
      final response = await _client.rpc(
        'get_nearby_stations',
        params: {
          'user_lat': userLat,
          'user_lng': userLng,
          'max_distance_km': radiusKm,
        },
      );

      print('DEBUG: Supabase RPC Success -> Received ${response.length} stations');
      // Uncomment to see full raw response if needed
      // print('DEBUG: Raw Response -> $response');

      return (response as List<dynamic>)
          .map((json) => GasStation.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      print('DEBUG: Supabase RPC PostgrestException ->');
      print('  Message: ${e.message}');
      print('  Details: ${e.details}');
      print('  Hint: ${e.hint}');
      print('  Code: ${e.code}');
      return [];
    } catch (e) {
      print('DEBUG: Supabase RPC Error -> $e');
      return [];
    }
  }
}
