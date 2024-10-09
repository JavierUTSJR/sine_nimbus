import 'package:flutter/material.dart';
import 'login_page.dart'; // Asegúrate de que este import coincida con la ubicación del archivo de LoginPage

void main() {
  runApp(const MyApp());
}

// Definición de la clase MyApp que hereda de StatelessWidget
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Constructor de la clase MyApp

  @override
  Widget build(BuildContext context) {
    // Método build, necesario para construir la interfaz de la aplicación
    return MaterialApp(
      title: 'SINE', // Título de la aplicación
      debugShowCheckedModeBanner: false, // Oculta la etiqueta "Debug" en la esquina superior derecha
      theme: ThemeData(
        primarySwatch: Colors.blue, // Definición de colores primarios para la interfaz
        visualDensity: VisualDensity.adaptivePlatformDensity, // Ajuste de densidad visual
      ),
      home: const SplashScreen(), // Pantalla de inicio, en este caso, SplashScreen
    );
  }
}
