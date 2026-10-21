import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/permission_dialogs.dart';

class RadarFrame {
  final int time;
  final String path;
  final bool isForecast;
  RadarFrame({required this.time, required this.path, this.isForecast = false});
}

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  static const double _minZoom = 3.0;
  static const double _maxZoom = 18.0;
  // RainViewer radar tiles only exist up to zoom 7. Zooming further now stretches the
  // level-7 tiles instead of requesting tiles that do not exist (this caused the zoom glitch).
  static const int _radarNativeZoom = 7;

  final MapController _mapController = MapController();
  List<RadarFrame> _frames = [];
  String _host = 'https://tilecache.rainviewer.com';
  int _currentFrameIndex = 0;
  bool _isLoadingRadar = true;
  bool _isPlaying = false;
  bool _mapReady = false;
  Timer? _animationTimer;
  Timer? _refreshTimer;
  String? _errorMessage;
  String? _centeredKey;

  @override
  void initState() {
    super.initState();
    _fetchRadarData();
    // Keep radar fresh: reload frames every 10 minutes when not playing.
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      if (!_isPlaying && mounted) _fetchRadarData(silent: true);
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRadarData({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoadingRadar = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await http
          .get(Uri.parse('https://api.rainviewer.com/public/weather-maps.json'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('Failed to load radar server metadata (${response.statusCode})');
      }

      final data = json.decode(response.body);
      final host = (data['host'] ?? 'https://tilecache.rainviewer.com').toString();

      final List<RadarFrame> parsed = [];
      var pastCount = 0;

      final past = data['radar']?['past'] as List<dynamic>?;
      if (past != null) {
        for (final item in past) {
          if (item['time'] != null && item['path'] != null) {
            parsed.add(RadarFrame(
              time: (item['time'] as num).toInt(),
              path: item['path'].toString(),
            ));
            pastCount++;
          }
        }
      }

      final nowcast = data['radar']?['nowcast'] as List<dynamic>?;
      if (nowcast != null) {
        for (final item in nowcast) {
          if (item['time'] != null && item['path'] != null) {
            parsed.add(RadarFrame(
              time: (item['time'] as num).toInt(),
              path: item['path'].toString(),
              isForecast: true,
            ));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _host = host;
        _frames = parsed;
        // Start on the most recent real (past) frame.
        _currentFrameIndex = parsed.isEmpty ? 0 : (pastCount > 0 ? pastCount - 1 : parsed.length - 1);
        _isLoadingRadar = false;
        _errorMessage = parsed.isEmpty ? 'No radar data available right now.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      if (silent && _frames.isNotEmpty) return; // keep showing old frames
      setState(() {
        _errorMessage = 'Radar unavailable. Check internet connection.';
        _isLoadingRadar = false;
      });
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
        if (!mounted || _frames.isEmpty) {
          timer.cancel();
          return;
        }
        setState(() {
          _currentFrameIndex = (_currentFrameIndex + 1) % _frames.length;
        });
      });
    }
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    try {
      final camera = _mapController.camera;
      final zoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom).toDouble();
      _mapController.move(camera.center, zoom);
    } catch (e) {
      debugPrint('Zoom error: $e');
    }
  }

  void _centerOn(LatLng pos, {double zoom = 7.0}) {
    if (!_mapReady) return;
    try {
      _mapController.move(pos, zoom);
    } catch (e) {
      debugPrint('Center map error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weather = weatherProvider.currentWeather;

    final LatLng centerPos = weather != null
        ? LatLng(weather.location.lat, weather.location.lon)
        : const LatLng(51.5074, -0.1278); // Default London

    // When the active location changes (GPS update / new city) move the map to it.
    final centerKey = '${centerPos.latitude.toStringAsFixed(3)},${centerPos.longitude.toStringAsFixed(3)}';
    if (_centeredKey == null) {
      _centeredKey = centerKey;
    } else if (_centeredKey != centerKey) {
      _centeredKey = centerKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _centerOn(centerPos);
      });
    }

    final frame = (_frames.isNotEmpty && _currentFrameIndex < _frames.length)
        ? _frames[_currentFrameIndex]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          weather != null ? 'Live Radar • ${weather.location.name}' : 'Live Weather Radar',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Center Location',
            onPressed: () => _centerOn(centerPos),
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerPos,
              initialZoom: 7.0,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              // Pinch-zoom, drag and double-tap zoom work; rotation is disabled because
              // it fights with the two-finger zoom gesture.
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () => _mapReady = true,
            ),
            children: [
              // OpenStreetMap base tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.atmosphere_weather',
                maxNativeZoom: 19,
                maxZoom: _maxZoom,
                errorTileCallback: (tile, error, stackTrace) {},
              ),

              // RainViewer live overlay (native tiles up to zoom 7, stretched beyond)
              if (frame != null)
                Opacity(
                  opacity: 0.65,
                  child: TileLayer(
                    urlTemplate: '$_host${frame.path}/256/{z}/{x}/{y}/2/1_1.png',
                    userAgentPackageName: 'com.example.atmosphere_weather',
                    maxNativeZoom: _radarNativeZoom,
                    maxZoom: _maxZoom,
                    tileProvider: NetworkTileProvider(),
                    errorTileCallback: (tile, error, stackTrace) {},
                  ),
                ),

              // Current location marker with pulsing animation
              MarkerLayer(
                markers: [
                  Marker(
                    point: centerPos,
                    width: 64,
                    height: 64,
                    child: const PulsingIcon(
                      icon: Icons.my_location_rounded,
                      color: Colors.blueAccent,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (_isLoadingRadar)
            Positioned(
              top: 16,
              left: 16,
              right: 76,
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
                      Expanded(
                        child: Text(
                          'Fetching live radar frames...',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_errorMessage != null && !_isLoadingRadar)
            Positioned(
              top: 16,
              left: 16,
              right: 76,
              child: Card(
                color: Colors.red.shade900,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.white),
                      const SizedBox(width: 8),
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

          // Zoom controls
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'radar_zoom_in',
                    tooltip: 'Zoom in',
                    onPressed: () => _zoomBy(1),
                    child: const Icon(Icons.add_rounded),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton.small(
                    heroTag: 'radar_zoom_out',
                    tooltip: 'Zoom out',
                    onPressed: () => _zoomBy(-1),
                    child: const Icon(Icons.remove_rounded),
                  ),
                ],
              ),
            ),
          ),

          // Bottom radar control dock
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
                    Row(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'radar_play',
                          onPressed: _togglePlayback,
                          child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                frame != null
                                    ? DateFormat('E, MMM d • hh:mm a').format(
                                        DateTime.fromMillisecondsSinceEpoch(frame.time * 1000))
                                    : 'Live Radar Timestamp',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                frame != null && frame.isForecast
                                    ? 'Rain forecast (next hour)'
                                    : 'Rain & Precipitation Overlay',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_frames.isNotEmpty ? _currentFrameIndex + 1 : 0}/${_frames.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_frames.length > 1) ...[
                      const SizedBox(height: 8),
                      Slider(
                        value: _currentFrameIndex.clamp(0, _frames.length - 1).toDouble(),
                        min: 0,
                        max: (_frames.length - 1).toDouble(),
                        divisions: _frames.length - 1,
                        onChanged: (val) {
                          if (_isPlaying) _togglePlayback();
                          setState(() {
                            _currentFrameIndex = val.round();
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 8),

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
                    const SizedBox(height: 6),
                    const Text(
                      '© OpenStreetMap contributors • Radar: RainViewer',
                      style: TextStyle(fontSize: 9, color: Colors.grey),
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
