import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'config/supabase_config.dart';
import 'data/fuel_station_state.dart';
import 'repository/gas_hop_service.dart';
import 'screens/main_navigation.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Mobile Ads SDK. The app uses Google's official test ad
  // units (see AdService), so no production ad IDs are required to run.
  await MobileAds.instance.initialize();

  // Credentials are injected at build time via --dart-define so that no
  // backend keys are committed to source control. See README.md for setup.
  if (!SupabaseConfig.isConfigured) {
    throw StateError(
      'Supabase credentials are missing. Provide SUPABASE_URL and '
      'SUPABASE_ANON_KEY, e.g. with '
      '--dart-define-from-file=dart_define.json. See README.md.',
    );
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => FuelStationState(service: GasHopService()),
      child: const GasHopApp(),
    ),
  );
}

class GasHopApp extends StatefulWidget {
  const GasHopApp({super.key});

  @override
  State<GasHopApp> createState() => _GasHopAppState();
}

class _GasHopAppState extends State<GasHopApp> with WidgetsBindingObserver {
  late AppOpenAdManager _appOpenAdManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appOpenAdManager = AppOpenAdManager()..loadAd(showImmediately: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appOpenAdManager.showAdIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GasHop - Price Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}
