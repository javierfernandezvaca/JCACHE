import 'dart:async';
import 'package:flutter/material.dart';

import 'download_controller.dart';
import 'download_event.dart';

/// Widget de Flutter que construye la UI de forma reactiva basada en el Stream de eventos de descarga.
///
/// `JCacheStreamBuilder` es un [StatefulWidget] diseñado para simplificar la
/// construcción de interfaces de usuario que reaccionan a los eventos de
/// progreso de descarga de archivos gestionados por un [JDownloadController].
/// Este Widget se encarga de:
///
/// - Iniciar automáticamente la descarga de un archivo al ser insertado en el
///   árbol de Widgets, utilizando un [JDownloadController] proporcionado.
/// - Suscribirse al [progressStream] del [JDownloadController] para recibir
///   eventos de tipo [JFileDownloadEvent] que notifican sobre el estado y
///   progreso de la descarga.
/// - Reconstruir la interfaz de usuario de forma reactiva cada vez que se
///   recibe un nuevo evento de descarga, permitiendo actualizar la UI con
///   información en tiempo real sobre el progreso de la descarga.
/// - Proporcionar un builder ([builder] parameter) que define cómo se debe
///   construir la UI en función del último evento de descarga recibido ([JFileDownloadEvent]).
/// - Gestionar el ciclo de vida del [JDownloadController] y la suscripción al
///   Stream, asegurando la limpieza de recursos al ser removido del árbol de Widgets.
///
/// `JCacheStreamBuilder` es ideal para escenarios donde se necesita mostrar
/// información de progreso de descarga (como barras de progreso, estado de
/// descarga, etc.) y actualizar la UI de forma dinámica mientras se descarga
/// un archivo.
class JCacheStreamBuilder extends StatefulWidget {
  /// URL del archivo que se va a descargar y cachear.
  final String url;

  /// Builder function que define cómo construir el Widget basado en el evento de descarga.
  final Widget Function(BuildContext context, JFileDownloadEvent event) builder;

  /// Controlador de descarga utilizado para gestionar la descarga del archivo.
  final JDownloadController controller;

  /// Duración de expiración opcional para la entrada de caché del archivo.
  final Duration? expiryDuration;

  /// Constructor para crear una instancia de [JCacheStreamBuilder].
  ///
  /// Requiere la [url] del archivo a descargar, un [builder] function para
  /// construir la UI reactiva, y un [controller] ([JDownloadController]) para
  /// gestionar la descarga.  [expiryDuration] es un parámetro opcional para
  /// configurar la expiración de caché.
  const JCacheStreamBuilder({
    super.key,
    required this.url,
    required this.builder,
    required this.controller,
    this.expiryDuration,
  });

  @override
  JCacheStreamBuilderState createState() => JCacheStreamBuilderState();
}

/// Clase de estado para [JCacheStreamBuilder].
///
/// `JCacheStreamBuilderState` gestiona el estado interno del [JCacheStreamBuilder],
/// incluyendo la suscripción al Stream de eventos de descarga y el ciclo de
/// vida del Widget.  Se encarga de iniciar la descarga, suscribirse al Stream,
/// reconstruir el Widget en respuesta a los eventos y liberar los recursos
/// al finalizar el ciclo de vida.
class JCacheStreamBuilderState extends State<JCacheStreamBuilder> {
  /// Suscripción al Stream de eventos de progreso de descarga del controlador.
  ///
  /// `_subscription` almacena la suscripción ([StreamSubscription]) al
  /// [progressStream] del [JDownloadController] ([widget.controller]).  Esta
  /// suscripción es esencial para recibir los eventos de tipo [JFileDownloadEvent]
  /// y para poder cancelar la suscripción al finalizar el ciclo de vida del
  /// Widget en el método [dispose()].
  late final StreamSubscription<JFileDownloadEvent> _subscription;

  @override
  void initState() {
    super.initState();
    // Suscribirse al Stream de progreso del controlador y reconstruir la UI en cada evento.
    _subscription = widget.controller.progressStream.listen(
      (JFileDownloadEvent event) {
        // Llamar a setState para reconstruir el Widget cuando se recibe un nuevo evento.
        setState(() {});
      },
    );
    // Iniciar la descarga del archivo al inicializar el estado.
    widget.controller.startDownload(
      widget.url,
      expiryDuration: widget.expiryDuration,
    );
  }

  @override
  void dispose() {
    // Cancelar la suscripción al Stream para evitar fugas de memoria.
    _subscription.cancel();
    // Liberar los recursos del controlador al finalizar el ciclo de vida del Widget.
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Construir el Widget utilizando el builder proporcionado y el evento de descarga actual.
    return widget.builder(context, widget.controller.currentEvent);
  }
}
