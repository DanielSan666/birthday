import 'package:birthday/screens/calendary_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Lista de nombres de los meses
  final List<String> months = const [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  List<QueryDocumentSnapshot> _events = [];
  String _selectedMonth = '';

  // Función para mostrar información del mes
  void _showMonthInfo(String month) async {
    // Obtener eventos del mes seleccionado desde Firebase
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('birthday')
            .where(
              'date',
              isGreaterThanOrEqualTo:
                  DateTime(
                    DateTime.now().year,
                    months.indexOf(month) + 1,
                    1,
                  ).toIso8601String(),
            )
            .where(
              'date',
              isLessThan:
                  DateTime(
                    DateTime.now().year,
                    months.indexOf(month) + 2,
                    1,
                  ).toIso8601String(),
            )
            .get();

    setState(() {
      _events = snapshot.docs;
      _selectedMonth = month;
    });
  }

  // Función para generar colores pastel aleatorios
  Color _generatePastelColor() {
    Random random = Random();
    int r = 150 + random.nextInt(106); // Rango de 150 a 255
    int g = 150 + random.nextInt(106); // Rango de 150 a 255
    int b = 150 + random.nextInt(106); // Rango de 150 a 255
    return Color.fromARGB(255, r, g, b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          children: [
            Text('Calendario', style: TextStyle(color: Colors.white)),
            Spacer(), // Espacio flexible para empujar el ícono a la derecha
            GestureDetector(
              onTap: () {
                // Navegar a la nueva pantalla
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalendaryScreen(),
                  ),
                );
              },
              child: Icon(
                Icons.calendar_month_outlined, // Ícono de calendario
                color:
                    Colors
                        .white, // Color del ícono (blanco para contrastar con la AppBar)
                size: 24, // Tamaño del ícono
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 180, 216, 245),
      ),
      body: Column(
        children: [
          // Título con ícono de calendario
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centrar el contenido
              children: [
                SizedBox(width: 8), // Espacio entre el ícono y el texto
                Text(
                  'Desliza para ver los meses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Lista horizontal de meses
          SizedBox(
            height: 100, // Altura de la lista de meses
            child: ListView.builder(
              scrollDirection: Axis.horizontal, // Scroll horizontal
              itemCount: months.length,
              itemBuilder: (context, index) {
                final month = months[index];
                return GestureDetector(
                  onTap: () {
                    _showMonthInfo(month); // Mostrar información del mes
                  },
                  child: Container(
                    width: 120, // Ancho de cada mes
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        month,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Mostrar eventos del mes seleccionado
          if (_selectedMonth.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Eventos de $_selectedMonth',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  final eventData = event.data() as Map<String, dynamic>;
                  final eventDate = DateTime.parse(eventData['date']);

                  // Calcular la fecha del próximo año si el evento ya pasó
                  final nextYearEventDate = DateTime(
                    eventDate.year +
                        (eventDate.isBefore(DateTime.now())
                            ? 1
                            : 0), // Sumar un año si ya pasó
                    eventDate.month,
                    eventDate.day,
                  );

                  // Calcular los días restantes (o pasados)
                  final daysRemaining =
                      nextYearEventDate.difference(DateTime.now()).inDays;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    color:
                        _generatePastelColor(), // Asignar color pastel aleatorio
                    child: ListTile(
                      title: Text(
                        eventData['title'],
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        'Fecha: ${DateFormat('dd/MM/yyyy').format(eventDate)}\n${daysRemaining >= 0 ? 'Días restantes: $daysRemaining' // Si el evento está por venir
                            : 'Días pasados: ${daysRemaining.abs()}'}', // Si el evento ya pasó
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
