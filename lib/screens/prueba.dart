import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class Prueba extends StatefulWidget {
  const Prueba({super.key});

  @override
  State<Prueba> createState() => _PruebaState();
}

class _PruebaState extends State<Prueba> {
  @override
  void initState() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    super.initState();
    // Aquí puedes inicializar cualquier cosa que necesites
  }

  triggerNotification() {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        title: 'Notificación de Prueba',
        body: 'Esta es una notificación de prueba.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba')),
      body: Center(
        child: ElevatedButton(
          onPressed: triggerNotification,
          child: const Text('Enviar Notificación'),
        ),
      ),
    );
  }
}
