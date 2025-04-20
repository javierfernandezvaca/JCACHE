import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'cache_manager.dart';
import 'download_event.dart';
import 'download_status.dart';

/// Clase responsable de la descarga y almacenamiento en caché de archivos desde URLs.
///
/// `JFileDownloader` proporciona una funcionalidad para descargar archivos de
/// recursos remotos (URLs) y gestiona su almacenamiento en caché utilizando
/// [JCacheManager].  Esta clase se encarga de:
///
/// - Iniciar descargas de archivos desde URLs proporcionadas.
/// - Gestionar el progreso de la descarga y notificarlo a través de un Stream.
/// - Almacenar los archivos descargados en el sistema de archivos local.
/// - Utilizar [JCacheManager] para persistir la ruta local del archivo descargado
///   en caché, asociándola a la URL original.
/// - Verificar si un archivo ya está en caché antes de iniciar una nueva descarga,
///   optimizando el proceso y evitando descargas innecesarias.
/// - Permitir la cancelación de descargas en curso.
/// - Gestionar errores durante el proceso de descarga y notificarlos a través
///   del Stream de progreso.
///
/// `JFileDownloader` utiliza la librería `http` para realizar las peticiones
/// de descarga y [JCacheManager] para la gestión de la caché persistente.
/// Proporciona un Stream de eventos ([JFileDownloadEvent]) para que los
/// componentes de la aplicación puedan reaccionar de forma reactiva al
/// progreso y estado de las descargas.
class JFileDownloader {
  /// Controlador de Stream para emitir eventos de progreso de descarga.
  ///
  /// `_controller` es un [StreamController] que se utiliza para enviar eventos
  /// de tipo [JFileDownloadEvent] a todos los suscriptores del Stream
  /// [progressStream].  Utiliza un Stream de tipo 'broadcast' para permitir
  /// que múltiples componentes de la aplicación puedan escuchar los eventos
  /// de progreso de descarga de forma simultánea.
  final StreamController<JFileDownloadEvent> _controller =
      StreamController<JFileDownloadEvent>.broadcast();

  /// Contador de bytes recibidos durante la descarga actual.
  ///
  /// `_bytesReceived` almacena la cantidad de bytes que se han recibido hasta
  /// el momento en la descarga activa.  Se utiliza para calcular el progreso
  /// de la descarga y emitir eventos de progreso actualizados.
  int _bytesReceived = 0;

  /// Longitud total del contenido del archivo a descargar (en bytes).
  ///
  /// `_contentLength` almacena la longitud total del contenido del archivo que
  /// se está descargando.  Este valor se obtiene de la cabecera 'content-length'
  /// de la respuesta HTTP del servidor.  Puede ser 0 o desconocido si el
  /// servidor no proporciona esta información.
  int _contentLength = 0;

  /// Cliente HTTP utilizado para realizar las peticiones de descarga.
  ///
  /// `_client` es una instancia de [http.Client] que se utiliza para realizar
  /// las peticiones HTTP GET para descargar los archivos desde las URLs
  /// proporcionadas.  Se instancia una vez al crear [JFileDownloader] y se
  /// reutiliza para todas las descargas.
  final http.Client _client = http.Client();

  /// URL del recurso que se está descargando actualmente.
  ///
  /// `_url` almacena la URL del recurso que se está descargando en la operación
  /// activa.  Se utiliza para asociar los eventos de descarga con la URL
  /// correspondiente y para la gestión de la caché.
  String? _url;

  /// Respuesta HTTP Streamed de la petición de descarga actual.
  ///
  /// `_response` almacena la respuesta HTTP de tipo [http.StreamedResponse]
  /// obtenida al iniciar la petición de descarga con `http.Client`.  Permite
  /// acceder al Stream de bytes del cuerpo de la respuesta para procesar la
  /// descarga en chunks.
  http.StreamedResponse? _response;

  /// Objeto File que representa el archivo local que se está creando para la descarga.
  ///
  /// `_file` almacena una instancia de [File] que representa el archivo local
  /// en el sistema de archivos donde se está escribiendo el contenido descargado.
  /// Se crea al iniciar la descarga y se utiliza para escribir los chunks de
  /// datos recibidos del Stream de respuesta HTTP.
  File? _file;

  /// Suscripción al Stream de bytes de la respuesta HTTP.
  ///
  /// `_streamSubscription` almacena la suscripción ([StreamSubscription]) al
  /// Stream de bytes del cuerpo de la respuesta HTTP ([_response!.stream]).
  /// Esta suscripción es esencial para controlar el flujo de datos de la
  /// descarga, procesar los chunks de bytes, y para poder cancelar la
  /// suscripción y detener la descarga si es necesario.
  StreamSubscription<List<int>>? _streamSubscription;

  /// Stream de eventos de progreso de descarga.
  ///
  /// `progressStream` expone el Stream subyacente del [_controller] para que
  /// los componentes externos puedan suscribirse y recibir eventos de tipo
  /// [JFileDownloadEvent] que notifican sobre el estado y progreso de las
  /// descargas gestionadas por [JFileDownloader].
  Stream<JFileDownloadEvent> get progressStream => _controller.stream;

  /// Constructor por defecto para crear una instancia de [JFileDownloader].
  ///
  /// Actualmente, el constructor de [JFileDownloader] no requiere ni realiza
  /// ninguna inicialización especial.  Se instancia principalmente para
  /// preparar el objeto para su uso en las operaciones de descarga.
  JFileDownloader() {
    // No se requiere inicialización especial por ahora.
  }

  /// Emite un evento de descarga a través del Stream de progreso.
  ///
  /// `emitEvent` es un método utilitario interno para crear y enviar eventos
  /// de tipo [JFileDownloadEvent] a través del [_controller].  Este método
  /// encapsula la lógica de creación del evento y la adición al Sink del
  /// Stream, asegurando que los eventos se emitan correctamente y solo si
  /// el controlador no está cerrado.
  ///
  /// Parámetros:
  ///
  /// - `resourceUrl`: String - URL del recurso asociado al evento.
  /// - `status`: JFileDownloadStatus - Estado de la descarga.
  /// - `progress`: double - Progreso de la descarga (0.0 - 1.0).
  /// - `contentLength`: int - Longitud total del contenido del archivo.
  /// - `resourcePath`: String? - Ruta local del archivo (opcional).
  /// - `error`: String? - Mensaje de error (opcional).
  void emitEvent({
    required String resourceUrl,
    required JFileDownloadStatus status,
    required double progress,
    required int contentLength,
    String? resourcePath,
    String? error,
  }) {
    if (!_controller.isClosed) {
      _controller.sink.add(JFileDownloadEvent(
        resourceUrl: resourceUrl,
        status: status,
        progress: progress,
        contentLength: contentLength,
        resourcePath: resourcePath,
        error: error,
      ));
    }
  }

  /// Descarga un archivo desde una URL y lo almacena en caché utilizando [JCacheManager].
  ///
  /// `downloadAndCacheFile` es el método principal de [JFileDownloader] para
  /// iniciar el proceso de descarga de un archivo desde una URL dada.  Realiza
  /// las siguientes acciones:
  ///
  /// 1. **Verifica la caché:**  Primero, consulta [JCacheManager] para ver si ya
  ///    existe una ruta de archivo en caché asociada a la URL proporcionada.
  ///    Si existe y el archivo local aún existe en la ruta, se considera que
  ///    el archivo ya está en caché.
  /// 2. **Emite evento 'completed' desde caché (si existe):** Si el archivo
  ///    está en caché, emite un evento [JFileDownloadEvent] con estado
  ///    `JFileDownloadStatus.completed` y devuelve la ruta del archivo en caché
  ///    inmediatamente, evitando una nueva descarga.
  /// 3. **Manejo de URLs locales (file://):**  Si la URL proporcionada no
  ///    comienza con 'http' y se interpreta como una ruta de archivo local,
  ///    verifica si el archivo existe localmente. Si existe, lo almacena en
  ///    caché usando [JCacheManager] y emite un evento 'completed', devolviendo
  ///    la ruta local.
  /// 4. **Descarga desde URL remota (http:// o https://):** Si el archivo no
  ///    está en caché y la URL es remota (http/https), inicia la descarga
  ///    utilizando [http.Client].
  /// 5. **Gestiona el progreso de descarga:**  Mientras se reciben los chunks de
  ///    bytes del Stream de respuesta HTTP, calcula el progreso de la descarga
  ///    y emite eventos [JFileDownloadEvent] con estado `JFileDownloadStatus.downloading`
  ///    y el progreso actual.
  /// 6. **Almacena el archivo localmente:**  Guarda los chunks de bytes recibidos
  ///    en un archivo local temporal en el directorio de documentos de la
  ///    aplicación.
  /// 7. **Almacena la ruta en caché con [JCacheManager]:**  Una vez que la
  ///    descarga se completa exitosamente, almacena la ruta del archivo local
  ///    en la caché utilizando [JCacheManager], asociándola a la URL original.
  /// 8. **Emite evento 'completed' tras descarga exitosa:**  Emite un evento
  ///    [JFileDownloadEvent] con estado `JFileDownloadStatus.completed` y
  ///    devuelve la ruta del archivo local.
  /// 9. **Gestiona errores de descarga:**  Captura excepciones que puedan ocurrir
  ///    durante la descarga (como `SocketException`, `http.ClientException`,
  ///    u otras excepciones generales).  En caso de error:
  ///     - Cancela la suscripción al Stream de descarga.
  ///     - Intenta eliminar el archivo local temporal (si se creó).
  ///     - Emite un evento [JFileDownloadEvent] con estado `JFileDownloadStatus.error`
  ///       y un mensaje de error descriptivo.
  ///     - En caso de `SocketException`, incluye el mensaje de error específico
  ///       de la excepción en el evento.
  ///     - Devuelve una cadena vacía ('') para indicar que la descarga falló.
  ///
  /// Parámetros:
  ///
  /// - `url`: String - La URL del archivo que se desea descargar y cachear.
  /// - `expiryDuration`: Duration? (Opcional) - Duración de expiración para la
  ///     entrada de caché del archivo. Si se proporciona, se utiliza esta
  ///     duración para la caché del archivo en [JCacheManager]. Si no se
  ///     proporciona, se utiliza la duración de expiración por defecto de
  ///     [JCacheManager].
  ///
  /// Devoluciones:
  ///
  /// - Future<String> - Un Future que se completa con la ruta local del
  ///     archivo descargado y cacheado en caso de éxito.  En caso de error
  ///     durante la descarga, el Future se completa con una cadena vacía ('').
  ///
  /// Excepciones:
  ///
  /// Este método maneja internamente las excepciones comunes de descarga
  /// (como errores de red, errores del servidor, etc.) y las notifica a
  /// través del Stream de eventos.  No lanza excepciones directamente, sino
  /// que emite eventos de error y devuelve una cadena vacía en caso de fallo.
  Future<String> downloadAndCacheFile(
    String url, {
    Duration? expiryDuration,
  }) async {
    _url = url;
    // Verificar si el archivo ya está en caché
    String? cachedFilePath = await JCacheManager.getFile(url);
    if ((cachedFilePath != null) && await File(cachedFilePath).exists()) {
      // Si el archivo ya está en caché y el archivo en el sistema de
      // archivos, emitir un evento 'completed'
      emitEvent(
        resourceUrl: url,
        status: JFileDownloadStatus.completed,
        progress: 1.0,
        contentLength: await File(cachedFilePath).length(),
        resourcePath: cachedFilePath,
        error: null,
      );
      // Devolver la ruta del archivo en caché
      return cachedFilePath;
    } else {
      if (!url.startsWith('http') && await File(url).exists()) {
        // Si la URL es una ruta de archivo local y el archivo esta en el
        // sistema de archivos, se almacena en caché
        await JCacheManager.setFile(
          url: url,
          path: url,
        );
        // Emitir un evento 'completed'
        emitEvent(
          resourceUrl: url,
          status: JFileDownloadStatus.completed,
          progress: 1.0,
          contentLength: await File(url).length(),
          resourcePath: url,
          error: null,
        );
        // Devolver la ruta del archivo local
        return url;
      } else {
        // Hacer la descarga del mismo y almacenarlo en caché
        try {
          _response = await _client.send(http.Request('GET', Uri.parse(url)));
          _bytesReceived = 0;
          _contentLength = _response!.contentLength ?? 0;
          // debugPrint('Content Length: $_contentLength');
          final directory = await getApplicationDocumentsDirectory();
          final path = '${directory.path}/${url.split('/').last}';
          _file = File(path);
          final sink = _file!.openWrite();
          _streamSubscription = _response!.stream.listen(
            (chunk) {
              _bytesReceived += chunk.length;
              // debugPrint('Bytes received: $_bytesReceived');
              sink.add(chunk);
              // Emitir un evento 'downloading'
              emitEvent(
                resourceUrl: url,
                status: JFileDownloadStatus.downloading,
                progress: _bytesReceived / _contentLength,
                contentLength: _contentLength,
                resourcePath: null,
                error: null,
              );
            },
            onDone: () async {
              await sink.close();
              await JCacheManager.setFile(
                url: url,
                path: path,
              );
              // Emitir un evento 'completed'
              emitEvent(
                resourceUrl: url,
                status: JFileDownloadStatus.completed,
                progress: 1.0,
                contentLength: _contentLength,
                resourcePath: path,
                error: null,
              );
            },
            onError: (e) async {
              if (e is http.ClientException) {
                debugPrint('Error during download: ${e.message}');
                await _streamSubscription?.cancel();
                if ((_file != null) && await _file!.exists()) {
                  await _file!.delete();
                }
                // Emitir un evento 'error'
                emitEvent(
                  resourceUrl: url,
                  status: JFileDownloadStatus.error,
                  progress: _bytesReceived / _contentLength,
                  contentLength: _contentLength,
                  resourcePath: null,
                  error: e.message,
                );
              } else {
                debugPrint('Error during download: $e');
                await _streamSubscription?.cancel();
                if ((_file != null) && await _file!.exists()) {
                  await _file!.delete();
                }
                // Emitir un evento 'error'
                emitEvent(
                  resourceUrl: url,
                  status: JFileDownloadStatus.error,
                  progress: _bytesReceived / _contentLength,
                  contentLength: _contentLength,
                  resourcePath: null,
                  error: 'Error during download',
                );
              }
            },
          );
          return path;
        } on SocketException catch (e) {
          debugPrint('Error initiating download: ${e.message}');
          await _streamSubscription?.cancel();
          if ((_file != null) && await _file!.exists()) {
            await _file!.delete();
          }
          // Emitir un evento 'error'
          emitEvent(
            resourceUrl: url,
            status: JFileDownloadStatus.error,
            progress: 0,
            contentLength: _contentLength,
            resourcePath: null,
            error: e.message,
          );
          return '';
        } catch (e) {
          debugPrint('Error initiating download');
          await _streamSubscription?.cancel();
          if ((_file != null) && await _file!.exists()) {
            await _file!.delete();
          }
          // Emitir un evento 'error'
          emitEvent(
            resourceUrl: url,
            status: JFileDownloadStatus.error,
            progress: 0,
            contentLength: _contentLength,
            resourcePath: null,
            error: 'Error initiating download',
          );
          return '';
        }
      }
    }
  }

  /// Cancela la descarga de archivo en curso.
  ///
  /// `cancelDownload` permite interrumpir una descarga de archivo que esté
  /// actualmente en progreso.  Realiza las siguientes acciones:
  ///
  /// 1. **Cancela la suscripción al Stream:** Cancela la suscripción al
  ///    [_streamSubscription], lo que detiene el flujo de datos de la descarga
  ///    desde el servidor.
  /// 2. **Elimina el archivo local temporal (si existe):**  Intenta eliminar
  ///    el archivo local que se estaba creando para la descarga (si existe en
  ///    el sistema de archivos).  Esto limpia el archivo incompleto.
  /// 3. **Emite evento 'cancelled':** Emite un evento [JFileDownloadEvent] con
  ///    estado `JFileDownloadStatus.cancelled` para notificar que la descarga
  ///    ha sido cancelada.  El evento incluye información sobre la URL, el
  ///    progreso hasta el momento de la cancelación y la longitud del contenido.
  ///
  /// Devoluciones:
  ///
  /// - Future<void> - Un Future que se completa una vez que se han realizado
  ///     las operaciones de cancelación (cancelación de la suscripción,
  ///     eliminación del archivo temporal y emisión del evento 'cancelled').
  Future<void> cancelDownload() async {
    await _streamSubscription?.cancel();
    if ((_file != null) && await _file!.exists()) {
      await _file!.delete();
    }
    // Emitir un evento 'cancelled'
    emitEvent(
      resourceUrl: _url ?? '',
      status: JFileDownloadStatus.cancelled,
      progress: _bytesReceived / (_response!.contentLength ?? 1),
      contentLength: _contentLength,
      resourcePath: null,
      error: null,
    );
  }

  /// Libera los recursos utilizados por [JFileDownloader].
  ///
  /// `dispose` debe ser llamado cuando ya no se necesita la instancia de
  /// [JFileDownloader] para liberar los recursos que mantiene, especialmente:
  ///
  /// 1. **Cierra el cliente HTTP:** Cierra la conexión del cliente HTTP
  ///    ([_client.close()]), liberando recursos de red y conexiones.
  /// 2. **Cancela la suscripción al Stream (si está activa):**  Asegura que la
  ///    suscripción al Stream de descarga se cancele ([_streamSubscription?.cancel()]),
  ///    deteniendo cualquier transferencia de datos en curso y liberando
  ///    recursos asociados al Stream.
  /// 3. **Cierra el StreamController:** Cierra el [_controller] ([_controller.close()]),
  ///    liberando recursos asociados al Stream y cerrando el canal de
  ///    comunicación de eventos de descarga.
  ///
  /// Es importante llamar a `dispose` para evitar fugas de recursos y asegurar
  /// una correcta limpieza al finalizar el uso de [JFileDownloader].
  ///
  /// Devoluciones:
  ///
  /// - Future<void> - Un Future que se completa una vez que se han liberado
  ///     todos los recursos (cierre del cliente HTTP, cancelación de la
  ///     suscripción y cierre del StreamController).
  Future<void> dispose() async {
    _client.close();
    await _streamSubscription?.cancel();
    await _controller.close();
  }
}
