import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toastification/toastification.dart';

//Add function
Future<void> addEvent({
  required BuildContext context,
  required DateTime today,
  required TextEditingController eventTitleController,
  required TextEditingController locationController,
  required TextEditingController notesController,
  required bool isAllDay,
  required bool isRepeating,
  required DateTime? startTime,
  required DateTime? endTime,
  required Color selectedTagColor,
}) async {
  try {
    // Guardar el evento en Firebase
    await FirebaseFirestore.instance.collection('birthday').add({
      'date': today.toIso8601String(),
      'title': eventTitleController.text,
      'location': locationController.text,
      'notes': notesController.text,
      'isAllDay': isAllDay,
      'isRepeating': isRepeating,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'tagColor': selectedTagColor.value,
    });

    // Programar notificación

    // Limpiar los campos después de guardar
    eventTitleController.clear();
    locationController.clear();
    notesController.clear();

    // Mostrar toast de éxito
    toastification.show(
      context: context,
      title: Text("Evento guardado"),
      description: Text("El evento se ha guardado correctamente."),
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: Duration(seconds: 3),
    );
  } catch (e) {
    print("Error al guardar el evento: $e");
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Error al guardar el evento")));
  }
}

//Delete function
Future<void> deleteEvent({
  required BuildContext context,
  required DocumentSnapshot event,
}) async {
  bool? confirmDelete = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Confirmar eliminación"),
        content: Text("¿Estás seguro de que deseas eliminar este evento?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text("Eliminar"),
          ),
        ],
      );
    },
  );

  if (confirmDelete == true) {
    try {
      await FirebaseFirestore.instance
          .collection('birthday')
          .doc(event.id)
          .delete();
      toastification.show(
        context: context,
        title: Text("Evento eliminado"),
        description: Text("El evento se ha eliminado correctamente."),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 3),
      );
    } catch (e) {
      print("Error al eliminar el evento: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al eliminar el evento")));
    }
  } else {
    toastification.show(
      context: context,
      title: Text("Eliminación cancelada"),
      description: Text("La eliminación del evento ha sido cancelada."),
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: Duration(seconds: 3),
    );
  }
}

//Edit function
Future<void> editEvent({
  required BuildContext context,
  required DocumentSnapshot event,
  required DateTime today,
  required TextEditingController eventTitleController,
  required TextEditingController locationController,
  required TextEditingController notesController,
  required bool isAllDay,
  required bool isRepeating,
  required DateTime? startTime,
  required DateTime? endTime,
  required Color selectedTagColor,
}) async {
  try {
    // Actualizar el evento en Firebase
    await FirebaseFirestore.instance
        .collection('birthday')
        .doc(event.id)
        .update({
          'date': today.toIso8601String(),
          'title': eventTitleController.text,
          'location': locationController.text,
          'notes': notesController.text,
          'isAllDay': isAllDay,
          'isRepeating': isRepeating,
          'startTime': startTime?.toIso8601String(),
          'endTime': endTime?.toIso8601String(),
          'tagColor': selectedTagColor.value,
        });

    // Programar notificación

    // Limpiar los campos después de guardar
    eventTitleController.clear();
    locationController.clear();
    notesController.clear();

    // Mostrar toast de éxito
    toastification.show(
      context: context,
      title: Text("Evento actualizado"),
      description: Text("El evento se ha actualizado correctamente."),
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: Duration(seconds: 3),
    );
  } catch (e) {
    print("Error al actualizar el evento: $e");
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Error al actualizar el evento")));
  }
}
