// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';

class CardsRoutePage extends StatelessWidget {
  final List<dynamic> rows;

  const CardsRoutePage({Key? key, required this.rows}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int cardsWithHyphenCount = 0;
    int cardsWithinToleranceCount = 0;

    for (final row in rows) {
      final subtitle = (row.length > 7 && row[7] != null)
          ? row[7]['t'].toString()
          : '';

      if (subtitle == '—') {
        cardsWithHyphenCount++;
      } else {
        var subtitleValue = int.tryParse(subtitle);
        if (subtitleValue != null && subtitleValue >= -4 && subtitleValue <= 4) {
          cardsWithinToleranceCount++;
        }
      }
    }

    bool allCardsWithHyphen = cardsWithHyphenCount == rows.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: Colors.grey[900],
      ),
      body: ListView.builder(
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row != null && row.length > 0) {
            var title = (row.length > 0 && row[0] != null)
                ? row[0]['t']
                : '';
            var subtitle = (row.length > 7 && row[7] != null)
                ? row[7]['t'].toString()
                : '';
            var subtitleValue = int.tryParse(subtitle);

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    subtitle != ''
                        ? Row(
                            children: [
                              const Icon(
                                Icons.safety_check,
                                color: Colors.grey,
                                size: 25,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  subtitle == '—'
                                      ? allCardsWithHyphen
                                          ? 'Sin salir a la rutina'
                                          : 'Parada no realizada'
                                      : subtitleValue != null
                                          ? subtitleValue >= -4 && subtitleValue <= 4
                                              ? 'Dentro de la tolerancia de horario'
                                              : subtitleValue >= 5
                                                  ? 'Diferencia de horario: $subtitle min'
                                                  : 'Diferencia de horario: $subtitle min'
                                          : 'Diferencia de horario: $subtitle min',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[900],
                                    fontWeight: subtitle == '—'
                                        ? FontWeight.bold
                                        : FontWeight.normal
                                  ),
                                ),
                              ),
                              if (subtitle == '—')
                                Icon(
                                  allCardsWithHyphen
                                      ? Icons.adjust
                                      : Icons.running_with_errors,
                                  color: allCardsWithHyphen
                                      ? const Color.fromARGB(255, 255, 0, 187)
                                      : Colors.black,
                                  size: 35,
                                ),
                              if (subtitleValue != null &&
                                  subtitle != '—')
                                Icon(
                                  subtitleValue >= 5
                                      ? Icons.arrow_circle_up
                                      : subtitleValue <= -5
                                          ? Icons.arrow_circle_down
                                          : Icons.check_circle_outline,
                                  color: subtitleValue >= 5
                                      ? Colors.orange
                                      : subtitleValue <= -5
                                          ? Colors.red
                                          : Colors.grey,
                                  size: 35,
                                ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}

class CardsUnitPage extends StatelessWidget {
  final List<dynamic> rows;

  const CardsUnitPage({Key? key, required this.rows}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int cardsWithHyphenCount = 0;
    int cardsWithinToleranceCount = 0;

    for (final row in rows) {
      final subtitle = (row.length > 7 && row[7] != null)
          ? row[7]['t'].toString()
          : '';

      if (subtitle == '—') {
        cardsWithHyphenCount++;
      } else {
        var subtitleValue = int.tryParse(subtitle);
        if (subtitleValue != null && subtitleValue >= -4 && subtitleValue <= 4) {
          cardsWithinToleranceCount++;
        }
      }
    }

    bool allCardsWithHyphen = cardsWithHyphenCount == rows.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: Colors.grey[900],
      ),
      body: ListView.builder(
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row != null && row.length > 0) {
            var title = (row.length > 0 && row[0] != null)
                ? row[0]['t']
                : '';
            var subtitle = (row.length > 7 && row[7] != null)
                ? row[7]['t'].toString()
                : '';
            var subtitleValue = int.tryParse(subtitle);

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    subtitle != ''
                        ? Row(
                            children: [
                              const Icon(
                                Icons.safety_check,
                                color: Colors.grey,
                                size: 25,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  subtitle == '—'
                                      ? allCardsWithHyphen
                                          ? 'Sin salir de la rutina'
                                          : 'Parada no realizada'
                                      : subtitleValue != null
                                          ? subtitleValue >= -4 && subtitleValue <= 4
                                              ? 'Dentro de la tolerancia de horario'
                                              : subtitleValue >= 5
                                                  ? 'Diferencia de horario: $subtitle min'
                                                  : 'Diferencia de horario: $subtitle min'
                                          : 'Diferencia de horario: $subtitle min',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[900],
                                    fontWeight: subtitle == '—'
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (subtitle == '—')
                                Icon(
                                  allCardsWithHyphen
                                      ? Icons.adjust
                                      : Icons.highlight_off,
                                  color: allCardsWithHyphen
                                      ? const Color.fromARGB(255, 255, 0, 187)
                                      : Colors.black,
                                  size: 35,
                                ),
                              if (subtitleValue != null &&
                                  subtitle != '—')
                                Icon(
                                  subtitleValue >= 5
                                      ? Icons.arrow_circle_up
                                      : subtitleValue <= -5
                                          ? Icons.arrow_circle_down
                                          : Icons.check_circle_outline,
                                  color: subtitleValue >= 5
                                      ? Colors.orange
                                      : subtitleValue <= -5
                                          ? Colors.red
                                          : Colors.grey,
                                  size: 35,
                                ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
