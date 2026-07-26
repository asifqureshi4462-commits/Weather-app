import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

class RadarFrame {
  final int time;
  final String path;
  RadarFrame({required this.time, required this.path});
}

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  final MapController _mapController = MapController();
  List<RadarFrame> _frames = [];
  String _host = 'https://tilecache.rainviewer.com';
  int _currentFrameIndex = 0;
  bool _isLoadingRadar = true;
  bool _isPlaying = false;
  Timer? _animationTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRadarData();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRadarData() async {
    setState(() {
      _isLoadingRadar = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('https://api.rainviewer.com/public/weather-maps.json'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _host = data['host'] ?? 'https://tilecache.rainviewer.com';

        final List<RadarFrame> parsedFrames = [];
        final past = data['radar']?['past'] as List<dynamic>?;
        if (past != null) {
          for (var item in past) {
            if (item['time'] != null && item['path'] != null) {
              parsedFrames.add(RadarFrame(
                time: (item['time'] as num).toInt(),
                path: item['path'].toString(),
              ));
            }
          }
        }

        final nowcast = data['radar']?['nowcast'] as List<dynamic>?;
        if (nowcast != null) {
          for (var item in nowcast) {
            if (item['time'] != null && item['path'] != null) {
              parsedFrames.add(RadarFrame(
                time: (item['time'] as num).toInt(),
                path: item['path'].toString(),
              ));
            }
          }
        }

        if (mounted) {
          setState(() {
            _frames = parsedFrames;
            _currentFrameIndex = parsedFrames.isNotEmpty ? parsedFrames.length - 1 : 0;
            _isLoadingRadar = false;
          });
        }
      } else {
        throw Exception('Failed to load radar server metadata (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Radar unavailable. Check internet connection.';
          _isLoadingRadar = false;
        });
      }
    }
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _animationTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      if (_frames.isEmpty) return;
      setState(() => _isPlaying = true);
      _animationTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
        if (!mounted) return;
        setState(() {
          _currentFrameIndex = (_currentFrameIndex + 1) % _frames.length;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weather = weatherProvider.currentWeather;

    final LatLng centerPos = weather != null
        ? LatLng(weather.location.lat, weather.location.lon)
        : const LatLng(51.5074, -0.1278); // Default London

    return Scaffold(
      appBar: AppBar(
        title: Text(
          weather != null ? 'Live Radar • ${weather.location.name}' : 'Live Weather Radar',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Center Location',
            onPressed: () {
              _mapController.move(centerPos, 8.5);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Radar',
            onPressed: _fetchRadarData,
          ),
        ],
      ),
      body: Stack(
        children: [
          // FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerPos,
              initialZoom: 8.5,
              minZoom: 3.0,
              maxZoom: 15.0,
            ),
            children: [
              // OpenStreetMap Base Tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.atmosphere_weather',
              ),

              // RainViewer Live Overlay Tile Layer
              if (_frames.isNotEmpty && _currentFrameIndex < _frames.length)
                TileLayer(
                  urlTemplate: '$_host${_frames[_currentFrameIndex].path}/256/{z}/{x}/{y}/2/1_1.png',
                  tileProvider: NetworkTileProvider(),
                  opacity: 0.65,
                ),

              // Current Location Marker Pin
              MarkerLayer(
                markers: [
                  Marker(
                    point: centerPos,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.location_on_rounded,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Loading overlay indicator
          if (_isLoadingRadar)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Fetching live precipitation radar frames...',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_errorMessage != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.red.shade900,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: _fetchRadarData,
                        child: const Text('RETRY', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Radar Scrubbing & Legend Control Dock
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Timestamp & Playback Toggle Row
                    Row(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'radar_play',
                          onPressed: _togglePlayback,
                          child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _frames.isNotEmpty
                                  ? DateFormat('E, MMM d • hh:mm a').format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                          _frames[_currentFrameIndex].time * 1000))
                                  : 'Live Radar Timestamp',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'Rain & Precipitation Overlay',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentFrameIndex + 1}/${_frames.isNotEmpty ? _frames.length : 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Slider Scrubbing
                    if (_frames.length > 1) ...[
                      const SizedBox(height: 8),
                      Slider(
                        value: _currentFrameIndex.toDouble(),
                        min: 0,
                        max: (_frames.length - 1).toDouble(),
                        divisions: _frames.length - 1,
                        onChanged: (val) {
                          if (_isPlaying) _togglePlayback();
                          setState(() {
                            _currentFrameIndex = val.toInt();
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Radar Intensity Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Light',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Expanded(
                          child: Container(
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.cyanAccent,
                                  Colors.blue,
                                  Colors.green,
                                  Colors.yellow,
                                  Colors.amber,
                                  Colors.red,
                                  Colors.purple,
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          'Heavy',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
