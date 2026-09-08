import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';

/// Mirrors frontend/src/components/matching/WorkLocationPicker.tsx: a pure
/// click/tap-to-drop-pin OSM map, no geocoding or address search — just
/// (lat, lng) out. The free-text label is a separate field the caller owns.
class WorkLocationPicker extends StatefulWidget {
  const WorkLocationPicker({super.key, this.initialLat, this.initialLng, required this.onChanged});

  final double? initialLat;
  final double? initialLng;
  final void Function(double lat, double lng) onChanged;

  static const _defaultCenter = LatLng(27.7172, 85.324); // Kathmandu

  @override
  State<WorkLocationPicker> createState() => _WorkLocationPickerState();
}

class _WorkLocationPickerState extends State<WorkLocationPicker> {
  LatLng? _pin;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _pin = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _pin ?? WorkLocationPicker._defaultCenter,
            initialZoom: 12,
            onTap: (tapPosition, point) {
              setState(() => _pin = point);
              widget.onChanged(point.latitude, point.longitude);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.gharnepal.ghar_nepal',
            ),
            if (_pin != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pin!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: AppColors.trust700, size: 36),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
