// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, prefer_final_fields
// Importaciones de paquetes necesarios
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Clase principal para mostrar la página de rutas
class RutasPage extends StatefulWidget {
  final String token; // Token para autenticación de la API
  final int depotId; // ID del depósito desde el cual se obtendrán las rutas

  const RutasPage({Key? key, required this.token, required this.depotId})
      : super(key: key);

  @override
  _RutasPageState createState() => _RutasPageState();
}

class _RutasPageState extends State<RutasPage> {
  List<dynamic> routes = []; // Lista para almacenar las rutas obtenidas
  String selectedRouteId = ''; // ID de la ruta seleccionada
  final TextEditingController _searchController =
      TextEditingController(); // Controlador del campo de búsqueda
  List<dynamic> filteredRoutes =
      []; // Rutas filtradas según el texto de búsqueda

  @override
  void initState() {
    super.initState();
    _checkInternetConnectivity(); // Verificar conexión a Internet
    fetchData(); // Obtener rutas desde la API
    filteredRoutes =
        List.from(routes); // Inicializar rutas filtradas con todas las rutas
  }

  // Método para obtener las rutas desde la API
  Future<void> fetchData() async {
    final apiUrl =
        'https://nimbus.wialon.com/api/depot/${widget.depotId}/routes';
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'accept': 'application/json',
        'Authorization': widget.token,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        routes = data['routes'] ?? [];
        filteredRoutes = List.from(routes);
      });
    }
  }

  // Método para obtener las paradas de una ruta específica
  Future<List<String>> fetchStops(String routeId) async {
    final apiUrl =
        'https://nimbus.wialon.com/api/depot/${widget.depotId}/route/$routeId';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'accept': 'application/json',
        'Authorization': widget.token,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final st = data['st'] ?? [];
      // Filtramos las paradas con coordenadas no vacías
      final filteredStops = st
          .where((stop) => stop['p'] != null && stop['p'].isNotEmpty)
          .toList();
      // Sólo procesamos las paradas filtradas
      final stops = filteredStops
          .map((stop) => 'Parada ${stop['id']}')
          .toList()
          .cast<String>();
      return stops;
    } else {
      //print('Error: ${response.statusCode}');
      return [];
    }
  }

  // Método para filtrar rutas según una consulta
  void _filterRoutes(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredRoutes = List.from(routes);
      });
    } else {
      final lowerCaseQuery = query.toLowerCase();
      setState(() {
        filteredRoutes = routes.where((route) {
          final routeName = route['n'].toString().toLowerCase();
          return routeName.contains(lowerCaseQuery);
        }).toList();
      });
    }
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

  // Construir la interfaz de usuario de la página
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text(
              'Rutas',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[900],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                _filterRoutes(value);
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                hintText: 'Buscar ruta',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredRoutes.length,
              itemBuilder: (BuildContext context, int index) {
                final route = filteredRoutes[index];
                final routeId = route['id'].toString();

                return Card(
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ExpansionTile(
                    leading: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.bus_alert,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      '${route['n']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: const Text(
                      'Nombre de la Ruta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    children: [
                      FutureBuilder<List<String>>(
                        future: fetchStops(routeId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return const Text(
                              'Error al obtener las paradas',
                              style: TextStyle(color: Colors.red),
                            );
                          } else {
                            final stops = snapshot.data ?? [];
                            return Column(
                              children: [
                                for (var i = 0; i < stops.length; i++)
                                  ListTile(
                                    title: Text(
                                      'Parada ${i + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    onTap: () {
                                      final stopId = stops[i].split(' ')[1];
                                      final token = widget.token;
                                      final depotId = widget.depotId;
                                      setState(() {
                                        selectedRouteId = routeId;
                                      });
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StopDetailsPage(
                                            depotId: depotId.toString(),
                                            token: token,
                                            routeId: routeId,
                                            stopId:
                                                stopId, // Pasamos el stopId a la nueva página
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ListTile(
                                  title: const Text(
                                    'Mostrar Paradas De Ruta',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  onTap: () {
                                    final token = widget.token;
                                    final depotId = widget.depotId;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RouteDetailsPage(
                                          depotId: depotId.toString(),
                                          routeId: routeId,
                                          token: token,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          }
                        },
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

class StopDetailsPage extends StatefulWidget {
  // Variables para almacenar la información necesaria para la página
  final String depotId;
  final String routeId;
  final String token;
  final String stopId;

  // Constructor de la clase que recibe e inicializa las variables mencionadas anteriormente
  const StopDetailsPage({
    Key? key,
    required this.depotId,
    required this.routeId,
    required this.token,
    required this.stopId,
  }) : super(key: key);

  @override
  _StopDetailsPageState createState() => _StopDetailsPageState();
}

class _StopDetailsPageState extends State<StopDetailsPage> {
  late GoogleMapController mapController; // Controlador del mapa de Google
  Marker? stopMarker; // Marcador en el mapa para representar la parada
  final PolylinePoints polylinePoints = PolylinePoints(); // Puntos para una línea en el mapa
  MapType _currentMapType = MapType.normal; // Tipo de mapa actual (normal, satélite, terreno)
  List<dynamic> stops = []; // Lista que almacena las paradas
  Timer? timer; // Timer para ejecutar acciones periódicamente

  @override
  void initState() {
    super.initState();
    _checkInternetConnectivity(); // Verificar la conexión a internet
    fetchData(); // Traer datos de la API
    fetchStops2().then((_) {
      setState(() {});
    });
    startTimer(); // Iniciar el timer para actualizar datos
  }

  @override
  void dispose() {
    timer?.cancel(); // Cancelar el timer al destruir el widget
    super.dispose();
  }

  // Método para iniciar el timer que se ejecutará cada 5 segundos
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      fetchData();
    });
  }

  // Método para verificar la conexión a Internet y mostrar un diálogo en caso de no tener
  Future<void> _checkInternetConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
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

  // Método para traer datos específicos de la parada desde la API
  Future<void> fetchData() async {
    final apiUrl =
        'https://nimbus.wialon.com/api/depot/${widget.depotId}/route/${widget.routeId}';

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

      for (var station in st) {
        if (station['id'].toString() == widget.stopId) {
          if (station['p'].isEmpty) {
            continue;
          }
          List<PointLatLng> pointLatLng =
              polylinePoints.decodePolyline(station['p']);

          if (pointLatLng.isNotEmpty) {
            LatLng stationLocation =
                LatLng(pointLatLng.first.latitude, pointLatLng.first.longitude);

            final matchedStop = stops.firstWhere(
              (stop) => stop['id'].toString() == widget.stopId,
              orElse: () => null,
            );

            final stopName = matchedStop != null
                ? matchedStop['n']
                : 'Parada ${station['i']}';

            stopMarker = Marker(
              markerId: MarkerId(station['id'].toString()),
              position: stationLocation,
              infoWindow: InfoWindow(
                title: stopName,
                snippet: stationLocation.toString(),
              ),
            );
            setState(() {});
            break;
          }
        }
      }
    } else {
      throw Exception('Error al obtener los datos');
    }
  }

  // Método para traer una lista de paradas desde la API
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
      //print('Error: ${response.statusCode}');
      return [];
    }
  }

  // Método llamado cuando se crea el mapa
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Método para cambiar el tipo de mapa (normal, satélite, terreno)
  void _toggleMapType() {
    setState(() {
      if (_currentMapType == MapType.normal) {
        _currentMapType = MapType.satellite;
      } else if (_currentMapType == MapType.satellite) {
        _currentMapType = MapType.terrain;
      } else {
        _currentMapType = MapType.normal;
      }
    });
  }
  
  // Método para construir la interfaz de usuario de la página
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la Parada'),
        backgroundColor: Colors.grey[900],
      ),
      body: (stopMarker == null)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 20),
                  Image.asset('assets/nimbus.gif'),
                  const SizedBox(height: 20),
                  const Text('Cargando datos...'),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: stopMarker!.position,
                    zoom: 17,
                  ),
                  markers: {stopMarker!},
                  mapType: _currentMapType,
                  trafficEnabled: true,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: FloatingActionButton(
                      onPressed: _toggleMapType,
                      backgroundColor: Colors.white,
                      child: Icon(
                        _currentMapType == MapType.normal
                            ? Icons.map
                            : _currentMapType == MapType.satellite
                                ? Icons.satellite
                                : Icons.terrain,
                        color: Colors.deepPurple[900],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Este es un widget de página para mostrar detalles de una ruta específica.
class RouteDetailsPage extends StatefulWidget {
  // depotId representa el ID del depósito.
  // routeId representa el ID de la ruta.
  // token es probablemente un token de autorización para hacer solicitudes a la API.
  final String depotId;
  final String routeId;
  final String token;

  // Constructor de la clase que inicializa los valores requeridos.
  const RouteDetailsPage({
      Key? key,
      required this.depotId,
      required this.routeId,
      required this.token
  }) : super(key: key);

  // Creación del estado asociado para este widget.
  @override
  _RouteDetailsPageState createState() => _RouteDetailsPageState();
}

// Clase de estado asociado al widget RouteDetailsPage.
class _RouteDetailsPageState extends State<RouteDetailsPage> {
  // Controlador para el GoogleMap.
  late GoogleMapController mapController;
  // Mapa para guardar marcadores relacionados con las paradas.
  final Map<String, Marker> _markers = {};
  // Posición inicial en el mapa.
  LatLng? firstPosition;
  // Utilidad para decodificar puntos de polilíneas.
  final PolylinePoints polylinePoints = PolylinePoints();
  // Conjunto de polilíneas para representar la ruta en el mapa.
  Set<Polyline> _polylines = {};
  // Tipo de mapa actual (terreno, normal, satélite).
  MapType _currentMapType = MapType.terrain;
  // Lista para almacenar información de las paradas.
  List<dynamic> stops = [];

  // Método que se ejecuta cuando se crea el estado del widget.
  @override
  void initState() {
    super.initState();
    _checkInternetConnectivity(); // Comprueba la conectividad a Internet.
    // Obtiene los datos de las paradas y luego los detalles de la ruta.
    fetchStops2().then((_) {
      fetchData();
    });
  }

  // Método para verificar si el dispositivo está conectado a Internet.
  Future<void> _checkInternetConnectivity() async {
    // Comprueba la conectividad.
    var connectivityResult = await (Connectivity().checkConnectivity());
    // Si no hay conexión, muestra un cuadro de diálogo alertando al usuario.
    if (connectivityResult == ConnectivityResult.none) {
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

  // Método para obtener los datos de la ruta de la API.
  Future<void> fetchData() async {
    // Construye la URL de la API usando los datos proporcionados en el widget.
    final apiUrl =
        'https://nimbus.wialon.com/api/depot/${widget.depotId}/route/${widget.routeId}';

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

          final marker = Marker(
            markerId: MarkerId(station['id'].toString()),
            position: stationLocation,
            infoWindow: InfoWindow(
              title: stopName,
              snippet: stationLocation.toString(),
            ),
          );
          _markers[station['id'].toString()] = marker;
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
          color: Colors.yellowAccent,
          points: polylineCoordinates,
          width: 5,
        );

        setState(() {
          _polylines.add(polyline);
        });
      }
    } else {
      throw Exception('Error al obtener los datos');
    }
  }

  // Método para obtener información sobre las paradas de la API.
  Future<List<String>> fetchStops2() async {
    // Construye la URL de la API usando el depotId del widget.
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
      //print('Error: ${response.statusCode}');
      return [];
    }
  }

  // Método llamado cuando se crea el mapa.
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Método para alternar entre diferentes tipos de mapas.
  void _toggleMapType() {
    setState(() {
      // Cambia el tipo de mapa.
      if (_currentMapType == MapType.terrain) {
        _currentMapType = MapType.normal;
      } else if (_currentMapType == MapType.normal) {
        _currentMapType = MapType.satellite;
      } else {
        _currentMapType = MapType.terrain;
      }
    });
  }

  // Método de construcción para dibujar el widget en la pantalla.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la Ruta'),
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
                  const Text('Cargando datos...'),
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
                  markers: _markers.values.toSet(),
                  polylines: _polylines,
                  mapType: _currentMapType,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  trafficEnabled: true,
                ),
                Positioned(
                  right: 4,
                  top: 60, // Modifica estos valores para mover el botón
                  child: FloatingActionButton(
                    onPressed: _toggleMapType,
                    backgroundColor: Colors.white,
                    child: Icon(
                      _currentMapType == MapType.terrain
                          ? Icons.terrain
                          : _currentMapType == MapType.normal
                              ? Icons.map
                              : Icons.satellite,
                      color: Colors.deepPurple[900],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
