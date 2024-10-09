// Ignora ciertas reglas de lint
// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, unused_local_variable, depend_on_referenced_packages
// Importar las bibliotecas necesarias
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'cards_page.dart';  // Importación de una página relacionada con tarjetas

// Definición de la pantalla de selección
class SelectionScreen extends StatelessWidget {
  final int depotId;  // Identificador del depósito
  final String token;  // Token para autenticación

  // Constructor de la clase
  const SelectionScreen({
    Key? key,
    required this.depotId,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtén el alto de la pantalla
    double screenHeight = MediaQuery.of(context).size.height;

    // Define la separación entre las tarjetas como una fracción del alto de la pantalla
    double separation = screenHeight * 0.09; // 5% del alto de la pantalla
    return Scaffold(
      // Barra de aplicación
      appBar: AppBar(
        title: const Text('Informes'),
        backgroundColor: Colors.grey[900],
      ),
      // Cuerpo de la aplicación
      body: Padding(
        padding: const EdgeInsets.all(43.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildCard(
                context,
                'Informes de Ruta',
                Icons.route,
                Colors.blue,
                ReportRoutePage(depotId: depotId, token: token),
              ),
              SizedBox(height: separation),  // <-- Separación proporcional
              buildCard(
                context,
                'Informes de Unidad',
                Icons.time_to_leave,
                Colors.orange,
                ReportUnitPage(depotId: depotId, token: token),
              ),
              SizedBox(height: separation),  // <-- Separación proporcional
              buildCard(
                context,
                'Informes de Grupos de Rutas',
                Icons.commute,
                Colors.green,
                ReportGroupPage(depotId: depotId, token: token),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Función para construir tarjetas con información
  Card buildCard(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    Widget page,
  ) {
    // Obtén el tamaño de la pantalla actual
    double screenWidth = MediaQuery.of(context).size.width;

    // Ajusta el tamaño del icono, padding y tamaño de fuente en función del tamaño de la pantalla
    double iconSize = screenWidth < 500 ? 60 : 80;
    double paddingValue = screenWidth < 500 ? 15 : 30;
    double fontSizeValue = screenWidth < 500 ? 18 : 24;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50.0),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => page,
              transitionDuration: const Duration(seconds: 1),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                var begin = const Offset(0.5, 0.0);
                var end = Offset.zero;
                var curve = Curves.easeOut;

                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(paddingValue),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: color),
              const SizedBox(height: 16),
              Text(
                text,
                textAlign: TextAlign.center, // Centra el texto
                maxLines: 2, // Limita el número de líneas
                overflow: TextOverflow.ellipsis, // Añade puntos suspensivos si el texto se desborda
                style: TextStyle(
                  fontSize: fontSizeValue, // Ajusta el tamaño de fuente según el tamaño de pantalla
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Define una página que muestra reportes de ruta.
class ReportRoutePage extends StatefulWidget {
  final int depotId; // Identificador del depósito.
  final String token; // Token de autenticación.

  // Constructor del widget que toma un identificador de depósito y un token como parámetros.
  const ReportRoutePage({Key? key, required this.depotId, required this.token})
      : super(key: key);

  @override
  // Crea el estado asociado con el widget.
  _ReportRoutePageState createState() => _ReportRoutePageState();
}

class _ReportRoutePageState extends State<ReportRoutePage> {
  List<dynamic> rows = [];  // Almacena las filas del informe.
  String routeName = '';  // Almacena el nombre de la ruta.
  Map<String, dynamic> total = {};  // Almacena el total del informe.
  List<dynamic> unitOptions = [];  // Almacena las opciones de unidades disponibles.
  dynamic selectedUnit;  // Unidad seleccionada actualmente.
  DateTime? fromDate;  // Fecha de inicio para filtrar los informes.
  DateTime? toDate;    // Fecha final para filtrar los informes.

  @override
  void initState() {
    super.initState();
    // Comprueba la conectividad a Internet y busca opciones de unidades al inicializar el widget.
    _checkInternetConnectivity();
    fetchUnitOptions();
  }

  // Método para buscar opciones de unidades disponibles.
  Future<void> fetchUnitOptions() async {
    // Construye la URL de la API para obtener las rutas del depósito.
    final depotApiUrl =
        'https://nimbus.wialon.com/api/depot/${widget.depotId}/routes';

    // Realiza una solicitud GET a la API.
    final depotResponse = await http.get(
      Uri.parse(depotApiUrl),
      headers: {
        'accept': 'application/json',
        'Authorization': widget.token,
      },
    );

    if (depotResponse.statusCode == 200) {
      final depotData = json.decode(depotResponse.body);
      setState(() {
        unitOptions = depotData['routes'] ?? [];
      });

      if (unitOptions.isNotEmpty) {
        final selectedUnit = unitOptions.first;
        // Obtiene los datos del informe para la primera unidad por defecto.
        fetchReportData(selectedUnit['id']);
      }
    }
  }

  // Método para obtener los datos del informe.
  Future<void> fetchReportData(int routeId,
      [DateTime? fromDate, DateTime? toDate]) async {
    final String formattedFromDate =
        fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate) : '';
    final String formattedToDate =
        toDate != null ? DateFormat('yyyy-MM-dd').format(toDate) : '';

    // Construye la URL de la API para obtener el informe de la ruta.
    final String apiUrl =
        'https://nimbus.wialon.com/api/depot/${widget.depotId}/report/route/$routeId?flags=1&df=$formattedFromDate&dt=$formattedToDate&sort=timetable';

    // Realiza una solicitud GET a la API.
    final reportResponse = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'accept': 'application/json',
        'Authorization': widget.token,
      },
    );

    if (reportResponse.statusCode == 200) {
      final reportData = json.decode(reportResponse.body);
      final allRows = obtenerTodasLasRows(reportData);
      // Actualiza el estado con los datos del informe.
      setState(() {
        rows = allRows;
        routeName = reportData['n'];
        total = reportData['total'] ?? {};
        selectedUnit = routeId;
      });
    }
  }

  // Método para generar filas de la tabla a partir de datos.
  List<DataRow> generateTableRows() {
    // El código que convierte los datos brutos en filas de la tabla.
    return rows.skip(1).map((row) {
      if (row.containsKey('cols') && row['cols'] is List) {
        List<dynamic> rowCells = List<dynamic>.filled(15, {});
        for (var i = 0; i < row['cols'].length; i++) {
          if (row['cols'][i] is Map) {
            rowCells[i] = row['cols'][i];
          } else {
            rowCells[12] = {'t': row['cols'][i].toString()};
          }
        }

        // Agregamos la nueva celda en la última posición
        rowCells[14] = {};

        return DataRow(
          cells: rowCells.map<DataCell>((cell) {
            if (cell is Map && cell.containsKey('t')) {
              return _getDataCell(cell);
            } else if (cell is Map && cell.isEmpty) {
              return DataCell(
                IconButton(
                  icon: const Icon(Icons.work_history), color: Colors.orange,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardsRoutePage(
                          rows: row['rows'],
                        ),
                      ),
                    );
                  },
                ),
              );
            } else {
              return const DataCell(Text('-'));
            }
          }).toList(),
        );
      } else {
        return const DataRow(cells: []);
      }
    }).toList();
  }

  // Método para obtener un widget DataCell a partir de un dato.
  DataCell _getDataCell(Map cell) {
    // El código que decide cómo mostrar el dato en una celda.
    var cellValue = cell['t'];
    if (cellValue == '—') {
      return const DataCell(Text('-'));
    } else if (cellValue == 11) {
      return DataCell(Text('$cellValue'));
    } else if (cellValue == 15) {
      return DataCell(Text('$cellValue'));
    } else {
      if (cellValue is String || cellValue is int || cellValue is double) {
        return DataCell(Text(cellValue.toString()));
      } else {
        //print('Error: el valor de "t" no es un string, int o double');
        return const DataCell(Text('-'));
      }
    }
  }

  // Método para extraer todas las filas de los datos.
  List<dynamic> obtenerTodasLasRows(dynamic data) {
    // El código que navega a través de los datos y extrae todas las filas.
    List<dynamic> rows = [];
    if (data is List) {
      for (var element in data) {
        rows.addAll(obtenerTodasLasRows(element));
      }
    } else if (data is Map) {
      if (data.containsKey('cols')) {
        rows.add(data);
      }
      if (data.containsKey('rows')) {
        rows.addAll(obtenerTodasLasRows(data['rows']));
      } else {
        for (var value in data.values) {
          if (value is Map || value is List) {
            rows.addAll(obtenerTodasLasRows(value));
          }
        }
      }
    }
    return rows;
  }

  // Método para construir una tarjeta que muestra información total.
  Widget buildTotalCard(
      String label, dynamic value, IconData? icon, Color? iconColor) {
    // Crea y devuelve una tarjeta que muestra información total.
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.blue, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Icon(
                icon,
                color: iconColor,
              ),
              const SizedBox(height: 8),
              Text(
                value != null ? value.toString() : '-',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método para seleccionar una fecha de inicio.
  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != fromDate) {
      setState(() {
        fromDate = picked;
        // Si hay una unidad seleccionada, busca los datos del informe para las fechas especificadas.
        if (selectedUnit != null) {
          fetchReportData(selectedUnit, fromDate, toDate);
        }
      });
    }
  }

  // Método para seleccionar una fecha final.
  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != toDate) {
      setState(() {
        toDate = picked;
        // Si hay una unidad seleccionada, busca los datos del informe para las fechas especificadas.
        if (selectedUnit != null) {
          fetchReportData(selectedUnit, fromDate, toDate);
        }
      });
    }
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

  @override
  Widget build(BuildContext context) {
    // Obtén el tamaño de la pantalla actual
    double screenWidth = MediaQuery.of(context).size.width;

    // Ajusta el tamaño de fuente en función del tamaño de pantalla
    double fontSize = screenWidth < 500 ? 14 : 16;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Informes de Ruta'),
          backgroundColor: Colors.grey[900],
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 55, 0, 255),
                Color.fromARGB(255, 64, 19, 88)
              ], // Puedes poner los colores que necesitas para tu degradado
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView( // Añade SingleChildScrollView para permitir desplazamiento
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seleccione Una Ruta:',
                              style: TextStyle(
                                fontSize: fontSize, // Usa el tamaño de fuente ajustado
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButton<int>(
                              value: selectedUnit,
                              onChanged: (int? newValue) {
                                setState(() {
                                  selectedUnit = newValue;
                                  fetchReportData(newValue!);
                                });
                              },
                              items: unitOptions.map<DropdownMenuItem<int>>(
                                (dynamic unit) {
                                  final int routeId = unit['id'];
                                  final String routeName = unit['n'].toString();
                                  return DropdownMenuItem<int>(
                                    value: routeId,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.fork_right,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          routeName,
                                          overflow: TextOverflow.ellipsis, // Añade manejo de desbordamiento
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seleccione el rango de fechas:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _selectFromDate(context),
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.blue),
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    fromDate != null
                                        ? 'Desde: ${DateFormat('d/MM/yyyy').format(fromDate!)}'
                                        : 'Fecha Inicial',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _selectToDate(context),
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.blue),
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    toDate != null
                                        ? 'Hasta: ${DateFormat('d/MM/yyyy').format(toDate!)}'
                                        : 'Fecha Final',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Unidad')),
                          DataColumn(label: Text('Fecha')),
                          DataColumn(label: Text('Ciclo')),
                          DataColumn(label: Text('Horario')),
                          DataColumn(label: Text('Inicio')),
                          DataColumn(label: Text('Fin')),
                          DataColumn(label: Text('Duración (min)')),
                          DataColumn(label: Text('Desviación media (min)')),
                          DataColumn(label: Text('Adelantamiento máximo (min)')),
                          DataColumn(label: Text('Atraso máximo (min)')),
                          DataColumn(label: Text('Paradas')),
                          DataColumn(label: Text('Resultado')),
                          DataColumn(label: Text('Fuera de la línea de ruta')),
                          DataColumn(label: Text('Kilometraje')),
                          DataColumn(label: Text('Historial')),
                        ],
                        rows: generateTableRows(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildTotalCard(
                                'Viajes completos',
                                total['total_complete_rides'],
                                Icons.check_circle,
                                Colors.green,
                              ),
                              buildTotalCard(
                                'Viajes planificados',
                                total['total_planed_rides'],
                                Icons.assignment,
                                Colors.blue,
                              ),
                              buildTotalCard(
                                'Viajes no realizados',
                                total['total_no_show_rides'],
                                Icons.cancel,
                                Colors.red,
                              ),
                              buildTotalCard(
                                'Viajes apresurados',
                                total['total_hurry_rides'],
                                Icons.watch_later,
                                Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildTotalCard(
                                'Viajes retrasados',
                                total['total_delay_rides'],
                                Icons.timer,
                                Colors.yellow,
                              ),
                              buildTotalCard(
                                'Viajes no críticos',
                                total['total_non_critical_rides'],
                                Icons.warning,
                                Colors.amber,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildTotalCard(
                                'Mín. desviación media en segundos',
                                total['min_avg_offset'],
                                Icons.arrow_downward,
                                Colors.green,
                              ),
                              buildTotalCard(
                                'Máx. desviación media en segundos',
                                total['max_avg_offset'],
                                Icons.arrow_upward,
                                Colors.red,
                              ),
                              buildTotalCard(
                                'Prom. desviación media en segundos',
                                total['avg_offset'],
                                Icons.swap_horiz,
                                Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ));
  }
}

class ReportGroupPage extends StatefulWidget {
  final int depotId;
  final String token;

  const ReportGroupPage({Key? key, required this.depotId, required this.token})
      : super(key: key);

  @override
  _ReportGroupPageState createState() => _ReportGroupPageState();
}

class _ReportGroupPageState extends State<ReportGroupPage> {
  List<dynamic> rows = [];
  String routeName = '';
  Map<String, dynamic> total = {};
  List<dynamic> unitOptions = [];
  dynamic selectedUnit;
  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();
    _checkInternetConnectivity();
    fetchUnitOptions();
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

  Future<void> fetchUnitOptions() async {
    final depotApiUrl =
        'https://nimbus.wialon.com/api/depot/${widget.depotId}/groups';

    final depotResponse = await http.get(
      Uri.parse(depotApiUrl),
      headers: {
        'accept': 'application/json',
        'Authorization': widget.token,
      },
    );

    if (depotResponse.statusCode == 200) {
      final depotData = json.decode(depotResponse.body);
      setState(() {
        unitOptions = depotData['groups'] ?? [];
      });

      if (unitOptions.isNotEmpty) {
        final selectedUnit = unitOptions.first;
        fetchReportData(selectedUnit['id']);
      }
    } else {
      //print('Error: ${depotResponse.statusCode}');
    }
  }

  Future<void> fetchReportData(int groupId) async {
    final String formattedFromDate =
        fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate!) : '';
    final String formattedToDate =
        toDate != null ? DateFormat('yyyy-MM-dd').format(toDate!) : '';

    final reportApiUrl =
        'https://nimbus.wialon.com/api/depot/${widget.depotId}/report/group_route/$groupId?flags=1&df=$formattedFromDate&dt=$formattedToDate&sort=timetable';

    //print('esta es la api: $reportApiUrl');

    final reportResponse = await http.get(
      Uri.parse(reportApiUrl),
      headers: {
        'accept': 'application/json',
        'Authorization': widget.token,
      },
    );

    if (reportResponse.statusCode == 200) {
      final reportData = json.decode(reportResponse.body);
      setState(() {
        rows = reportData['report_data']['rows'] ?? [];
        routeName = reportData['n'];
        total = reportData['total'] ?? {};
        selectedUnit = groupId;
      });
    } else {
      //print('Error: ${reportResponse.statusCode}');
    }
  }

List<DataRow> generateTableRows() {
  return rows.map((row) {
    if (row.containsKey('cols') && row['cols'] is List) {
      List<dynamic> rowCells = List<dynamic>.filled(11, {}); // Aumentamos el tamaño de la lista para acomodar la nueva columna
      for (var i = 0; i < row['cols'].length; i++) {
        if (row['cols'][i] is Map) {
          rowCells[i] = row['cols'][i];
        } else {
          rowCells[i] = {'t': row['cols'][i].toString()};
        }
      }

      // Añadimos la unidad en la posición correcta en el array rowCells
      if (row.containsKey('rows') && row['rows'] is List && row['rows'][0] is List && row['rows'][0][2] is Map) {
        rowCells[10] = row['rows'][0][2]; // Siempre asumimos que la unidad está en rows[0][2]
      }

      return DataRow(
        cells: rowCells.map<DataCell>((cell) {
          if (cell is Map && cell.containsKey('t')) {
            return _getDataCell(cell);
          } else {
            return const DataCell(Text('-'));
          }
        }).toList(),
      );
    } else {
      //print('Error: la fila no contiene "cols" o "cols" no es una lista');
      return const DataRow(cells: []);
    }
  }).toList();
}

  DataCell _getDataCell(Map cell) {
    var cellValue = cell['t'];
    if (cellValue == '—') {
      return const DataCell(Text('-'));
    } else {
      if (cellValue is String || cellValue is int || cellValue is double) {
        return DataCell(Text(cellValue.toString()));
      } else {
        //print('Error: el valor de "t" no es un string, int o double');
        return const DataCell(Text('-'));
      }
    }
  }

  List<dynamic> obtenerTodasLasRows(dynamic data) {
    List<dynamic> rows = [];
    if (data is List) {
      for (var element in data) {
        rows.addAll(obtenerTodasLasRows(element));
      }
    } else if (data is Map) {
      if (data.containsKey('cols')) {
        rows.add(data);
      }
      if (data.containsKey('rows')) {
        rows.addAll(obtenerTodasLasRows(data['rows']));
      } else {
        for (var value in data.values) {
          if (value is Map || value is List) {
            rows.addAll(obtenerTodasLasRows(value));
          }
        }
      }
    }
    return rows;
  }

  Widget buildTotalCard(
      String label, dynamic value, IconData? icon, Color? iconColor) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.blue, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Icon(
                icon,
                color: iconColor,
              ),
              const SizedBox(height: 8),
              Text(
                value != null ? value.toString() : '-',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != fromDate) {
      setState(() {
        fromDate = picked;
        if (selectedUnit != null) {
          fetchReportData(selectedUnit);
        }
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != toDate) {
      setState(() {
        toDate = picked;
        if (selectedUnit != null) {
          fetchReportData(selectedUnit);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtén el tamaño de la pantalla actual
    double screenWidth = MediaQuery.of(context).size.width;

    // Ajusta el tamaño de fuente en función del tamaño de pantalla
    double fontSize = screenWidth < 500 ? 14 : 16;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Informes de Viajes de Grupos'),
          backgroundColor: Colors.grey[900],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 55, 0, 255),
                Color.fromARGB(255, 64, 19, 88)
              ], // Puedes poner los colores que necesitas para tu degradado
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seleccione un grupo:',
                            style: TextStyle(
                              fontSize: fontSize, // Usa el tamaño de fuente ajustado
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<int>(
                            value: selectedUnit,
                            onChanged: (int? newValue) {
                              setState(() {
                                selectedUnit = newValue;
                                fetchReportData(newValue!);
                              });
                            },
                            items: unitOptions.map<DropdownMenuItem<int>>(
                              (dynamic unit) {
                                final int routeId = unit['id'];
                                final String routeName = unit['n'].toString();
                                return DropdownMenuItem<int>(
                                  value: routeId,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.local_shipping,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(routeName),
                                    ],
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                        ],
                      ),
                    )
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seleccione el rango de fechas:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _selectFromDate(context),
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.blue),
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    fromDate != null
                                        ? 'Desde: ${DateFormat('dd/MM/yyyy').format(fromDate!)}'
                                        : 'Fecha Inicial',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _selectToDate(context),
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.blue),
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    toDate != null
                                        ? 'Hasta: ${DateFormat('d/MM/yyyy').format(toDate!)}'
                                        : 'Fecha Final',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 100),
                        child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Fecha')),
                          DataColumn(label: Text('Ruta')),
                          DataColumn(label: Text('Unidades')),
                          DataColumn(label: Text('Planeadas')),
                          DataColumn(label: Text('Realizadas')),
                          DataColumn(label: Text('No realizadas')),
                          DataColumn(label: Text('Fuera de horario')),
                          DataColumn(label: Text('A tiempo')),
                          DataColumn(label: Text('Fuera de la línea de ruta')),
                          DataColumn(label: Text('Kilometraje')),
                          DataColumn(label: Text('Unidad que realizó el viaje')),
                          ],
                          rows: generateTableRows(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 400),
                ],
              ),
            ),
          ),
        )
      );
  }
}

class ReportUnitPage extends StatefulWidget {
  final int depotId;
  final String token;

  const ReportUnitPage({Key? key, required this.depotId, required this.token})
      : super(key: key);

  @override
  _ReportUnitPageState createState() => _ReportUnitPageState();
}

class _ReportUnitPageState extends State<ReportUnitPage> {
  List<dynamic> rows = [];
  String unitName = '';
  Map<String, dynamic> total = {};
  List<dynamic> unitIds = [];
  List<dynamic> unitDetails = [];
  String? selectedUnitId;
  dynamic selectedUnit1;
  DateTime? fromDate;
  DateTime? toDate;
  List<dynamic> unitOptions = [];
  List<dynamic> selectedUnits = [];
  Map<String, dynamic>? selectedUnit;
  bool isLoading = true;

  List<DropdownMenuItem<String>> buildDropdownMenuItems(
      List<dynamic> unitDetails) {
    return unitDetails
        .map<DropdownMenuItem<String>>((unit) {
          return DropdownMenuItem<String>(
            value: unit['id'].toString(),
            child: Text(unit['obj_name']),
          );
        })
        .toSet() // Eliminar duplicados
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _checkInternetConnectivity();
    fetchUnitOptions();
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

  Future<void> fetchUnitOptions() async {
    final depotApiUrl =
        'https://nimbus.wialon.com/api/depot/${widget.depotId}/routes';
    final depotResponse = await http.get(
      Uri.parse(depotApiUrl),
      headers: {
        'accept': 'application/json',
        'Authorization': widget.token,
      },
    );

    //print('primera api: ${depotApiUrl}');

    if (depotResponse.statusCode == 200) {
      final depotData = json.decode(depotResponse.body);
      var units = depotData['routes'] ?? [];

      for (var unit in units) {
        if (unit['u'] != null && unit['u'].isNotEmpty) {
          final filteredU = unit['u'].where((u) => u is int).toSet().toList();
          unitIds.addAll(filteredU);
        }
      }

      unitIds = unitIds.toSet().toList(); // remove duplicates

      for (var unitId in unitIds) {
        await fetchUnitDetails(unitId);
      }

      if (selectedUnit == null && unitDetails.isNotEmpty) {
        setState(() {
          selectedUnit = unitDetails.first;
          fetchReportData(selectedUnit!['id']);
        });
      } else {
        //print('Error: ${depotResponse.statusCode}');
      }
    }
  }

  Future<void> fetchUnitDetails(int unitId) async {
    final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final String apiUrl =
        'https://nimbus.wialon.com/api/depot/${widget.depotId}/report/avl_unit/$unitId?flags=1&df=$currentDate&dt=$currentDate&sort=timetable';

    final reportResponse = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'accept': 'application/json',
        'Authorization': widget.token,
      },
    );

    //print('segunda api: ${apiUrl}');

    if (reportResponse.statusCode == 200) {
      final unitData = json.decode(reportResponse.body);

      if (unitData != null &&
          unitData['params'] != null &&
          unitData['params']['obj_name'] != null &&
          unitData['params']['obj_name'].isNotEmpty) {
        setState(() {
          final existingUnit = unitDetails.firstWhere(
              (unit) => unit['id'] == unitData['params']['id'],
              orElse: () => null);
          if (existingUnit == null) {
            unitDetails.add(unitData['params']);
          }
        });
      }
    } else {
      //print('Error: ${reportResponse.statusCode}');
    }
  }

  Future<void> fetchReportData(int unidadId) async {
    final String formattedFromDate =
        fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate!) : '';
    final String formattedToDate =
        toDate != null ? DateFormat('yyyy-MM-dd').format(toDate!) : '';

    final reportApiUrl =
        'https://nimbus.wialon.com/api/depot/${widget.depotId}/report/avl_unit/$unidadId?flags=1&df=$formattedFromDate&dt=$formattedToDate&sort=timetable';

    setState(() {
      isLoading = true;
    });

    // print('Este es el unidad ID: $unidadId');
    // print('tercera api: $reportApiUrl');

    final reportResponse = await http.get(
      Uri.parse(reportApiUrl),
      headers: {
        'accept': 'application/json',
        'Authorization': widget.token,
      },
    );

    setState(() {
      isLoading = false;
    });

    if (reportResponse.statusCode == 200) {
      final reportData = json.decode(reportResponse.body);

      if (reportData.containsKey('report_data') &&
          reportData['report_data'].containsKey('rows')) {
        setState(() {
          rows = reportData['report_data']['rows'] ?? [];
          unitName = reportData.containsKey('n') ? reportData['n'] : "";
          total = reportData.containsKey('total') ? reportData['total'] : {};
        });
      } else {
        //print('Error: los datos del reporte no contienen "report_data" o "rows"');
      }
    } else {
      //print('Error: ${reportResponse.statusCode}');
    }
  }

List<DataRow> generateTableRows() {
  return rows.map((row) {
    if (row.containsKey('cols') && row['cols'] is List) {
      List<dynamic> rowCells = List<dynamic>.filled(15, {});
      for (var i = 0; i < row['cols'].length; i++) {
        if (row['cols'][i] is Map) {
          rowCells[i] = row['cols'][i];
        } else {
          rowCells[12] = {'t': row['cols'][i].toString()};
        }
      }

      // Agregamos la nueva celda en la última posición
      rowCells[14] = {};

      return DataRow(
        cells: rowCells.map<DataCell>((cell) {
          if (cell is Map && cell.containsKey('t')) {
            return _getDataCell(cell);
          } else if (cell is Map && cell.isEmpty) {
            return DataCell(
              IconButton(
                icon: const Icon(Icons.work_history), color: Colors.orange,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardsRoutePage(
                        rows: row['rows'],
                      ),
                    ),
                  );
                },
              ),
            );
          } else {
            return const DataCell(Text('-'));
          }
        }).toList(),
      );
    } else {
      return const DataRow(cells: []);
    }
  }).toList();
}

  DataCell _getDataCell(Map cell) {
    var cellValue = cell['t'];
    if (cellValue == '—') {
      return const DataCell(Text('-'));
    } else if (cellValue == 11) {
      return DataCell(Text('$cellValue'));
    } else if (cellValue == 15) {
      return DataCell(Text('$cellValue'));
    } else {
      if (cellValue is String || cellValue is int || cellValue is double) {
        return DataCell(Text(cellValue.toString()));
      } else {
        //print('Error: el valor de "t" no es un string, int o double');
        return const DataCell(Text('-'));
      }
    }
  }

  List<dynamic> obtenerTodasLasRows(dynamic data) {
    List<dynamic> rows = [];
    if (data is List) {
      for (var element in data) {
        rows.addAll(obtenerTodasLasRows(element));
      }
    } else if (data is Map) {
      if (data.containsKey('cols')) {
        rows.add(data);
      }
      if (data.containsKey('rows')) {
        rows.addAll(obtenerTodasLasRows(data['rows']));
      } else {
        for (var value in data.values) {
          if (value is Map || value is List) {
            rows.addAll(obtenerTodasLasRows(value));
          }
        }
      }
    }
    return rows;
  }

  Widget buildTotalCard(
      String label, dynamic value, IconData? icon, Color? iconColor) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.blue, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Icon(
                icon,
                color: iconColor,
              ),
              const SizedBox(height: 8),
              Text(
                value != null ? value.toString() : '-',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != fromDate) {
      setState(() {
        fromDate = picked;
        if (selectedUnit != null) {
          fetchReportData(selectedUnit!['id']);
        }
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != toDate) {
      setState(() {
        toDate = picked;
        if (selectedUnit != null) {
          fetchReportData(selectedUnit!['id']);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dentro de tu método build
    double screenWidth = MediaQuery.of(context).size.width;

    // Ajusta el tamaño de fuente en función del tamaño de pantalla
    double fontSize = screenWidth < 500 ? 14 : 16;
    if (unitDetails.isEmpty) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Informes de Unidad'),
            backgroundColor: Colors.grey[900],
          ),
          body: Center(
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
          ));
    } else {
      //  print('estos son unitDetails: $unitDetails');
      //  print('este es selectedUnit: $selectedUnitId');
      return Scaffold(
          appBar: AppBar(
            title: const Text('Informes de Unidad'),
            backgroundColor: Colors.grey[900],
          ),
          body: Container(
            
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 55, 0, 255),
                  Color.fromARGB(255, 64, 19, 88)
                ], // Puedes poner los colores que necesitas para tu degradado
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seleccione Una Unidad:',
                              style: TextStyle(
                                fontSize: fontSize, // Usa el tamaño de fuente ajustado
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButton<String>(
                              value: selectedUnit != null
                                  ? selectedUnit!['id'].toString()
                                  : null,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedUnit = unitDetails.firstWhereOrNull(
                                      (unit) => unit['id'].toString() == newValue);
                                  if (selectedUnit != null) {
                                    fetchReportData(selectedUnit!['id']);
                                  }
                                });
                              },
                              items: unitDetails
                                  .whereType<Map>()
                                  .map<DropdownMenuItem<String>>((unit) {
                                return DropdownMenuItem<String>(
                                  value: unit['id'].toString(),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.emoji_transportation,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        unit['obj_name'],
                                        overflow: TextOverflow.ellipsis, // Manejo de desbordamiento
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: fontSize, // Usa el tamaño de fuente ajustado
                              ),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.black54,
                              ),
                              underline: Container(
                                height: 1,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seleccione el rango de fechas:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _selectFromDate(context),
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.blue),
                                      shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      fromDate != null
                                          ? 'Desde: ${DateFormat('d/MM/yyyy').format(fromDate!)}'
                                          : 'Fecha Inicial',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _selectToDate(context),
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.blue),
                                      shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      toDate != null
                                          ? 'Hasta: ${DateFormat('d/MM/yyyy').format(toDate!)}'
                                          : 'Fecha Final',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Unidad')),
                            DataColumn(label: Text('Fecha')),
                            DataColumn(label: Text('Ciclo')),
                            DataColumn(label: Text('Horario')),
                            DataColumn(label: Text('Inicio')),
                            DataColumn(label: Text('Fin')),
                            DataColumn(label: Text('Duración (min)')),
                            DataColumn(label: Text('Desviación media (min)')),
                            DataColumn(label: Text('Adelantamiento máximo (min)')),
                            DataColumn(label: Text('Atraso máximo (min)')),
                            DataColumn(label: Text('Paradas')),
                            DataColumn(label: Text('Resultado')),
                            DataColumn(label: Text('Fuera de la línea de ruta')),
                            DataColumn(label: Text('Kilometraje')),
                            DataColumn(label: Text('Historial')),
                          ],
                          rows: generateTableRows(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                buildTotalCard(
                                  'Viajes completos',
                                  total['total_complete_rides'],
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                                buildTotalCard(
                                  'Viajes planificados',
                                  total['total_planed_rides'],
                                  Icons.assignment,
                                  Colors.blue,
                                ),
                                buildTotalCard(
                                  'Viajes no realizados',
                                  total['total_no_show_rides'],
                                  Icons.cancel,
                                  Colors.red,
                                ),
                                buildTotalCard(
                                  'Viajes apresurados',
                                  total['total_hurry_rides'],
                                  Icons.watch_later,
                                  Colors.orange,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                buildTotalCard(
                                  'Viajes retrasados',
                                  total['total_delay_rides'],
                                  Icons.timer,
                                  Colors.yellow,
                                ),
                                buildTotalCard(
                                  'Viajes no críticos',
                                  total['total_non_critical_rides'],
                                  Icons.warning,
                                  Colors.amber,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                buildTotalCard(
                                  'Mín. desviación media en segundos',
                                  total['min_avg_offset'],
                                  Icons.arrow_downward,
                                  Colors.green,
                                ),
                                buildTotalCard(
                                  'Máx. desviación media en segundos',
                                  total['max_avg_offset'],
                                  Icons.arrow_upward,
                                  Colors.red,
                                ),
                                buildTotalCard(
                                  'Prom. desviación media en segundos',
                                  total['avg_offset'],
                                  Icons.swap_horiz,
                                  Colors.blue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ));
    }
  }
}
