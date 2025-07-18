import 'package:birthday/services/notifications_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

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
    final eventId = DateTime.now().millisecondsSinceEpoch % 100000;

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
      'notificationId': eventId,
    });

    // Programar notificación si hay hora de inicio
    if (startTime != null) {
      await NotificationService.scheduleEventNotification(
        id: eventId,
        title: 'Recordatorio: ${eventTitleController.text}',
        body: 'El evento comienza pronto en ${locationController.text}',
        scheduledTime: startTime,
        color: selectedTagColor,
      );
    }

    eventTitleController.clear();
    locationController.clear();
    notesController.clear();

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
    final eventData = event.data() as Map<String, dynamic>;
    final eventId =
        eventData['notificationId'] ??
        DateTime.now().millisecondsSinceEpoch % 100000;

    // Cancelar notificación anterior si existe
    await NotificationService.cancelScheduledNotification(eventId);

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
          'notificationId': eventId,
        });

    // Programar nueva notificación si hay hora de inicio
    if (startTime != null) {
      await NotificationService.scheduleEventNotification(
        id: eventId,
        title: 'Recordatorio: ${eventTitleController.text}',
        body: 'El evento comienza pronto en ${locationController.text}',
        scheduledTime: startTime,
        color: selectedTagColor,
      );
    }

    eventTitleController.clear();
    locationController.clear();
    notesController.clear();

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
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Eliminar"),
          ),
        ],
      );
    },
  );

  if (confirmDelete == true) {
    try {
      final eventData = event.data() as Map<String, dynamic>;
      final eventId = eventData['notificationId'];

      // Cancelar notificación si existe
      if (eventId != null) {
        await NotificationService.cancelScheduledNotification(eventId);
      }

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
