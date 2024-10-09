// ignore_for_file: library_private_types_in_public_api, unused_field, unused_local_variable

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParadasPage extends StatefulWidget {
  final String token;
  final int depotId;

  const ParadasPage({Key? key, required this.token, required this.depotId})
      : super(key: key);

  @override
  _ParadasPageState createState() => _ParadasPageState();
}

class _ParadasPageState extends State<ParadasPage> {
  // URLs de API
  final String _apiUrl = 'https://nimbus.wialon.com/api/depots';
  late String _apiUrl2;

  // Datos obtenidos de la API
  List<dynamic> _data = [];
  bool _isLoading = true;
  List<dynamic> _stops = [];
  bool _isLoading2 = true;

  // Mapas para contar tipos de paradas y sus datos relacionados
  final Map<int, int> _tpCountMap = {};
  int _totalTpCount = 0;
  Map<int, List<Map<String, dynamic>>> tpDataMap = {};

  // Inicialización
  @override
  void initState() {
    super.initState();
    _apiUrl2 = 'https://nimbus.wialon.com/api/depot/${widget.depotId}/stops';
    _fetchData();
    _fetchData2();
  }

  // Método para obtener datos de la API (_apiUrl)
  Future<void> _fetchData() async {
    final url = _apiUrl;
    final token = widget.token;

    if (url.isEmpty || token.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          _data = json['depots'];
          _isLoading = false;
        });
      }

      // Imprimir los datos obtenidos en la consola
      // print('Datos obtenidos:');
      // print(json);
    } else {
      throw Exception('Error al obtener datos: ${response.statusCode}');
    }
  }

  // Método para obtener datos de la API (_apiUrl2)
  Future<void> _fetchData2() async {
    final token = widget.token;

    final response = await http.get(
      Uri.parse(_apiUrl2),
      headers: {
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          if (json['stops'] != null) {
            _stops = json['stops'];
          }
          _isLoading2 = false;
          _updateTpCountMap();

          for (var stop in _stops) {
            int tp = stop['tp'];

            if (tpDataMap.containsKey(tp)) {
              tpDataMap[tp]!.add(stop);
            } else {
              tpDataMap[tp] = [stop];
            }
          }
        });
      }
      if (_stops.isNotEmpty) {
        for (var stop in _stops) {
          final position = stop['p'][0];
          final name = stop['n'];
          final tp = stop['tp'];
          final id = stop['id'];
          final tm = stop['tm'];
          final coordinates =
              '(${position['x']}, ${position['y']},${position['r']})';
        }
      } else {
        //print('No se encontraron paradas en la respuesta del servidor.');
      }
    } else {
      throw Exception('Error al obtener datos: ${response.statusCode}');
    }
  }

  // Actualizar el mapa de recuento de tipos de paradas
  void _updateTpCountMap() {
    _tpCountMap.clear();
    _totalTpCount = 0;

    for (final stop in _stops) {
      final tp = stop['tp'];
      if (tp != null && tp is int) {
        _tpCountMap[tp] = (_tpCountMap[tp] ?? 0) + 1;
        _totalTpCount++;
      }
    }

    _tpCountMap[0] = _totalTpCount;
  }

  // Obtener color según el tipo de parada
  Color getTrailingColor(int tp) {
    Color trailingColor;

    if (tp == 0) {
      trailingColor = Colors.blue;
    } else if (tp == 1) {
      trailingColor = const Color.fromARGB(255, 91, 174, 81);
    } else if (tp == 2) {
      trailingColor = const Color.fromARGB(255, 107, 11, 142);
    } else if (tp == 3) {
      trailingColor = const Color(0xFF7F65F1);
    } else if (tp == 4) {
      trailingColor = const Color(0xFFF06292);
    } else if (tp == 5) {
      trailingColor = const Color(0xFFFFAA00);
    } else {
      trailingColor = const Color.fromARGB(202, 236, 198, 8);
    }

    return trailingColor;
  }

  // Obtener widget de recuento para la lista
  Widget getTrailingWidget(int tp, int count) {
    Color trailingColor = getTrailingColor(tp);

    Widget trailingWidget;
    if (tp == 0) {
      trailingWidget = Container(
        decoration: BoxDecoration(
          color: trailingColor,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(8),
        child: Text(
          _totalTpCount.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    } else {
      trailingWidget = Container(
        decoration: BoxDecoration(
          color: trailingColor,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(8),
        child: Text(
          count.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return trailingWidget;
  }

  // Navegar a la siguiente página con datos relacionados
  void _navigateToNextPage(Map<String, dynamic> relatedData) {
    final tp = relatedData['tp'] as int;
    final count = relatedData['count'] as int;
//pasamos estos parametros que ocuparemos en la clase nextPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NextPage(
          tp: tp,
          count: count,
          token: widget.token,
          totalTpCount: _totalTpCount,
          depotId: widget.depotId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paradas'),
        backgroundColor: Colors.grey[900],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _data.length,
                    itemBuilder: (BuildContext context, int index) {
                      final item = _data[index];
                      final tpList = item['tp'] as List<dynamic>;

                      return ExpansionTile(
                        title: Text(
                          '${item['n']}',
                        ),
                        initiallyExpanded: true,
                        trailing: const IconTheme(
                          data: IconThemeData(color: Colors.transparent),
                          child: Icon(Icons.expand_more),
                        ),
                        children: tpList.map((tpItem) {
                          final tp = tpItem['f'];
                          final count = _tpCountMap[tp] ?? 0;
                          final name = tpItem['n'];
                          final id = tpItem['id'];
                          final tm = tpItem['tm'];
                          final coordinates = tpItem['p'] != null
                              ? '(${tpItem['p'][0]['x']}, ${tpItem['p'][0]['y']}, ${tpItem['p'][0]['r']})'
                              : 'Coordinates not available';

                          return ListTile(
                            title: Text(
                              name ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            trailing: getTrailingWidget(tp, count),
                            onTap: () {
                              final relatedData = {
                                'tp': tp,
                                'count': count,
                                'name': name ?? '',
                                'id': id ?? '',
                                'tm': tm ?? '',
                                'coordinates': coordinates,
                              };
                              _navigateToNextPage(relatedData);
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class NextPage extends StatefulWidget {
  final int tp;
  final int count;
  final String token;
  final int totalTpCount;
  final int depotId;

  const NextPage({
    Key? key,
    required this.tp,
    required this.count,
    required this.token,
    required this.totalTpCount,
    required this.depotId,
  }) : super(key: key);

  @override
  _NextPageState createState() => _NextPageState();
}

class _NextPageState extends State<NextPage> {
  // Datos obtenidos de la API
  List<dynamic> _stops = [];
  bool _isLoading = true;
  String _searchQuery = ''; // Consulta de búsqueda

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Obtener datos de la API
  Future<void> _fetchData() async {
    final token = widget.token;
    final apiUrl =
        'https://nimbus.wialon.com/api/depot/${widget.depotId}/stops';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (mounted) {
        setState(() {
          if (json['stops'] != null) {
            _stops = json['stops'];
          }
          _isLoading = false;
          _setMarkers();
        });
      }
    } else {
      throw Exception('Error al obtener datos: ${response.statusCode}');
    }
  }

  // Crear marcador personalizado
  Future<BitmapDescriptor> _createCustomMarkerBitmap(String iconPath) async {
    final ImageConfiguration imageConfiguration =
        createLocalImageConfiguration(context, size: const Size(1, 1));
    final BitmapDescriptor bitmapDescriptor =
        await BitmapDescriptor.fromAssetImage(imageConfiguration, iconPath);
    return bitmapDescriptor;
  }

  // Configurar marcadores en el mapa
  void _setMarkers() async {
    // Limpiar todos los marcadores existentes en el mapa
    _markers.clear();

    // Obtener el ícono personalizado del marcador basado en el tipo de parada seleccionado
    final customMarkerIcon =
        await _createCustomMarkerBitmap(_getMarkerIconPath(widget.tp));

    // Iterar a través de todas las paradas para agregar marcadores al mapa
    for (var stop in _stops) {
      // Obtener las coordenadas de la parada
      final coordinates = LatLng(stop['p'][0]['y'], stop['p'][0]['x']);

      // Crear un marcador con la información correspondiente
      final marker = Marker(
        markerId:
            MarkerId(stop['id'].toString()), // Identificador único del marcador
        position: coordinates, // Posición en el mapa
        icon: customMarkerIcon, // Ícono personalizado del marcador
        infoWindow:
            InfoWindow(title: stop['n']), // Ventana emergente de información
      );

      // Agregar el marcador al conjunto de marcadores del mapa
      _markers.add(marker);
    }
  }

  // Obtener la ruta del ícono del marcador según el tipo de parada
  String _getMarkerIconPath(int tp) {
    switch (tp) {
      case 0:
        return 'assets/azul.png';
      case 1:
        return 'assets/verde.png';
      case 2:
        return 'assets/morado.png';
      case 4:
        return 'assets/rosa.png';
      default:
        return 'assets/amarillo.png';
    }
  }

  // Ir a la ubicación de una parada en el mapa
  void _goToStopLocation(double lat, double lng) {
    final newPosition = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 24.0,
    );

    _mapController?.animateCamera(CameraUpdate.newCameraPosition(newPosition));
  }

  // Cambiar el tipo de mapa
  void _changeMapType(MapType mapType) {
    setState(() {
      _mapType = mapType;
    });
  }

  // Mostrar un menú para seleccionar el tipo de mapa
  void _showMapTypeMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Estándar'),
              onTap: () {
                _changeMapType(MapType.normal);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.satellite),
              title: const Text('Satélite'),
              onTap: () {
                _changeMapType(MapType.satellite);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.terrain),
              title: const Text('Relieve'),
              onTap: () {
                _changeMapType(MapType.terrain);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Tipo de mapa predeterminado
  MapType _mapType = MapType.normal;

  Color getTrailingColor(int tp) {
    Color trailingColor;

    // Esta función toma un entero "tp" como parámetro, que representa el tipo de parada.

    if (tp == 0) {
      trailingColor =
          Colors.blue; // Si el tipo de parada es 0, el color es azul (DEFAULT).
    } else if (tp == 1) {
      trailingColor = const Color.fromARGB(255, 91, 174, 81); // Color verde.
    } else if (tp == 2) {
      trailingColor = const Color.fromARGB(255, 107, 11, 142); // Color morado.
    } else if (tp == 3) {
      trailingColor = const Color(0xFF7F65F1); // Color personalizado.
    } else if (tp == 4) {
      trailingColor = const Color(0xFFF06292); // Color personalizado.
    } else if (tp == 5) {
      trailingColor = const Color(0xFFFFAA00); // Color personalizado.
    } else {
      trailingColor =
          const Color.fromARGB(202, 236, 198, 8); // Color amarillo por defecto.
    }

    // Esta función devuelve un color que será utilizado en la interfaz de usuario.
    return trailingColor;
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar las paradas en base al tipo seleccionado y la búsqueda
    final filteredStops = _stops
        .where((stop) =>
            (widget.tp == 0 ||
                stop['tp'] == widget.tp) && // Filtro por tipo de parada
            (stop['n'] as String)
                .toLowerCase()
                .contains(_searchQuery)) // Filtro por búsqueda
        .toList();

    // Construir la interfaz de usuario utilizando el Scaffold
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de las Paradas'),
        backgroundColor: Colors.grey[
            900], // Establecer el color de fondo de la AppBar (gris oscuro)
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator()) // Mostrar un indicador de carga si es necesario
          : filteredStops.isEmpty
              ? const Center(
                  child: Text(
                      'No se encontraron paradas :c'), // Mostrar mensaje si no hay paradas filtradas
                )
              : Column(
                  children: [
                    Expanded(
                      child: GoogleMap(
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        markers: _markers,
                        mapType: _mapType,
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                              filteredStops[0]['p'][0]['y'],
                              filteredStops[0]['p'][0][
                                  'x']), // Establecer la posición inicial del mapa
                          zoom:
                              12.0, // Establecer el nivel de zoom inicial del mapa
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value
                                .toLowerCase(); // Actualizar la búsqueda al escribir
                          });
                        },
                        style: const TextStyle(
                            color: Colors
                                .white), // Estilo del texto ingresado (blanco)
                        decoration: const InputDecoration(
                          labelText:
                              'Buscar Parada', // Etiqueta del campo de búsqueda
                          labelStyle: TextStyle(
                              color: Colors
                                  .white), // Estilo de la etiqueta (blanco)
                          prefixIcon: Icon(Icons.search,
                              color:
                                  Colors.white), // Icono de búsqueda (blanco)
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors
                                    .black), // Borde del campo de búsqueda
                          ),
                          filled: true,
                          fillColor: Colors
                              .green, // Color de fondo del campo de búsqueda (verde)
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors
                                    .white), // Borde cuando el campo está enfocado (blanco)
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredStops.length,
                        itemBuilder: (context, index) {
                          final stop = filteredStops[index];
                          final name = stop['n'];
                          final tp = stop['tp'];

                          // Construir una tarjeta con detalles de la parada
                          return Card(
                            color: Colors.grey[
                                900], // Color de fondo de la tarjeta (gris oscuro)
                            elevation: 2.0,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: tp == 0
                                    ? Colors
                                        .blue // Cambiar el color para tipo de parada 0 (azul)
                                    : getTrailingColor(tp),
                                child: const Icon(
                                  Icons.directions_bus,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                    color: Colors
                                        .white), // Color del texto del título (blanco)
                              ),
                              onTap: () {
                                final lat = stop['p'][0]['y'];
                                final lng = stop['p'][0]['x'];
                                _goToStopLocation(lat,
                                    lng); // Ir a la ubicación de la parada en el mapa
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showMapTypeMenu(
              context); // Mostrar el menú de tipos de mapa al hacer clic en el botón flotante
        },
        child: const Icon(Icons.map), // Icono del botón flotante
      ),
    );
  }
}
