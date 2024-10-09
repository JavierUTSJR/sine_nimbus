// Importando las bibliotecas necesarias
// ignore_for_file: unused_field, use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api, prefer_final_fields
import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

// Definición de la clase SplashScreen que hereda de StatefulWidget
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

// Estado de la clase SplashScreen
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Retraso antes de navegar a otra pantalla
    Future.delayed(const Duration(milliseconds: 450), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(), // Navegación a la página LoginPage
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Construcción de la interfaz visual de la SplashScreen
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 55, 0, 255),
              Color.fromARGB(255, 64, 19, 88)
            ],
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _logoOffsetAnimation;
  late Animation<double> _opacityAnimation;
  late ConfettiController _confettiController;

  final GlobalKey _imageKey = GlobalKey();
  final TextEditingController _tokenController = TextEditingController();

  bool _isTokenValid = true;
  bool _isTokenComplete = false;

  String _token = ''; // Agregamos esta variable
  int _depotId = 0; // Agregamos esta variable

  bool _validateToken(String token) {
    return token.isNotEmpty;
  }

  // Verifica el token con el servidor
  Future<Map<String, dynamic>> _checkToken(String token) async {
    if (!_validateToken(token)) {
      return {
        'isValid': false,
        'response': 'Token inválido',
        'token': token,
        'url': '',
        'depotId': null,
      };
    }

    String url = 'https://nimbus.wialon.com/api/depots';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': token,
      },
    );

    int? depotId;
    bool isValid = false;
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['depots'] != null && json['depots'].isNotEmpty) {
        depotId = json['depots'][0]['id'];
        isValid = depotId != null;
      }
    }

    return {
      'isValid': isValid,
      'response': response.body,
      'token': token,
      'url': url,
      'depotId': depotId,
    };
  }

  // Guarda el token en las preferencias
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Lee el token de las preferencias
  Future<String?> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Guarda el ID del depósito en las preferencias
  Future<void> _saveDepotId(int depotId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('depotId', depotId);
  }

  // Lee el ID del depósito de las preferencias
  Future<int?> _readDepotId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('depotId');
  }

  // Verifica el estado de inicio de sesión
  void _checkLoginStatus() async {
    String? token = await _readToken();
    int? depotId = await _readDepotId();
    if (token != null && token.isNotEmpty && depotId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => MainMenuPage(
                  token: token,
                  depotId: depotId,
                )),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Verifica el estado de inicio de sesión al inicio

    // ... Configuración de las animaciones ...
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    _logoOffsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.4),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _animationController.forward().whenComplete(() {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    // Elimina los controladores al desechar el widget
    _animationController.dispose();
    _confettiController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Construcción de la UI
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 55, 0, 255),
            Color.fromARGB(255, 64, 19, 88)
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        height: screenHeight * 0.2), // 20% del alto de pantalla
                    SlideTransition(
                      position: _logoOffsetAnimation,
                      child: Center(
                        key: _imageKey,
                        child: Image.asset(
                          'assets/nim.png',
                          height:
                              screenHeight * 0.25, // 25% del alto de pantalla
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: FadeTransition(
                        opacity: _animationController.drive(
                          CurveTween(curve: Curves.easeIn),
                        ),
                        child: const Text(
                          'SINE',
                          style: TextStyle(
                            fontSize: 70,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TyperAnimatedTextKit(
                      speed: const Duration(milliseconds: 200),
                      text: const ['NIMBUS'],
                      textStyle: const TextStyle(
                        fontSize: 20.0,
                        color: Colors.white,
                      ),
                      isRepeatingAnimation: false,
                    ),
                    SizedBox(
                        height: screenHeight * 0.05), // 5% del alto de pantalla
                    FadeTransition(
                      opacity: _opacityAnimation,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _tokenController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.vpn_key,
                                  color: Colors.white),
                              labelText: 'Token',
                              labelStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              fillColor: Colors.white24,
                              filled: true,
                              border: const OutlineInputBorder(),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white54),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              errorText:
                                  _isTokenValid ? null : 'Token inválido',
                              counterStyle: const TextStyle(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            maxLength: 38,
                            onChanged: (value) {
                              setState(() {
                                _isTokenValid = _validateToken(value);
                                _isTokenComplete = value.length == 38;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isTokenValid &&
                                    _tokenController.text.isNotEmpty
                                ? () async {
                                    ConnectivityResult connectivityResult =
                                        await Connectivity()
                                            .checkConnectivity();

                                    if (connectivityResult ==
                                        ConnectivityResult.none) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'No hay conexión a Internet. Por favor, verifica tu conexión e intenta nuevamente.'),
                                          duration: Duration(seconds: 3),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    _token = _tokenController.text;
                                    Map<String, dynamic> result =
                                        await _checkToken(_token);
                                    bool isValid = result['isValid'];
                                    String token = result['token'];
                                    int? depotId = result['depotId'];
                                    if (isValid) {
                                      _saveToken(token);
                                      if (depotId != null) {
                                        _saveDepotId(depotId);
                                      }
                                      Navigator.pushReplacement(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation,
                                                  secondaryAnimation) =>
                                              MainMenuPage(
                                            token: token,
                                            depotId: depotId,
                                          ),
                                          transitionDuration: const Duration(
                                              seconds:
                                                  1), // Puedes ajustar la duración de la transición aquí
                                          transitionsBuilder: (context,
                                              animation,
                                              secondaryAnimation,
                                              child) {
                                            var begin = const Offset(1.0, 0.0);
                                            var end = Offset.zero;
                                            var curve =
                                                Curves.easeInOut; // Curva suave

                                            var tween = Tween(
                                                    begin: begin, end: end)
                                                .chain(
                                                    CurveTween(curve: curve));

                                            var scaleTween = Tween(
                                                    begin: 0.0, end: 1.0)
                                                .chain(
                                                    CurveTween(curve: curve));

                                            return FadeTransition(
                                              opacity: animation,
                                              child: SlideTransition(
                                                position:
                                                    animation.drive(tween),
                                                child: ScaleTransition(
                                                  scale: animation
                                                      .drive(scaleTween),
                                                  child: child,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                      //print('Este es el depotID: $depotId');
                                      // print('Este es el token: $token');
                                    } else {
                                      String message = _isTokenComplete
                                          ? 'El token proporcionado es incorrecto.'
                                          : 'Token inválido. Por favor, verifica e intenta nuevamente.';
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(message),
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.blueGrey[900],
                              backgroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 32,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Iniciar sesión'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                        height: screenHeight * 0.5), // 5% del alto de pantalla
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 1.5,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                shouldLoop: false,
                displayTarget: false,
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
