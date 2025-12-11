// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'page.dart';

class HeatmapPage extends ExamplePage {
  const HeatmapPage({super.key})
      : super(const Icon(Icons.thermostat), 'Heatmap Layer');

  @override
  Widget build(BuildContext context) {
    return const HeatmapBody();
  }
}

class HeatmapBody extends StatefulWidget {
  const HeatmapBody({super.key});

  @override
  State<StatefulWidget> createState() => HeatmapBodyState();
}

class HeatmapBodyState extends State<HeatmapBody> {
  // Sulaymaniyah, Iraq coordinates
  static const LatLng sulaymaniyahCenter = LatLng(35.5556, 45.4375);
  static const String sourceId = 'heatmap_source';
  static const String layerId = 'heatmap_layer';

  MapLibreMapController? controller;
  bool _heatmapAdded = false;
  int _pointCount = 100;
  double _heatmapRadius = 30;
  double _heatmapIntensity = 1.0;

  void _onMapCreated(MapLibreMapController controller) {
    this.controller = controller;
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Generate random points around Sulaymaniyah city
  Map<String, dynamic> _generateHeatmapData(int pointCount) {
    final random = Random();
    final features = <Map<String, dynamic>>[];

    for (var i = 0; i < pointCount; i++) {
      // Generate points within approximately 0.1 degrees radius
      final distance = random.nextDouble() * 0.1;
      final angle = random.nextDouble() * 2 * pi;

      final lat = sulaymaniyahCenter.latitude + (distance * cos(angle));
      final lng = sulaymaniyahCenter.longitude + (distance * sin(angle));

      // Random intensity for each point
      final intensity = random.nextDouble() * 10;

      features.add({
        'type': 'Feature',
        'properties': {
          'intensity': intensity,
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [lng, lat],
        },
      });
    }

    return {
      'type': 'FeatureCollection',
      'features': features,
    };
  }

  Future<void> _addHeatmap() async {
    if (controller == null) return;

    // Add GeoJSON source with random points
    await controller!.addSource(
      sourceId,
      GeojsonSourceProperties(data: _generateHeatmapData(_pointCount)),
    );

    // Add heatmap layer with beautiful color gradient
    await controller!.addHeatmapLayer(
      sourceId,
      layerId,
      HeatmapLayerProperties(
        heatmapRadius: _heatmapRadius,
        heatmapWeight: [
          'interpolate',
          ['linear'],
          ['get', 'intensity'],
          0,
          0,
          10,
          1,
        ],
        heatmapIntensity: [
          'interpolate',
          ['linear'],
          ['zoom'],
          0,
          1,
          15,
          _heatmapIntensity,
        ],
        heatmapColor: [
          'interpolate',
          ['linear'],
          ['heatmap-density'],
          0,
          'rgba(33,102,172,0)',
          0.2,
          'rgb(103,169,207)',
          0.4,
          'rgb(209,229,240)',
          0.6,
          'rgb(253,219,199)',
          0.8,
          'rgb(239,138,98)',
          1,
          'rgb(178,24,43)',
        ],
        heatmapOpacity: 0.8,
      ),
    );

    setState(() {
      _heatmapAdded = true;
    });
  }

  Future<void> _removeHeatmap() async {
    if (controller == null) return;

    await controller!.removeLayer(layerId);
    await controller!.removeSource(sourceId);

    setState(() {
      _heatmapAdded = false;
    });
  }

  Future<void> _updateHeatmapRadius() async {
    if (controller == null || !_heatmapAdded) return;

    await controller!.setLayerProperties(
      layerId,
      HeatmapLayerProperties(
        heatmapRadius: _heatmapRadius,
      ),
    );
  }

  Future<void> _updateHeatmapIntensity() async {
    if (controller == null || !_heatmapAdded) return;

    await controller!.setLayerProperties(
      layerId,
      HeatmapLayerProperties(
        heatmapIntensity: [
          'interpolate',
          ['linear'],
          ['zoom'],
          0,
          1,
          15,
          _heatmapIntensity,
        ],
      ),
    );
  }

  Future<void> _regenerateData() async {
    if (controller == null || !_heatmapAdded) return;

    await _removeHeatmap();
    await _addHeatmap();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: MapLibreMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: sulaymaniyahCenter,
              zoom: 11.0,
            ),
            onStyleLoadedCallback: () {
              // Optionally add heatmap automatically
              _addHeatmap();
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _heatmapAdded ? null : _addHeatmap,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Heatmap'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _heatmapAdded ? _removeHeatmap : null,
                    icon: const Icon(Icons.remove),
                    label: const Text('Remove Heatmap'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Points: '),
                  Expanded(
                    child: Slider(
                      value: _pointCount.toDouble(),
                      min: 10,
                      max: 500,
                      divisions: 49,
                      label: _pointCount.toString(),
                      onChanged: (value) {
                        setState(() {
                          _pointCount = value.toInt();
                        });
                      },
                      onChangeEnd: (value) {
                        _regenerateData();
                      },
                    ),
                  ),
                  Text(_pointCount.toString()),
                ],
              ),
              Row(
                children: [
                  const Text('Radius: '),
                  Expanded(
                    child: Slider(
                      value: _heatmapRadius,
                      min: 10,
                      max: 100,
                      divisions: 18,
                      label: _heatmapRadius.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          _heatmapRadius = value;
                        });
                      },
                      onChangeEnd: (value) {
                        _updateHeatmapRadius();
                      },
                    ),
                  ),
                  Text(_heatmapRadius.round().toString()),
                ],
              ),
              Row(
                children: [
                  const Text('Intensity: '),
                  Expanded(
                    child: Slider(
                      value: _heatmapIntensity,
                      min: 0.1,
                      max: 3.0,
                      divisions: 29,
                      label: _heatmapIntensity.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _heatmapIntensity = value;
                        });
                      },
                      onChangeEnd: (value) {
                        _updateHeatmapIntensity();
                      },
                    ),
                  ),
                  Text(_heatmapIntensity.toStringAsFixed(1)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _heatmapAdded ? _regenerateData : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Regenerate Data'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
