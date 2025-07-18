import 'package:flutter/material.dart';
import 'package:birthday/services/firebase_functions.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CalendaryScreen extends StatefulWidget {
  const CalendaryScreen({super.key});

  @override
  State<CalendaryScreen> createState() => _CalendaryScreenState();
}

class _CalendaryScreenState extends State<CalendaryScreen> {
  DateTime today = DateTime.now();
  bool isAllDay = false;
  bool isRepeating = false;
  TextEditingController eventTitleController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController notesController = TextEditingController();
  DateTime? startTime;
  DateTime? endTime;
  Color selectedTagColor = Colors.blue;

  @override
  void dispose() {
    eventTitleController.dispose();
    locationController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      today = selectedDay;
    });
  }

  void _showBottomSheet({DocumentSnapshot? event}) {
    if (event != null) {
      final eventData = event.data() as Map<String, dynamic>;
      eventTitleController.text = eventData['title'];
      locationController.text = eventData['location'];
      notesController.text = eventData['notes'];
      isAllDay = eventData['isAllDay'];
      isRepeating = eventData['isRepeating'];
      startTime =
          eventData['startTime'] != null
              ? DateTime.parse(eventData['startTime'])
              : null;
      endTime =
          eventData['endTime'] != null
              ? DateTime.parse(eventData['endTime'])
              : null;
      selectedTagColor = Color(eventData['tagColor']);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: eventTitleController,
                      decoration: InputDecoration(
                        labelText: "Event Title",
                        hintText: "Evento sin título",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: locationController,
                            decoration: InputDecoration(
                              labelText: "Location",
                              hintText: "Agregar ubicación",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                      ],
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Notes",
                        hintText: "Añadir notas",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("All day"),
                        Switch(
                          value: isAllDay,
                          onChanged: (value) {
                            setModalState(() {
                              isAllDay = value;
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Repeat"),
                        Switch(
                          value: isRepeating,
                          onChanged: (value) {
                            setModalState(() {
                              isRepeating = value;
                            });
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              DateTime? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              ).then((time) {
                                if (time != null) {
                                  return DateTime(
                                    today.year,
                                    today.month,
                                    today.day,
                                    time.hour,
                                    time.minute,
                                  );
                                }
                                return null;
                              });
                              if (picked != null) {
                                setModalState(() {
                                  startTime = picked;
                                });
                              }
                            },
                            child: Text(
                              startTime == null
                                  ? "Select Start Time"
                                  : "Start: ${DateFormat.jm().format(startTime!)}",
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              DateTime? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              ).then((time) {
                                if (time != null) {
                                  return DateTime(
                                    today.year,
                                    today.month,
                                    today.day,
                                    time.hour,
                                    time.minute,
                                  );
                                }
                                return null;
                              });
                              if (picked != null) {
                                setModalState(() {
                                  endTime = picked;
                                });
                              }
                            },
                            child: Text(
                              endTime == null
                                  ? "Select End Time"
                                  : "End: ${DateFormat.jm().format(endTime!)}",
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tag Color"),
                        Wrap(
                          spacing: 10,
                          children:
                              [
                                Colors.blue[100],
                                Colors.yellow[100],
                                Colors.pink[100],
                                Colors.green[100],
                                Colors.cyan[100],
                                Colors.amber[100],
                              ].map((color) {
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedTagColor = color!;
                                    });
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: color,
                                    radius: 15,
                                    child:
                                        selectedTagColor == color
                                            ? Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 18,
                                            )
                                            : null,
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          if (event != null) {
                            await editEvent(
                              context: context,
                              event: event,
                              today: today,
                              eventTitleController: eventTitleController,
                              locationController: locationController,
                              notesController: notesController,
                              isAllDay: isAllDay,
                              isRepeating: isRepeating,
                              startTime: startTime,
                              endTime: endTime,
                              selectedTagColor: selectedTagColor,
                            );
                          } else {
                            await addEvent(
                              context: context,
                              today: today,
                              eventTitleController: eventTitleController,
                              locationController: locationController,
                              notesController: notesController,
                              isAllDay: isAllDay,
                              isRepeating: isRepeating,
                              startTime: startTime,
                              endTime: endTime,
                              selectedTagColor: selectedTagColor,
                            );
                          }

                          eventTitleController.clear();
                          locationController.clear();
                          notesController.clear();
                          setModalState(() {
                            isAllDay = false;
                            isRepeating = false;
                            startTime = null;
                            endTime = null;
                            selectedTagColor = Colors.blue;
                          });

                          Navigator.pop(context);
                        } catch (e) {
                          print("Error al guardar el evento: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error al guardar el evento"),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 100, 167, 235),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text("Save"),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      eventTitleController.clear();
      locationController.clear();
      notesController.clear();
      setState(() {
        isAllDay = false;
        isRepeating = false;
        startTime = null;
        endTime = null;
        selectedTagColor = Colors.blue;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Calendario",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 151, 199, 247),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: _showBottomSheet),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    locale: 'en_US',
                    rowHeight: constraints.maxWidth > 500 ? 70 : 50,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: TextStyle(fontSize: 16),
                    ),
                    focusedDay: today,
                    firstDay: DateTime.utc(2010, 10, 16),
                    lastDay: DateTime(2050, 3, 14),
                    selectedDayPredicate: (day) => isSameDay(day, today),
                    onDaySelected: _onDaySelected,
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('birthday')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final events =
                      snapshot.data!.docs.where((event) {
                        final eventData = event.data() as Map<String, dynamic>;
                        final eventDate = DateTime.parse(eventData['date']);
                        return isSameDay(eventDate, today);
                      }).toList();

                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final eventData = event.data() as Map<String, dynamic>;
                      DateTime.parse(eventData['date']);
                      final eventTitle = eventData['title'];
                      final eventLocation = eventData['location'];
                      final eventTagColor = Color(eventData['tagColor']);
                      final eventStartTime =
                          eventData['startTime'] != null
                              ? DateFormat.jm().format(
                                DateTime.parse(eventData['startTime']),
                              )
                              : 'No start time';
                      final eventEndTime =
                          eventData['endTime'] != null
                              ? DateFormat.jm().format(
                                DateTime.parse(eventData['endTime']),
                              )
                              : 'No end time';

                      return Card(
                        margin: EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: eventTagColor,
                        elevation: 4,
                        child: InkWell(
                          onTap: () {
                            _showBottomSheet(event: event);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "$eventStartTime - $eventEndTime",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        eventTitle,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        eventLocation,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.8),
                                          fontWeight: FontWeight.w400,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.white),
                                  onPressed: () async {
                                    await deleteEvent(
                                      context: context,
                                      event: event,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
