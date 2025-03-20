import 'download_status.dart';

/// Clase que representa un evento de descarga de archivo en JCacheManager.
///
/// `JFileDownloadEvent` se utiliza para encapsular información sobre el estado
/// y progreso de una descarga de archivo en curso o finalizada.  Esta clase
/// permite comunicar de manera estructurada y reactiva los diferentes momentos
/// y datos relevantes durante el proceso de descarga, facilitando el seguimiento
/// y la gestión de las descargas en la aplicación.
///
/// Cada instancia de `JFileDownloadEvent` proporciona detalles esenciales sobre
/// una descarga específica, incluyendo:
///
/// - `resourceUrl`: String - La URL del recurso (archivo) que se está descargando.
///     Esta URL identifica de manera única el archivo que se está procesando
///     en el evento.
///
/// - `status`: JFileDownloadStatus - El estado actual de la descarga, representado
///     por un valor de la enumeración `JFileDownloadStatus`.  Este estado indica
///     si la descarga está inicializada, en curso, completada, si ha ocurrido
///     un error o si ha sido cancelada.
///
/// - `progress`: double - El progreso de la descarga, expresado como un valor
///     decimal entre 0.0 y 1.0.  0.0 indica que la descarga no ha comenzado
///     o no ha avanzado, mientras que 1.0 indica que la descarga está completa
///     (o al 100%).  Este valor es útil para mostrar barras de progreso o
///     indicadores visuales de descarga al usuario.
///
/// - `contentLength`: int - La longitud total del contenido del archivo que se
///     está descargando, en bytes.  Este valor puede ser desconocido al inicio
///     de la descarga (si el servidor no lo proporciona), pero una vez que
///     se conoce (generalmente después de la respuesta inicial del servidor),
///     se utiliza para calcular el progreso y para informar al usuario sobre
///     el tamaño del archivo.
///
/// - `resourcePath`: String? -  Opcional. La ruta local en el sistema de
///     archivos donde se almacenará (o se ha almacenado) el archivo descargado.
///     Este valor se proporciona una vez que se conoce la ubicación de destino
///     del archivo (por ejemplo, al completarse la descarga o al inicializarse
///     si la ruta de destino es predefinida).  Puede ser nulo si la ruta
///     aún no se ha determinado o si el evento no implica el almacenamiento
///     local del archivo.
///
/// - `error`: String? - Opcional.  Un mensaje de error descriptivo en caso de
///     que la descarga haya terminado en un estado de error (`status` ==
///     `JFileDownloadStatus.error`).  Este mensaje proporciona detalles sobre
///     la causa del error y puede ser útil para la depuración, el registro de
///     errores o para mostrar información de error al usuario.  Es nulo si
///     no ha ocurrido ningún error.
class JFileDownloadEvent {
  /// URL del recurso que se está descargando.
  final String resourceUrl;

  /// Estado actual de la descarga.
  final JFileDownloadStatus status;

  /// Progreso de la descarga (0.0 - 1.0).
  final double progress;

  /// Longitud total del contenido del archivo en bytes.
  final int contentLength;

  /// Ruta local del archivo descargado (opcional).
  final String? resourcePath;

  /// Mensaje de error en caso de fallo de descarga (opcional).
  final String? error;

  /// Constructor para crear una instancia de [JFileDownloadEvent].
  ///
  /// Requiere `resourceUrl`, `status`, `progress` y `contentLength` como
  /// parámetros obligatorios para asegurar que cada evento de descarga
  /// contenga la información esencial.  `resourcePath` y `error` son
  /// opcionales y pueden ser proporcionados según el contexto del evento.
  JFileDownloadEvent({
    required this.resourceUrl,
    required this.status,
    required this.progress,
    required this.contentLength,
    this.resourcePath,
    this.error,
  });
}
