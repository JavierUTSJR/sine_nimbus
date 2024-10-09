// ignore_for_file: unnecessary_null_comparison, unnecessary_string_interpolations, unused_field, prefer_final_fields, library_private_types_in_public_api, 
// ignore_for_file: use_build_context_synchronously, unused_local_variable, no_leading_underscores_for_local_identifiers, depend_on_referenced_packages
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'maparide_page.dart';

class UserParametersPage extends StatefulWidget {
  final String token;
  final int? depotId;

  const UserParametersPage({required this.token, this.depotId, Key? key})
      : super(key: key);

  @override
  _UserParametersPageState createState() => _UserParametersPageState();
}

class _UserParametersPageState extends State<UserParametersPage> {
  TextEditingController adelantamientoController = TextEditingController();
  TextEditingController atrasoController = TextEditingController();
  TextEditingController actualidadController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    adelantamientoController.dispose();
    atrasoController.dispose();
    actualidadController.dispose();
    super.dispose();
  }

  void _submitForm() {
    final adelantamiento = adelantamientoController.text;
    final atraso = atrasoController.text;
    final actualidad = actualidadController.text;

    if (adelantamiento.isNotEmpty &&
        double.tryParse(adelantamiento) != null &&
        atraso.isNotEmpty &&
        double.tryParse(atraso) != null &&
        actualidad.isNotEmpty &&
        double.tryParse(actualidad) != null) {
      setState(() {
        _isLoading = true;
      });

      // Simulación de envío de datos (reemplaza con tu lógica de envío real)
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeguiPage(
              token: widget.token,
              depotId: widget.depotId ?? 0,
              adelantamiento: adelantamiento,
              atraso: atraso,
              actualidad: actualidad,
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('❌Error❌'),
          content:
              const Text('Por favor, ingresa números válidos en los campos.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('🔧 Parámetros del usuario ⚙️'),
          backgroundColor: const Color(0xFF42A5F5)),
      body: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seguimiento',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Mientras seguir rutinas en tiempo real las unidades que van con adelantamiento del horario se seleccionan de amarillo y los que van con atraso de rojo. Si desviación es insignificatva, la unidad se selecciona de gris para que no atraiga atención adicional. Abajo se puede indicar los grados de adelantamiento y de atraso a seleccionarse de color',
                ),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: adelantamientoController,
                    decoration: InputDecoration(
                      labelText: 'Adelantamiento, min',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: atrasoController,
                    decoration: InputDecoration(
                      labelText: 'Atraso, min',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Las descripciones emergentes contienen información sobre el último mensaje recibido. Si el indicador y la hora de recibir el mensaje son de color verde, los datos son actuales: si de color gris, no. Abajo se puede indicar el periodo de tiempo al expirar el cual los datos deben considerarse no actuales.',
                ),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: actualidadController,
                    decoration: InputDecoration(
                      labelText: 'Actualidad de datos, min',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color(0xFF42A5F5)),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    shape: MaterialStateProperty.all<OutlinedBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24.0,
                          height: 24.0,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3.0,
                          ),
                        )
                      : const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SeguiPage extends StatefulWidget {
  final String token;
  final int depotId;
  final String adelantamiento;
  final String atraso;
  final String actualidad;

  const SeguiPage({
    Key? key,
    required this.token,
    required this.depotId,
    required this.adelantamiento,
    required this.atraso,
    required this.actualidad,
  }) : super(key: key);

  get at => null;

  @override
  _SeguiPageState createState() => _SeguiPageState();
}

class _SeguiPageState extends State<SeguiPage> {
  final String _apiUrl = 'https://nimbus.wialon.com/api/depot';
  Timer? _timer;
  double _scrollOffset = 0.0;
  ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _rides = [];
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _stops = [];
  List<dynamic> unitDetails = [];
  List<Map<String, dynamic>> filteredRoutes = [];
  List<Map<String, dynamic>> stopDataList = [];
  // Define el Map para almacenar los colores asociados con circleId
  List<Color> coloresAsignados = [];
  //alerta sin datos:
  bool _noStopsFound = false;

  get ride => null;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _checkInternetConnectivity();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchRidesData();
      _fetchRoutesData();
      _fetchStopsData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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

  Future<void> _fetchRidesData() async {
    final url = '$_apiUrl/${widget.depotId}/rides';
    final token = widget.token;

    if (url.isEmpty || token.isEmpty) {
      return;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (mounted) {
        if (json['rides'] != null) {
          List<Map<String, dynamic>> newRides =
              List<Map<String, dynamic>>.from(json['rides']);
          if (!listEquals(_rides, newRides)) {
            setState(() {
              _rides = newRides;
            });
          }
        }
      }
      //print('Datos obtenidos:');
      if (_rides.isNotEmpty) {
        for (var ride in _rides) {
          final tid = ride['tid'];
          final idR = ride['id'];
          final tmR = ride['tm'];
          final dR = ride['d'];
          final aR = ride['a'];
          final u = ride['u'];
          final f = ride['f'];
          final i = ride['i'];
          final si = ride['si'];
          final pt = ride['pt'];
          final at = ride['at'];
          //fetchUnitDetails();

          // print('tid: $tid');
          // print('idR: $idR');
          // print('tmR: $tmR');
          // print('dR: $dR');
          // print('aR: $aR');
          // print('u: $u');
          // print('f: $f');
          // print('i: $i');
          // print('si: $si');
          // print('pt: $pt');
          // print('at: $at');
          // print('---');
        }
      } else {
        //print('No se encontraron paradas en la respuesta del servidor.');
      }
    } else {
      throw Exception('Error al obtener datos: ${response.statusCode}');
    }
  }

  Future<void> _fetchRoutesData() async {
    final url = '$_apiUrl/${widget.depotId}/routes';
    final token = widget.token;

    if (url.isEmpty || token.isEmpty) {
      return;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (mounted) {
        if (json['routes'] != null) {
          List<Map<String, dynamic>> newRoutes =
              List<Map<String, dynamic>>.from(json['routes']);
          // Actualiza el estado solo si los datos son diferentes
          if (!listEquals(_routes, newRoutes)) {
            setState(() {
              _routes = newRoutes;
            });
          }
        }
      }
    } else {
      throw Exception('Error al obtener datos: ${response.statusCode}');
    }
  }

  Future<void> _fetchStopsData() async {
    final url = 'https://nimbus.wialon.com/api/depot/${widget.depotId}/stops';

    final token = widget.token;

    if (url.isEmpty || token.isEmpty) {
      return;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': token,
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (mounted) {
        if (json['stops'] != null) {
          List<Map<String, dynamic>> newStops =
              List<Map<String, dynamic>>.from(json['stops']);
          // Actualiza el estado solo si los datos son diferentes
          if (!listEquals(_stops, newStops)) {
            setState(() {
              _stops = newStops;
            });
          }
        }
      }
      //print('Datos obtenidos:');
      if (_stops.isNotEmpty) {
        for (var stop in _stops) {
          final name = stop['n'];
          final id = stop['id'];
          //print('Nombre de parada: $name');
          //print('Adelantamiento: ${widget.adelantamiento}');
          //print('Atraso: ${widget.atraso}');
        }
      } else {
        setState(() {
          _noStopsFound = true;
        });
      }
    } else {
      throw Exception('Error al obtener datos: ${response.statusCode}');
    }
  }

  //Nombre de la unidad
  Future<String> fetchUnitDetails(String rideU) async {
    final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (rideU != null) {
      final String apiUrl =
          'https://nimbus.wialon.com/api/depot/${widget.depotId}/report/avl_unit/$rideU?flags=1&df=$currentDate&dt=$currentDate&sort=timetable';

      final reportResponse = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'accept': 'application/json',
          'Authorization': widget.token,
        },
      );

      //print('segunda api: $apiUrl');

      if (reportResponse.statusCode == 200) {
        final unitData = json.decode(reportResponse.body);

        //print('Respuesta de la API: $unitData');

        final n = unitData['params']['n'];
        //print('Valor de n: $n');

        if (unitData != null &&
            unitData['params'] != null &&
            unitData['params']['obj_name'] != null &&
            unitData['params']['obj_name'].isNotEmpty) {
          final objName = unitData['params']['obj_name'];
          final nValue = unitData['n'];
          // print('Valor de obj_name: $objName');
          // print('Valor de n: $nValue');

          setState(() {
            final existingUnit = unitDetails.firstWhere(
                (unit) => unit['id'] == unitData['params']['id'],
                orElse: () => null);
            if (existingUnit == null) {
              unitDetails.add(unitData['params']);
            }
          });
          return objName;
        }
      }
    }

    // Si no se encuentra el valor obj_name, puedes retornar un valor alternativo o lanzar una excepción.
    // Aquí se retorna una cadena de texto vacía como ejemplo.
    return '';
  }

  //alertas

  String timeZone = 'America/Mexico_City';
  int ptIndex = 0;
  int atIndex = 0;
  String? nToShow;
  String searchText = '';
  String value = '';
  String objName = '';
  String? currentRideId;
  String? latestRideU;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double itemWidth = 100.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento'),
        backgroundColor: Colors.grey[900],
      ),
      body: ListView.builder(
        itemCount: _rides.length +
            1, // Agrega uno al itemCount para incluir el buscador
        itemBuilder: (context, index) {
          if (index == 0) {
            // Este será el buscador, ya que está en el primer índice (0)
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 22, 21, 21).withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar',
                    hintStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.normal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20.0),
                  ),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  onChanged: (text) {
                    setState(() {
                      value =
                          text; // Asignar el valor del TextField a la variable value
                    });
                  },
                ),
              ),
            );
          } else {
            final rideIndex = index -
                1; // Resta uno al índice para tener en cuenta el buscador en el primer índice
            final ride = _rides[rideIndex];

            final tid = ride['tid'];
            final idR = ride['id'];
            final tmR = ride['tm'];
            final dR = ride['d'];
            final aR = ride['a'];
            final u = ride['u'];
            final f = ride['f'];
            final i = ride['i'];
            final si = ride['si'];
            final pt = ride['pt'];
            final at = ride['at'];

            final matchingRoutes = _routes.where((route) {
              final st = route != null ? route['st'] : null;
              final tt = route['tt'] as List<dynamic>?;

              return tt != null && tt.any((element) => element['id'] == tid);
            }).toList();

            // Declarar las variables de las paradas inicial y final
            String? paradaInicial;
            String? paradaFinal;
            final int adelantoMinutos = int.parse(widget.adelantamiento);
            final int atrasoMinutos = int.parse(widget.atraso);

            // Asignar las paradas inicial y final según tus condiciones
            if (matchingRoutes.isNotEmpty) {
              final route = matchingRoutes[0];
              final st = route['st'];

              if (st != null && st.isNotEmpty) {
                paradaInicial = _stops
                    .firstWhere((stop) => stop['id'] == st.first['id'])['n'];
                paradaFinal = _stops
                    .firstWhere((stop) => stop['id'] == st.last['id'])['n'];

                int lastIndex = at.lastIndexWhere((item) => item != null);
                if (lastIndex >= 0) {
                  // Asegurarse de que el controlador tenga adjuntada una vista
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollController.animateTo(
                      lastIndex *
                          50.0, // Ajusta este valor según el ancho del elemento
                      duration: const Duration(
                          milliseconds:
                              1000), // Ajusta la duración según tus preferencias
                      curve: Curves
                          .easeInOut, // Ajusta la curva según tus preferencias
                    );
                  });
                }
              }
            }

            filteredRoutes = matchingRoutes.where((route) {
              final String routeName = route['n'].toString().toLowerCase();
              final String searchText =
                  value.toLowerCase(); // El valor de búsqueda del TextField

              return routeName.contains(searchText);
            }).toList();

            String _formatDuration(Duration duration) {
              String twoDigits(int n) {
                if (n >= 10) return "$n";
                return "0$n";
              }

              //cards filtro
              List filteredRoutes = matchingRoutes.where((route) {
                final routeName = route['n'].toString().toLowerCase();
                final searchQuery = searchText.toLowerCase();
                return routeName.contains(searchQuery);
              }).toList();

              String twoDigitHours = twoDigits(duration.inHours);
              String twoDigitMinutes =
                  twoDigits(duration.inMinutes.remainder(60));
              String twoDigitSeconds =
                  twoDigits(duration.inSeconds.remainder(60));

              return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
            }

            String getEventType(int tp) {
              switch (tp) {
                case 1:
                  return '--⏱️Iniciado⏱️--';
                case 2:
                  return 'Finalizado';
                case 4:
                  return 'Creado manualmente';
                case 8:
                  return 'Actualizado';
                case 16:
                  return 'Eliminado';
                case 32:
                  return 'Detener ingreso';
                case 64:
                  return 'Dentro';
                case 128:
                  return 'Salida detenida';
                case 256:
                  return 'Omitir';
                case 513:
                  return 'Reasignar unidad en el viaje activo';
                case 514:
                  return 'Viaje detenido manualmente';
                case 1024:
                  return 'Unidad incorrecta';
                case 2048:
                  return 'Abandonar ruta';
                default:
                  return 'Desconocido';
              }
            }

            const timeZone = 'America/Mexico_City';

            final screenWidth = MediaQuery.of(context).size.width;

            for (var i = 0; i < _stops.length; i++) {
              if (i < pt.length && i < at.length) final atIcon = at[i];
            }

            int currentIndex = 0;

// Función para encontrar el siguiente índice con un valor no nulo en 'at'.
            // Ajustar el desplazamiento del SingleChildScrollView al último elemento válido en 'at'

            return Container(
              alignment: Alignment.topCenter,
              // esto colocará las cards en la parte superior de la pantalla
              child: Column(
                children: [
                  if (filteredRoutes.isNotEmpty)
                    Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.grey, width: 1.0),
                      ),
                      child: ListTile(
                        leading: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors
                                .green, // Establece el color verde para el círculo
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors
                                .transparent, // Hace que el fondo del círculo sea transparente
                            child: IconButton(
                              icon: const Icon(
                                Icons.directions_bus,
                                color: Colors
                                    .white, // Cambia el color del icono a blanco
                              ),
                              onPressed: () async {
                                if (ride != null && ride['u'] != null) {
                                  // print('Valor de ride: $ride');
                                  // print('Valor de ride[\'u\']: ${ride['u']}');
                                  String rideU = ride['u'].toString();
                                  objName = await fetchUnitDetails(rideU);
                                  // Actualiza el widget para mostrar el nuevo valor
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      int tp = matchingRoutes[0]['tp'];
                                      String eventType = getEventType(tp);

                                      return AlertDialog(
                                        title: const Text(
                                            ' 🚥 Información de la ruta 🚥'),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 20.0,
                                                vertical: 10.0),
                                        content: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${matchingRoutes[0]['n']}',
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 10.0),
                                            Text(
                                              'Tipo de evento: $eventType',
                                              style: const TextStyle(
                                                color: Colors
                                                    .blue, // Cambia el color del texto a rojo
                                              ),
                                            ),
                                            const SizedBox(height: 15),

                                            /*
                                            Text(
                                              '${ride['u'] ?? 'Unidades no disponibles'}',
                                              style: const TextStyle(
                                                // Estilo para el valor de "U de rides"
                                                fontSize: 14,
                                              ),
                                            ),*/

                                            GestureDetector(
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.directions_bus,
                                                    // Ajusta el tamaño y el color del ícono según tus necesidades
                                                    size: 24,
                                                    color: Colors.green,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text('$objName'),
                                                  // Espacio adicional entre el ícono y el texto
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Cerrar'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        title: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    // Agrega el icono de la cama si at no contiene datos
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 2.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '  ${matchingRoutes[0]['n']}',
                                            style: const TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    // Mostrar alerta
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return AlertDialog(
                                                          title: const Text(
                                                              '🚨 Alerta 🚨'),
                                                          content: const Text(
                                                            '¡Sin Salir a la Rutina!',
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              child: const Text(
                                                                  'Aceptar'),
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  },
                                                  child: at != null &&
                                                          at.any((element) =>
                                                              element != null)
                                                      ? const SizedBox
                                                          .shrink() // No mostrar ningún icono
                                                      : const Icon(
                                                          Icons
                                                              .bedroom_child_rounded,
                                                          color: Colors.red,
                                                        ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    // Mostrar alerta
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return AlertDialog(
                                                          title: const Text(
                                                              '🥶¡Sin Unidad Asignada!🥶'),
                                                          actions: [
                                                            TextButton(
                                                              child: const Text(
                                                                  'Aceptar'),
                                                              onPressed: () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  },
                                                  child: u != null
                                                      ? const SizedBox
                                                          .shrink() // No mostrar ningún icono
                                                      : const Icon(
                                                          Icons.bus_alert,
                                                          color: Colors.blue,
                                                        ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                paradaInicial ?? '',
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              const Text(
                                '-',
                                style: TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                paradaFinal ?? '',
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              GestureDetector(
                                onTap: () {
                                  // Navigate to the new page passing data (matchingRoutes[0]['n']) to the next page
                                  //print('list: $coloresAsignados');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MapaRidePage(
                                          data: matchingRoutes[0]['id'],
                                          token: widget.token,
                                          depotId: widget.depotId,
                                          adelantamiento: widget.adelantamiento,
                                          atraso: widget.atraso,
                                          stopDataList: stopDataList,
                                          coloresAsignados: coloresAsignados),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.location_on,
                                  size: 28, // Tamaño del icono
                                  color: Colors.green, // Color del icono
                                ),
                              ),
                            ],
                          ),
                        ),
                        subtitle: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (var i = 0; i < _stops.length; i++)
                                if (i < pt.length && i < at.length)
                                  InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          final ptValue = pt[i];
                                          final atValue = at[i];

                                          final diff = (ptValue != null &&
                                                  atValue != null)
                                              ? ptValue - atValue
                                              : null;

                                          final atraso = (ptValue != null &&
                                                  atValue != null &&
                                                  atValue > ptValue)
                                              ? atValue - ptValue
                                              : null;

                                          final stIds = matchingRoutes
                                              .where((route) =>
                                                  route.containsKey('st'))
                                              .map((route) => route['st']
                                                  .map((st) => st['id'])
                                                  .toList())
                                              .expand((ids) => ids)
                                              .toList();

                                          final circleId = (i < stIds.length)
                                              ? stIds[i]
                                              : null;

                                          //print('pau: $stopDataList');
                                          final stop = _stops.firstWhere(
                                            (stop) => stop['id'] == circleId,
                                          );
                                          final stopName = (stop != null)
                                              ? stop['n']
                                              : 'No data';

                                          //print('Valor de diff: $circleColors');
                                          // Almacena los datos de la parada en la lista como un mapa
                                          stopDataList.add({
                                            "id": stIds,
                                            "at": at,
                                            "pt": pt
                                          });

                                          //print('Valor de diff: $coloresAsignados');

                                          for (int i = 0; i < pt.length; i++) {
                                            final ptValue = pt[i];
                                            final atValue = at[i];
                                            Color colorAsignado;

                                            if (ptValue != null &&
                                                atValue != null) {
                                              if (atValue >
                                                  ptValue +
                                                      (atrasoMinutos * 60)) {
                                                colorAsignado = Colors.red;
                                              } else if ((ptValue - atValue)
                                                      .abs() >
                                                  adelantoMinutos * 60) {
                                                colorAsignado = Colors.yellow;
                                              } else {
                                                colorAsignado = Colors.grey;
                                              }
                                            } else if (atValue != null) {
                                              colorAsignado = Colors.grey;
                                            } else {
                                              colorAsignado =
                                                  const Color.fromRGBO(
                                                      0, 0, 0, 0);
                                            }

                                            coloresAsignados.add(colorAsignado);
                                          }

                                          return AlertDialog(
                                            title: Text(
                                              '-🚍 Parada : $stopName 🚍-',
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                              ),
                                            ),

                                            contentPadding: const EdgeInsets
                                                    .symmetric(
                                                horizontal: 20.0,
                                                vertical:
                                                    10.0), // Ajusta el tamaño de la alerta aquí
                                            content: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              // Ajusta el tamaño de la columna
                                              children: [
                                                const SizedBox(height: 12),
                                                Text(
                                                    '🕛PT: ${ptValue != null ? DateFormat.Hms().format(DateTime.fromMillisecondsSinceEpoch(ptValue * 1000 - 3600 * 1000)) : ''}'),
                                                const SizedBox(height: 15.0),
                                                Text(
                                                    '🕓AT: ${atValue != null ? DateFormat.Hms().format(DateTime.fromMillisecondsSinceEpoch(atValue * 1000 - 3600 * 1000)) : ''}'),
                                                const SizedBox(height: 15.0),
                                                if ((pt[i] != null &&
                                                        at[i] != null) &&
                                                    at[i] >
                                                        pt[i] +
                                                            (atrasoMinutos *
                                                                60) &&
                                                    at[i] != null &&
                                                    at[i] != Colors.grey)
                                                  Text(
                                                    '🚩Atraso: ${atraso != null ? _formatDuration(Duration(seconds: atraso)) : ''}',
                                                    style: const TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                if (((pt[i] != null &&
                                                            at[i] != null) &&
                                                        (pt[i] - at[i]).abs() >
                                                            adelantoMinutos *
                                                                60) &&
                                                    (at[i] != null &&
                                                        at[i] != Colors.grey) &&
                                                    !(at[i] >
                                                        pt[i] +
                                                            (atrasoMinutos *
                                                                60)))
                                                  Text(
                                                    '🌠Adelantamiento: ${diff != null ? _formatDuration(Duration(seconds: diff)) : ''}',
                                                    style: const TextStyle(
                                                        color: Color.fromARGB(
                                                            255, 190, 172, 4)),
                                                  ),
                                                if (((pt[i] != null &&
                                                            at[i] != null) &&
                                                        (pt[i] - at[i]).abs() <=
                                                            adelantoMinutos *
                                                                60) &&
                                                    (at[i] != null &&
                                                        at[i] != Colors.grey) &&
                                                    !(at[i] >
                                                        pt[i] +
                                                            (atrasoMinutos *
                                                                60)))
                                                  Text(
                                                    'Tolerancia: ${diff != null ? _formatDuration(Duration(seconds: diff)) : ''}',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                              ],
                                            ),

                                            actions: [
                                              TextButton(
                                                child: const Text('Cerrar'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              )
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: Column(
                                      children: [
                                        const Text(""),
                                        // Text(
                                        Text(
                                          '${i + 1}',
                                          style:
                                              const TextStyle(fontSize: 10.0),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          width: 16.0,
                                          height: 16.0,
                                          decoration: BoxDecoration(
                                            color: (pt[i] != null &&
                                                    at[i] != null)
                                                ? at[i] >
                                                        pt[i] +
                                                            (atrasoMinutos * 60)
                                                    ? Colors.red
                                                    : (pt[i] - at[i]).abs() >
                                                            adelantoMinutos * 60
                                                        ? Colors.yellow
                                                        : Colors.grey
                                                : at[i] != null
                                                    ? Colors.grey
                                                    : const Color.fromRGBO(
                                                        0,
                                                        0,
                                                        0,
                                                        0), // Usar transparente si no hay datos (null) o gris si no hay asignación específica
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 1.0,
                                              style: BorderStyle.solid,
                                            ),
                                          ),
                                          child: Icon(
                                            at[i] != null
                                                ? Icons.directions_bus
                                                : null,
                                            size: 14.0,
                                            color: at
                                                        .where((item) =>
                                                            item != null)
                                                        .toList()
                                                        .isNotEmpty &&
                                                    at
                                                            .where((item) =>
                                                                item != null)
                                                            .toList()
                                                            .last ==
                                                        at[i]
                                                ? Colors.black
                                                : Colors.transparent,
                                          ),
                                        ),

                                        const Text(""),
                                      ],
                                    ),
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
        },
      ),
    );
  }
}
