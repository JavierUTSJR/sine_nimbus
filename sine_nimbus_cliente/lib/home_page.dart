// Instalar librerías necesarias
// ignore_for_file: library_private_types_in_public_api, must_be_immutable
import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'informacion_page.dart';
import 'login_page.dart';
import 'paradas_page.dart';
import 'rutas_page.dart';
import 'seguimiento_page.dart';

// Clase MainMenuPage que extiende StatefulWidget ya que maneja el estado
class MainMenuPage extends StatefulWidget {
  final String token;
  int? depotId; // Puede ser nulo, por lo que se usa int?

  MainMenuPage({required this.token, this.depotId, Key? key}) : super(key: key);

  @override
  _MainMenuPageState createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int _currentIndex =
      0; // Para mantener un seguimiento de la página actual en el menú inferior

  // Lista de páginas a mostrar en función del índice seleccionado en el menú inferior
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    // Si depotId es nulo, lo obtenemos de SharedPreferences
    if (widget.depotId == null) {
      _getDepotIdFromSharedPreferences();
    }
    // Inicializar páginas con token y depotId
    _pages = [
      ParadasPage(token: widget.token, depotId: widget.depotId ?? 0),
      RutasPage(token: widget.token, depotId: widget.depotId ?? 0),
      UserParametersPage(token: widget.token, depotId: widget.depotId ?? 0),
      SelectionScreen(token: widget.token, depotId: widget.depotId ?? 0),
    ];
  }

  // Función para obtener el depotId de SharedPreferences
  Future<void> _getDepotIdFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    int? depotId = prefs.getInt('depotId');
    setState(() {
      widget.depotId = depotId;
    });
  }

  // Función para eliminar el token de SharedPreferences
  Future<void> _deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Función para mostrar una alerta con novedades
  void _showNovedadesAlert() {
    showPlatformDialog(
      context: context,
      builder: (_) => BasicDialogAlert(
        title: const Text('Novedades'),
        content: InAppWebView(
          initialUrlRequest: URLRequest(
            url: Uri.parse('https://help.wialon.com/help/nimbus/es/what-s-new'),
          ),
        ),
        actions: [
          BasicDialogAction(
            onPressed: () {
              // Navegación al Foro
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Foro'),
                      backgroundColor: Colors.grey[900],
                    ),
                    backgroundColor: Colors.grey[900],
                    body: InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: Uri.parse(
                            'https://forum.wialon.com/viewforum.php?id=87'),
                      ),
                    ),
                  ),
                ),
              );
            },
            title: const Text('DISCUTIR EN EL FORO'),
          ),
          BasicDialogAction(
            onPressed: () {
              Navigator.pop(context);
            },
            title: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }

  // Función para manejar la selección del menú de perfil
  void _onProfileMenuSelected(String value) async {
    // Aquí se gestionan las diferentes opciones del menú de perfil, como 'PARAMETROS_DEL_USUARIO', 'DOCUMENTACION', 'NOVEDADES' y 'SALIR'
    // El código maneja la navegación a diferentes páginas o muestra alertas en función de la opción seleccionada
    if (value == 'PARAMETROS_DEL_USUARIO') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              UserParametersPage(
            token: widget.token,
            depotId: widget.depotId ?? 0,
          ),
          transitionDuration: const Duration(seconds: 1),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
        ),
      );
    } else if (value == 'DOCUMENTACION') {
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
            appBar: AppBar(
              title: const Text('Documentación'),
              backgroundColor: Colors.grey[900],
            ),
            backgroundColor: Colors.grey[900],
            body: InAppWebView(
              initialUrlRequest: URLRequest(
                url: Uri.parse(
                    'https://help.wialon.com/help/nimbus/es/user-guide'),
              ),
            ),
          ),
          transitionDuration: const Duration(seconds: 1),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
        ),
      );
    } else if (value == 'NOVEDADES') {
      _showNovedadesAlert();
    } else if (value == 'SALIR') {
      await _deleteToken();
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         // AppBar con menú desplegable
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/nim.png',
              height: 40,
            ),
            const SizedBox(width: 8),
            const Text('SINE'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _onProfileMenuSelected,
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'PARAMETROS_DEL_USUARIO',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Parámetros del usuario'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'DOCUMENTACION',
                child: ListTile(
                  leading: Icon(Icons.book),
                  title: Text('Documentación'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'NOVEDADES',
                child: ListTile(
                  leading: Icon(Icons.new_releases),
                  title: Text('Novedades'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'SALIR',
                child: ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: Text('Salir'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: _pages[_currentIndex], // Mostrar la página actual seleccionada
      ),
      bottomNavigationBar: ConvexAppBar(
        // Menú inferior convexo para navegar entre páginas
        initialActiveIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.grey[900],
        activeColor: Colors.white,
        color: Colors.grey[400],
        style: TabStyle.reactCircle,
        items: const [
          TabItem(icon: Icons.directions_bus, title: 'Paradas'),
          TabItem(icon: Icons.map, title: 'Rutas'),
          TabItem(icon: Icons.track_changes, title: 'Seguimiento'),
          TabItem(icon: Icons.assignment, title: 'Informes'),
        ],
      ),
    );
  }
}
