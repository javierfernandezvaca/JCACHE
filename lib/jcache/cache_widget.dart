import 'package:flutter/material.dart';

import 'download_controller.dart';
import 'download_event.dart';
import 'download_status.dart';
import 'stream_builder.dart';

/// Widget de Flutter que simplifica la construcción de UI para diferentes estados de descarga de archivos cacheados.
///
/// `JCacheWidget` es un [StatefulWidget] diseñado para facilitar la creación
/// de interfaces de usuario que muestran diferentes Widgets según el estado
/// de la descarga de un archivo gestionado por [JCacheManager] y [JFileDownloader].
/// Este Widget actúa como un "selector de estado" basado en el estado de la
/// descarga, permitiendo definir Widgets específicos para cada fase del proceso
/// de descarga (inicializado, descargando, completado, error, cancelado).
///
/// `JCacheWidget` simplifica el uso de [JCacheStreamBuilder] al proporcionar
/// una API más declarativa y basada en callbacks para definir la UI para cada
/// estado de descarga.  En lugar de un único builder genérico, `JCacheWidget`
/// ofrece callbacks específicos para cada estado:
///
/// - `onInitialized`:  Widget a mostrar cuando la descarga está inicializada.
/// - `onDownloading`:  Widget a mostrar durante la descarga activa.
/// - `onCompleted`:    Widget a mostrar cuando la descarga se completa con éxito.
/// - `onError`:        Widget a mostrar en caso de error durante la descarga.
/// - `onCancelled`:    Widget a mostrar si la descarga es cancelada.
///
/// `JCacheWidget` internamente utiliza [JCacheStreamBuilder] para gestionar
/// el Stream de eventos de descarga y reconstruir la UI de forma reactiva.
/// Proporciona una forma más organizada y legible de definir la interfaz de
/// usuario para diferentes estados de descarga en comparación con el uso
/// directo de [JCacheStreamBuilder] con una lógica de switch case en el builder.
///
/// `JCacheWidget` es ideal para casos donde se necesita una UI diferenciada y
/// específica para cada estado de la descarga, haciendo el código más limpio
/// y mantenible.
class JCacheWidget extends StatefulWidget {
  /// URL del archivo que se va a descargar y cachear.
  final String url;

  /// Función callback que retorna el Widget a mostrar en el estado 'initialized'.
  final Widget Function(JFileDownloadEvent, JDownloadController) onInitialized;

  /// Función callback que retorna el Widget a mostrar en el estado 'downloading'.
  final Widget Function(JFileDownloadEvent, JDownloadController) onDownloading;

  /// Función callback que retorna el Widget a mostrar en el estado 'completed'.
  final Widget Function(JFileDownloadEvent, JDownloadController) onCompleted;

  /// Función callback que retorna el Widget a mostrar en el estado 'error'.
  final Widget Function(JFileDownloadEvent, JDownloadController) onError;

  /// Función callback que retorna el Widget a mostrar en el estado 'cancelled'.
  final Widget Function(JFileDownloadEvent, JDownloadController) onCancelled;

  /// Duración de expiración opcional para la entrada de caché del archivo.
  final Duration? expiryDuration;

  /// Constructor para crear una instancia de [JCacheWidget].
  ///
  /// Requiere la [url] del archivo a descargar y funciones callback ([onInitialized],
  /// [onDownloading], [onCompleted], [onError], [onCancelled]) para definir
  /// los Widgets a mostrar para cada estado de descarga.  [expiryDuration] es
  /// un parámetro opcional para configurar la expiración de caché.
  const JCacheWidget({
    Key? key,
    required this.url,
    required this.onInitialized,
    required this.onDownloading,
    required this.onCompleted,
    required this.onError,
    required this.onCancelled,
    this.expiryDuration,
  }) : super(key: key);

  @override
  JCacheWidgetState createState() => JCacheWidgetState();
}

/// Clase de estado para [JCacheWidget].
///
/// `JCacheWidgetState` gestiona el estado interno de [JCacheWidget],
/// principalmente la creación y gestión del [JDownloadController] que se
/// utiliza para la descarga. También implementa [AutomaticKeepAliveClientMixin]
/// para mantener el estado del Widget vivo incluso cuando no está completamente
/// visible, lo cual puede ser útil en ciertos escenarios de UI (como en
/// [TabView] o [PageView]).
class JCacheWidgetState extends State<JCacheWidget>
    with AutomaticKeepAliveClientMixin {
  /// Controlador de descarga utilizado por [JCacheWidget] para gestionar la descarga del archivo.
  ///
  /// `controller` es una instancia de [JDownloadController] que se crea en
  /// [initState()] y se utiliza para iniciar la descarga del archivo especificado
  /// por [widget.url].  Este controlador se pasa al [JCacheStreamBuilder] interno
  /// para gestionar el Stream de eventos de descarga.
  late JDownloadController controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Inicializar el controlador de descarga en initState.
    controller = JDownloadController();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Retornar un JCacheStreamBuilder que gestiona la UI reactiva basada en el estado de descarga.
    return JCacheStreamBuilder(
      controller: controller,
      url: widget.url,
      expiryDuration: widget.expiryDuration,
      builder: (context, event) {
        // Utilizar callbacks proporcionados para construir la UI basada en el estado de descarga.
        if (event.status == JFileDownloadStatus.downloading) {
          return widget.onDownloading(event, controller);
        } else if (event.status == JFileDownloadStatus.completed) {
          return widget.onCompleted(event, controller);
        } else if (event.status == JFileDownloadStatus.error) {
          return widget.onError(event, controller);
        } else if (event.status == JFileDownloadStatus.cancelled) {
          return widget.onCancelled(event, controller);
        } else {
          // Estado por defecto: initialized
          return widget.onInitialized(event, controller);
        }
      },
    );
  }
}
