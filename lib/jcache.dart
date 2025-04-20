library jcache;

/// Punto de entrada principal de la librería JCache para Flutter.
///
/// Este archivo `library jcache.dart` define el punto de acceso público a toda
/// la funcionalidad proporcionada por la librería JCache.  Su propósito
/// principal es **re-exportar** los componentes clave de la librería,
/// facilitando a los desarrolladores la importación y el uso de las
/// diferentes clases, enumeraciones y Widgets que conforman JCache.
///
/// Al importar `package:jcache/jcache.dart`, los usuarios de la librería
/// pueden acceder de manera concisa a todas las partes esenciales de JCache,
/// sin tener que importar archivos individuales desde subdirectorios internos.
///
/// Componentes Re-exportados:
///
/// - `cache_manager.dart`:  Define la clase principal [JCacheManager], que
///     proporciona la API central para la gestión de la caché (inicialización,
///     almacenamiento, recuperación, eliminación, limpieza, etc.).  Es el
///     componente fundamental para interactuar con el sistema de caché.
///
/// - `cache_manager_data.dart`:  Define la clase [JCacheManagerData] y la
///     enumeración [JCacheManagerDataType], que representan la estructura de
///     los datos almacenados en la caché y los tipos de datos que puede
///     gestionar JCache (datos serializables y rutas de archivos).
///
/// - `cache_widget.dart`:  Define el Widget [JCacheWidget], que simplifica la
///     construcción de interfaces de usuario reactivas para diferentes estados
///     de descarga de archivos cacheados.  Ofrece callbacks para definir la UI
///     para cada estado de descarga.
///
/// - `download_controller.dart`: Define la clase [JDownloadController], que
///     actúa como un controlador de alto nivel para iniciar, controlar y
///     monitorizar las descargas de archivos gestionadas por [JFileDownloader].
///     Simplifica la interacción con el proceso de descarga.
///
/// - `download_event.dart`:  Define la clase [JFileDownloadEvent], que
///     representa un evento de descarga de archivo y encapsula información
///     sobre el estado y progreso de una descarga en curso o finalizada.
///     Utilizada para la comunicación reactiva del progreso de descarga.
///
/// - `download_status.dart`: Define la enumeración [JFileDownloadStatus], que
///     enumera los posibles estados de una descarga de archivo gestionada
///     por JCacheManager (inicializado, descargando, completado, error,
///     cancelado).  Utilizada para definir el estado de los eventos de descarga.
///
/// En resumen, este archivo `library jcache.dart` actúa como un **punto de
/// acceso unificado** a la librería JCache, exponiendo todos los componentes
/// esenciales para su uso por parte de los desarrolladores de Flutter.
export 'jcache/cache_manager.dart';
export 'jcache/cache_manager_data.dart';
export 'jcache/cache_widget.dart';
export 'jcache/download_controller.dart';
export 'jcache/download_event.dart';
export 'jcache/download_status.dart';
