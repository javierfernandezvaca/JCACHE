import 'download_event.dart';
import 'download_status.dart';
import 'file_downloader.dart';

/// Clase controladora para gestionar el proceso de descarga de archivos.
///
/// `JDownloadController` actúa como una interfaz de alto nivel para iniciar,
/// controlar y monitorizar las descargas de archivos.  Su principal función
/// es simplificar la interacción con el proceso de descarga, delegando la
/// lógica de descarga real a [JFileDownloader] y proporcionando una forma
/// más sencilla de iniciar descargas, cancelar y obtener el Stream de progreso.
///
/// `JDownloadController` encapsula una instancia de [JFileDownloader] y
/// ofrece métodos para:
///
/// - Iniciar una descarga de archivo desde una URL (`startDownload`).
/// - Cancelar una descarga en curso (`cancelDownload`).
/// - Liberar los recursos utilizados por el descargador (`dispose`).
/// - Acceder a un Stream de eventos de progreso de descarga (`progressStream`).
/// - Mantener el último evento de descarga recibido (`currentEvent`) para
///   consultar el estado actual de la descarga.
///
/// Esta clase está diseñada para ser utilizada por componentes de la aplicación
/// que necesiten iniciar y gestionar descargas de archivos sin tener que
/// interactuar directamente con la complejidad de [JFileDownloader].
class JDownloadController {
  /// Instancia de [JFileDownloader] utilizada para realizar las descargas.
  ///
  /// `_fileDownloader` es la instancia interna de [JFileDownloader] que
  /// `JDownloadController` utiliza para ejecutar las operaciones de descarga
  /// de archivos.  `JDownloadController` delega la lógica de descarga a
  /// esta instancia y actúa como un punto de acceso simplificado para
  /// iniciar, cancelar y monitorizar las descargas.
  late JFileDownloader _fileDownloader;

  /// Almacena el evento de descarga más reciente recibido del Stream de progreso.
  ///
  /// `currentEvent` mantiene una referencia al último evento de tipo
  /// [JFileDownloadEvent] que se ha recibido a través del Stream de progreso
  /// de [_fileDownloader].  Esto permite a los consumidores de `JDownloadController`
  /// acceder al estado de descarga más actual sin tener que suscribirse
  /// directamente al Stream.  Se inicializa con un evento de estado
  /// `JFileDownloadStatus.initialized` al crear el controlador.
  JFileDownloadEvent currentEvent = JFileDownloadEvent(
    resourceUrl: '',
    status: JFileDownloadStatus.initialized,
    progress: 0,
    contentLength: 0,
    resourcePath: null,
  );

  /// Stream de eventos de progreso de descarga expuesto por el controlador.
  ///
  /// `progressStream` proporciona acceso al Stream de eventos de progreso de
  /// descarga que emite la instancia interna de [_fileDownloader].  A través
  /// de este Stream, los componentes de la aplicación pueden suscribirse
  /// para recibir notificaciones reactivas sobre el estado y el progreso de
  /// las descargas iniciadas a través de este controlador.  Simplemente
  /// re-expone el `progressStream` de la instancia de [JFileDownloader].
  Stream<JFileDownloadEvent> get progressStream =>
      _fileDownloader.progressStream;

  /// Constructor por defecto para crear una instancia de [JDownloadController].
  ///
  /// El constructor de [JDownloadController] se encarga de inicializar la
  /// instancia interna de [JFileDownloader] ([_fileDownloader]) que se
  /// utilizará para gestionar las descargas.  No requiere parámetros y
  /// prepara el controlador para su uso inmediato.
  JDownloadController() {
    _fileDownloader = JFileDownloader();
  }

  /// Inicia la descarga de un archivo desde una URL y gestiona el proceso.
  ///
  /// `startDownload` es el método principal de [JDownloadController] para
  /// iniciar una descarga de archivo.  Realiza las siguientes acciones:
  ///
  /// 1. **Suscribe al Stream de progreso:**  Se suscribe al `progressStream`
  ///    de la instancia de [_fileDownloader] para recibir eventos de progreso
  ///    de descarga.  Cada evento recibido se asigna a la propiedad
  ///    `currentEvent` para mantener actualizado el último estado de la descarga.
  /// 2. **Inicia la descarga en [JFileDownloader]:**  Llama al método
  ///    `downloadAndCacheFile` de [_fileDownloader] para iniciar la descarga
  ///    real del archivo desde la URL proporcionada.  También pasa el parámetro
  ///    opcional `expiryDuration` para configurar la expiración en caché si
  ///    se proporciona.
  /// 3. **Devuelve el Future de la descarga:**  Retorna el [Future<String>]
  ///    devuelto por `_fileDownloader.downloadAndCacheFile`.  Este Future se
  ///    completará con la ruta local del archivo descargado y cacheado en caso
  ///    de éxito, o con una cadena vacía en caso de error durante la descarga.
  ///
  /// Parámetros:
  ///
  /// - `url`: String - La URL del archivo que se desea descargar.
  /// - `expiryDuration`: Duration? (Opcional) - Duración de expiración para
  ///     la entrada de caché del archivo. Se pasa directamente a
  ///     `_fileDownloader.downloadAndCacheFile`.
  ///
  /// Devoluciones:
  ///
  /// - Future<String> - Un Future que se completa con la ruta local del
  ///     archivo descargado y cacheado en caso de éxito, o con una cadena
  ///     vacía en caso de error.  Este Future es el mismo que se obtiene al
  ///     llamar directamente a `_fileDownloader.downloadAndCacheFile`.
  Future<String> startDownload(
    String url, {
    Duration? expiryDuration,
  }) {
    _fileDownloader.progressStream.listen((JFileDownloadEvent event) {
      currentEvent = event;
    });
    return _fileDownloader.downloadAndCacheFile(
      url,
      expiryDuration: expiryDuration,
    );
  }

  /// Cancela la descarga de archivo en curso, delegando la acción a [JFileDownloader].
  ///
  /// `cancelDownload` delega la operación de cancelación de la descarga al
  /// método `cancelDownload` de la instancia interna de [_fileDownloader].
  /// Simplemente llama al método correspondiente de [JFileDownloader] para
  /// realizar la cancelación efectiva.
  ///
  /// Devoluciones:
  ///
  /// - Future<void> - Un Future que se completa una vez que la operación de
  ///     cancelación ha finalizado en [JFileDownloader].
  Future<void> cancelDownload() async {
    await _fileDownloader.cancelDownload();
  }

  /// Libera los recursos utilizados por el controlador y su descargador interno.
  ///
  /// `dispose` se encarga de liberar los recursos mantenidos por `JDownloadController`
  /// y, lo que es más importante, delega la liberación de recursos a la
  /// instancia interna de [_fileDownloader] llamando a su método `dispose`.
  /// Esto asegura que todos los recursos asociados con la descarga, incluyendo
  /// el cliente HTTP, la suscripción al Stream y el StreamController, sean
  /// liberados correctamente.
  ///
  /// Devoluciones:
  ///
  /// - Future<void> - Un Future que se completa una vez que se han liberado
  ///     todos los recursos, incluyendo la llamada a `_fileDownloader.dispose()`.
  Future<void> dispose() async {
    await _fileDownloader.dispose();
  }
}
