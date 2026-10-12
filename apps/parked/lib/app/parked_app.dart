import 'package:flutter/material.dart';

import '../features/map/map_page.dart';

class ParkedApp extends StatelessWidget {
  const ParkedApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Parked',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const MapPage(),
      );
}
