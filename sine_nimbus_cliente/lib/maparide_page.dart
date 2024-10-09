// ignore_for_file: prefer_final_fields, library_private_types_in_public_api, use_build_context_synchronously, unused_element

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapaRidePage extends StatefulWidget {
  final int depotId;
  final String token;
  final int data;
  final List<Map<String, dynamic>> stopDataList;
  final List<Color> coloresAsignados;

  const MapaRidePage({
    Key? key,
    required this.token,
    required this.depotId,
    required this.data,
    required atraso,
    required adelantamiento,
    required this.stopDataList,
    required this.coloresAsignados,
  }) : super(key: key);

  @override
  _MapaRidePageState createState() => _MapaRidePageState();
}

class _MapaRidePageState extends State<MapaRidePage> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  LatLng? firstPosition;
  final PolylinePoints polylinePoints = PolylinePoints();
  Set<Polyline> _polylines = {};
  MapType _currentMapType = MapType.terrain;
  List<dynamic> stops = [];

  @override
  void initState() {
    super.initState();
    _checkInternetConnectivity();
    fetchStops2().then((_) {
      fetchData();
    });
  }

  Future<void> fetchData() async {
    final apiUrl =
        'https://nimbus.wialon.com/api/depot/${widget.depotId}/route/${widget.data}';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'accept': 'application/json',
        'Authorization': widget.token,
      },
    );

    if (response.statusCode == 200) {
      final items = json.decode(response.body);
      var st = items['st'];

      int stationCount = 1;
      for (var station in st) {
        List<PointLatLng> pointLatLng =
            polylinePoints.decodePolyline(station['p']);

        if (pointLatLng.isNotEmpty) {
          LatLng stationLocation =
              LatLng(pointLatLng.first.latitude, pointLatLng.first.longitude);

          final matchedStop = stops.firstWhere(
            (stop) => stop['id'].toString() == station['id'].toString(),
            orElse: () => null,
          );

          final stopName =
              matchedStop != null ? matchedStop['n'] : 'Parada $stationCount';

          // Obtenemos el color para este marcador en particular
          Color markerColor = widget.coloresAsignados.isNotEmpty
              ? widget.coloresAsignados[
                  (stationCount - 1) % widget.coloresAsignados.length]
              : Colors
                  .grey; // Color predeterminado en caso de que la lista esté vacía

          final customIcon = await _createCustomMarker(markerColor);

          final marker = Marker(
            markerId: MarkerId(station['id'].toString()),
            position: stationLocation,
            infoWindow: InfoWindow(
              title: stopName,
              snippet: stationLocation.toString(),
            ),
            icon: customIcon,
          );
          _markers.add(marker);
          stationCount++;

          firstPosition ??= stationLocation;
        }
      }

      if (firstPosition != null) {
        List<LatLng> polylineCoordinates = [];
        for (var i = 0; i < st.length - 1; i++) {
          List<PointLatLng> points = polylinePoints.decodePolyline(st[i]['p']);
          polylineCoordinates.addAll(
              points.map((point) => LatLng(point.latitude, point.longitude)));
        }

        Polyline polyline = Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          points: polylineCoordinates,
          width: 5,
        );

        setState(() {
          _polylines.add(polyline);
        });
      }
    } else {
    }
  }

  Future<List<String>> fetchStops2() async {
    final apiUrl =
        'https://nimbus.wialon.com/api/depot/${widget.depotId}/stops';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'accept': 'application/json',
        'Authorization': widget.token,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      stops = data['stops'] as List<dynamic>;
      return [];
    } else {
      return [];
    }
  }

  Future<BitmapDescriptor> _createCustomMarker(Color color) async {
    String markerAssetName;

    // Si el color es transparente, asignamos el marcador morado
    if (color.value == const Color(0x00000000).value) {
      markerAssetName = 'assets/morado.png';
    } else {
      // Creamos un mapa que asigne el nombre de archivo de imagen a cada color correspondiente
      Map<Color, String> colorToFile = {
        Colors.red: 'assets/rojo.png',
        Colors.yellow: 'assets/amarillo.png',
        Colors.grey: 'assets/griss.png',
        // Aquí puedes seguir agregando más colores y sus nombres de archivo de imagen
      };

      // Si el color está en el mapa, usamos su nombre de archivo de imagen correspondiente,
      // de lo contrario, usamos el marcador predeterminado
      markerAssetName = colorToFile[color] ?? 'assets/morado.png';
    }

    return BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(
        devicePixelRatio:
            2.5, // Ajusta el valor del devicePixelRatio según tus imágenes
      ),
      markerAssetName,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _toggleMapType() {
    setState(() {
      if (_currentMapType == MapType.terrain) {
        _currentMapType = MapType.normal;
      } else if (_currentMapType == MapType.normal) {
        _currentMapType = MapType.satellite;
      } else {
        _currentMapType = MapType.terrain;
      }
    });
  }

  // Método para verificar si el dispositivo tiene conexión a Internet
  Future<void> _checkInternetConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // Mostrar un diálogo si no hay conexión
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35),
            ),
            titlePadding: const EdgeInsets.all(20),
            title: const Row(
              children: [
                Icon(
                  Icons.signal_wifi_statusbar_connected_no_internet_4,
                  color: Color.fromARGB(255, 255, 0, 0),
                  size: 40,
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "Sin conexión a Internet",
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 0, 0),
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              "Por favor, verifica tu conexión a Internet.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            actions: [
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                  ),
                  icon: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: const Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      );
    }
  }

    // Método para verificar si hay datos disponibles para generar el mapa
  bool _hasDataForMap() {
    return firstPosition != null;
  }

  // Método que muestra una alerta si no hay datos disponibles
  void _showNoDataDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
            return AlertDialog(
                title: const Text("Alerta"),
                content: const Text("No se ha podido generar el mapa ya que no hay datos disponibles."),
                actions: [
                    TextButton(
                        child: const Text("Cerrar"),
                        onPressed: () {
                            Navigator.of(context).pop();
                        },
                    ),
                ],
            );
        },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⏱️ Ruta en Seguimiento ⏱️'),
        backgroundColor: Colors.grey[900],
      ),
      body: (firstPosition == null)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 20),
                  Image.asset('assets/nimbus.gif'),
                  const SizedBox(height: 20),
                  const Text('Cargando Ruta...'),
                  const SizedBox(height: 20),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: firstPosition != null
                      ? CameraPosition(
                          target: firstPosition!,
                          zoom: 17,
                        )
                      : const CameraPosition(
                          target: LatLng(0, 0),
                          zoom: 50,
                        ),
                  markers: _markers,
                  polylines: _polylines,
                  mapType: _currentMapType,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  trafficEnabled: true,
                ),
                Positioned(
                  right: 4,
                  top: 60,
                  child: FloatingActionButton(
                    onPressed: _toggleMapType,
                    backgroundColor: Colors.white,
                    child: Icon(
                      _currentMapType == MapType.terrain
                          ? Icons.terrain
                          : _currentMapType == MapType.normal
                              ? Icons.map
                              : Icons.satellite,
                      color: Colors.grey[900],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
