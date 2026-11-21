import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/fuel_station_state.dart';
import '../models/gas_station.dart';
import '../widgets/station_map.dart';
import '../widgets/debouncer.dart';
import '../utils/navigation_utils.dart';

enum FuelType { e5, e10, diesel }
enum SortOption { price, distance }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String selectedRadiusLabel = '5 km';
  double selectedRadiusValue = 5.0;
  final List<Map<String, dynamic>> radiusOptions = [
    {'label': '1 km', 'value': 1.0},
    {'label': '5 km', 'value': 5.0},
    {'label': '10 km', 'value': 10.0},
    {'label': '25 km', 'value': 25.0},
  ];

  // UI State for Filtering & Sorting
  FuelType selectedFuelType = FuelType.e5;
  SortOption selectedSortOption = SortOption.distance;


  // Test Coordinates
  final double testLat = 51.3653;
  final double testLng = 6.78083;

  GasStation? selectedStation;
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final Debouncer _debouncer = Debouncer(delay: const Duration(seconds: 3));
  
  // High-performance state tracking: only rebuilds the icon, not the whole map/screen
  final ValueNotifier<double> _sheetSizeNotifier = ValueNotifier<double>(0.25);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch();
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _sheetController.dispose();
    _sheetSizeNotifier.dispose();
    super.dispose();
  }

  void _expandSheetFull() {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.75,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _expandSheetMid() {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleSheet() {
    if (!_sheetController.isAttached) return;
    final isExpanded = _sheetSizeNotifier.value > 0.20;
    if (isExpanded) {
      _sheetController.animateTo(
        0.15,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _sheetController.animateTo(
        0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _performSearch() {
    final state = Provider.of<FuelStationState>(context, listen: false);
    state.searchNearby(
      lat: testLat,
      lng: testLng,
      radius: selectedRadiusValue,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<FuelStationState>(context);
    
    // Dynamic Sorting Logic
    List<GasStation> displayStations = List.from(state.allStations);
    if (selectedSortOption == SortOption.distance) {
      displayStations.sort((a, b) => a.distance.compareTo(b.distance));
    } else {
      displayStations.sort((a, b) {
        double priceA = selectedFuelType == FuelType.e5 ? a.gasolinePrice : (selectedFuelType == FuelType.e10 ? a.e10Price : a.dieselPrice);
        double priceB = selectedFuelType == FuelType.e5 ? b.gasolinePrice : (selectedFuelType == FuelType.e10 ? b.e10Price : b.dieselPrice);
        return priceA.compareTo(priceB);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Station Map - NO REBUILDS during drag
          StationMap(
            stations: displayStations,
            preferredFuelType: selectedFuelType == FuelType.e5 ? 'Gasoline' : (selectedFuelType == FuelType.diesel ? 'Diesel' : 'E10'),
            onStationTap: (station) {
              setState(() {
                selectedStation = station;
              });
              _expandSheetMid();
            },
          ),
          
          // UI Overlays
          SafeArea(
            child: Column(
              children: [
                // Radius Selection
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 16),
                        ...radiusOptions.map((opt) {
                          final isSelected = selectedRadiusLabel == opt['label'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(opt['label']),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    selectedRadiusLabel = opt['label'];
                                    selectedRadiusValue = opt['value'];
                                  });
                                  _debouncer.run(() => _performSearch());
                                }
                              },
                            ),
                          );
                        }),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                
                // Fuel Type Selector
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SegmentedButton<FuelType>(
                      segments: const [
                        ButtonSegment(value: FuelType.e5, label: Text('E5'), icon: Icon(Icons.local_gas_station)),
                        ButtonSegment(value: FuelType.e10, label: Text('E10'), icon: Icon(Icons.eco)),
                        ButtonSegment(value: FuelType.diesel, label: Text('Diesel'), icon: Icon(Icons.settings_input_component)),
                      ],
                      selected: {selectedFuelType},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          selectedFuelType = newSelection.first;
                        });
                      },
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        selectedBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                if (state.isLoading)
                  Card(
                    elevation: 4,
                    shape: const StadiumBorder(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 12),
                          const Text('Updating Prices...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Station List Panel with HIGH PERFORMANCE NotificationListener
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              // Update notifier directly WITHOUT calling setState()
              // This avoids rebuilding the entire screen every frame of the drag.
              _sheetSizeNotifier.value = notification.extent;
              return true;
            },
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.25,
              minChildSize: 0.15,
              maxChildSize: 0.75,
              snap: true,
              builder: (context, sheetScrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                  ),
                  child: Column(
                    children: [
                      // ELEMENT A: Static Header
                      GestureDetector(
                        onTap: () {
                          if (_sheetSizeNotifier.value > 0.20) {
                            _expandSheetFull();
                          } else {
                            _toggleSheet();
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 60,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    top: 12,
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                                    ),
                                  ),
                                  Positioned(
                                    top: 24,
                                    child: Text('Nearby Stations (${displayStations.length})', 
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 4,
                                    child: ValueListenableBuilder<double>(
                                      valueListenable: _sheetSizeNotifier,
                                      builder: (context, size, _) {
                                        final isExpanded = size > 0.20;
                                        return IconButton(
                                          onPressed: _toggleSheet,
                                          icon: AnimatedRotation(
                                            turns: isExpanded ? 0 : 0.5,
                                            duration: const Duration(milliseconds: 300),
                                            child: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 36),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _SortChip(
                                    label: 'Closest', 
                                    isSelected: selectedSortOption == SortOption.distance,
                                    onTap: () => setState(() => selectedSortOption = SortOption.distance),
                                  ),
                                  const SizedBox(width: 12),
                                  _SortChip(
                                    label: 'Cheapest', 
                                    isSelected: selectedSortOption == SortOption.price,
                                    onTap: () => setState(() => selectedSortOption = SortOption.price),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      
                      Expanded(
                        child: ListView.builder(
                          controller: sheetScrollController,
                          padding: EdgeInsets.zero,
                          physics: const ClampingScrollPhysics(),
                          itemCount: displayStations.length,
                          itemBuilder: (context, index) {
                            final station = displayStations[index];
                            final isFav = state.isFavorite(station.id);
                            final isSelected = selectedStation?.id == station.id;
                            final currentPrice = (selectedFuelType == FuelType.e5 ? station.gasolinePrice : (selectedFuelType == FuelType.e10 ? station.e10Price : station.dieselPrice));

                            return InkWell(
                              onTap: () => setState(() => selectedStation = station),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2) : null,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceVariant,
                                          child: Icon(Icons.local_gas_station, size: 18, color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(station.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              const SizedBox(height: 2),
                                              Text(station.address, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                              const SizedBox(height: 2),
                                              Text('${station.distance} km away', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('€${currentPrice.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: isSelected ? Theme.of(context).colorScheme.primary : null)),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => state.toggleFavorite(station.id),
                                              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey, size: 20),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          _FuelPrice(label: 'E5', price: station.gasolinePrice),
                                          const SizedBox(width: 12),
                                          _FuelPrice(label: 'Diesel', price: station.dieselPrice),
                                          const SizedBox(width: 12),
                                          _FuelPrice(label: 'E10', price: station.e10Price),
                                          const Spacer(),
                                          _StatusTag(isOpen: station.isOpen),
                                          const SizedBox(width: 8),
                                          IconButton.filledTonal(
                                            onPressed: () => NavigationUtils.openMapDirections(station.location.latitude, station.location.longitude, station.name),
                                            icon: const Icon(Icons.directions, size: 18),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SortChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.grey[700])),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final bool isOpen;
  const _StatusTag({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(isOpen ? 'OPEN' : 'CLOSED', style: TextStyle(color: isOpen ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}

class _FuelPrice extends StatelessWidget {
  final String label;
  final double price;
  const _FuelPrice({required this.label, required this.price});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        Text('€${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
