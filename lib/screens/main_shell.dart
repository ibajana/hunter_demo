import 'package:flutter/material.dart';

import 'asignacion/asignacion_screen.dart';
import 'chequeo/chequeo_screen.dart';
import 'control_calidad/control_calidad_screen.dart';
import 'login_screen.dart';
import 'reception/reception_search_screen.dart';
import 'salida/salida_screen.dart';

/// Contenedor principal de la app tras el login. Provee el [AppBar] con logout,
/// la barra de etapas navegable (Recepción · Asignación · Chequeos · Control
/// Calidad · Salida Vehículo) y conmuta el cuerpo con un [IndexedStack].
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  static const _titles = [
    'Recepción de Vehículos',
    'Asignación de Técnico',
    'Chequeo de Órdenes',
    'Control de Calidad',
    'Salida de Vehículos',
  ];

  final _sections = const [
    ReceptionSection(),
    AsignacionScreen(),
    ChequeoScreen(),
    ControlCalidadScreen(),
    SalidaScreen(),
  ];

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar la sesión actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.directions_car_outlined),
      selectedIcon: Icon(Icons.directions_car),
      label: 'Recepción',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_add_alt_1_outlined),
      selectedIcon: Icon(Icons.person_add_alt_1),
      label: 'Asignación',
    ),
    NavigationDestination(
      icon: Icon(Icons.checklist_outlined),
      selectedIcon: Icon(Icons.checklist),
      label: 'Chequeos',
    ),
    NavigationDestination(
      icon: Icon(Icons.verified_user_outlined),
      selectedIcon: Icon(Icons.verified_user),
      label: 'Calidad',
    ),
    NavigationDestination(
      icon: Icon(Icons.exit_to_app_outlined),
      selectedIcon: Icon(Icons.exit_to_app),
      label: 'Salida',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: _sections,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
