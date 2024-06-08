# JCACHE

**JCache** es un paquete de Flutter que ofrece una solución robusta para el almacenamiento en caché de archivos y datos. Con la capacidad de manejar cualquier tipo de archivo y almacenar datos en formato JSON; también asegura que tus datos estén siempre actualizados y disponibles cuando los necesites.

Además, **JCache** te da un control total sobre el proceso de descarga, permitiéndote iniciar, cancelar y liberar recursos de la caché de manera óptima y automática. Ya sea a nivel de controlador o directamente en la interfaz de usuario, **JCache** facilita la gestión de la caché de archivos facilmente.

- [Características](#características)
- [Instalación](#instalación)
- [Uso](#uso)
  - [JCacheManager](#jcachemanager)
    - [Almacenar Datos en la Caché](#almacenar-datos-en-la-caché)
    - [Recuperar Datos de la Caché](#recuperar-datos-de-la-caché)
    - [Almacenar la Ruta del Archivo en la Caché](#almacenar-la-ruta-del-archivo-en-la-caché)
    - [Recuperar la Ruta del Archivo de la Caché](#recuperar-la-ruta-del-archivo-de-la-caché)
    - [Escuchar Cambios en un Elemento](#escuchar-cambios-en-un-elemento)
    - [Eliminar un Elemento de la Caché](#eliminar-un-elemento-de-la-caché)
    - [Eliminar todos los Elementos de la Caché](#eliminar-todos-los-elementos-de-la-caché)
    - [Obtener Todas las Claves en la Caché](#obtener-todas-las-claves-en-la-caché)
    - [Imprimir un Elemento de la Caché](#imprimir-un-elemento-de-la-caché)
    - [Consultar el Número de Elementos en la Caché](#consultar-el-número-de-elementos-en-la-caché)
    - [Verificar si la Caché está Vacía](#verificar-si-la-caché-está-vacía)
    - [Verificar si la Caché No está Vacía](#verificar-si-la-caché-no-está-vacía)
    - [Comprobar si la Caché Contiene un Elemento](#comprobar-si-la-caché-contiene-un-elemento)
    - [Eliminar los Datos y Archivos Expirados](#eliminar-los-datos-y-archivos-expirados)
    - [Liberar los Recursos de la Caché](#liberar-los-recursos-de-la-caché)
  - [JCacheWidget](#jcachewidget)
  - [JDownloadController](#jdownloadcontroller)
- [Ejemplos](#ejemplos)
- [Resumen](#resumen)

## Características

- **Almacenamiento en caché de archivos**: JCache puede almacenar en caché archivos de cualquier tipo. Los archivos pueden ser locales o descargados de Internet.
- **Almacenamiento en caché de datos**: Además de los archivos, JCache también puede almacenar en caché datos en formato `JSON`.
- **Expiración de los archivos y datos**: Permite definir un tiempo de expiración personalizado para cada elemento en caché. Después de este tiempo, los elementos se consideran obsoletos y se eliminan de la caché.
- **JCacheManager**: Esta es la clase administradora de la caché. Se encarga de todas las operaciones de caché, como almacenar, recuperar y eliminar elementos obsoletos.
- **JCacheWidget**: Este es un widget de Flutter que se encarga de obtener un archivo desde la caché. Si el archivo es local, simplemente lo registra y lo proporciona cuando se solicita. Si el archivo se descarga de Internet, JCacheWidget lo descarga, lo almacena en la caché y luego lo proporciona cuando se solicita.
- **JDownloadController**: Esta es la clase controladora de las descargas. Puedes iniciar descargas, cancelarlas, y liberar los recursos de la caché cuando ya no se necesiten. Esto te da un control total sobre el proceso de descarga y te permite optimizar el uso de la red y la memoria.

## Instalación

Para instalar JCache, añade la librería a tu archivo `pubspec.yaml`:

```yaml
dependencies:
  jcache:
```

## Uso

En Flutter, la gestión de la caché es una parte esencial para garantizar un 
rendimiento óptimo de la aplicación y una experiencia de usuario fluida. `JCacheManager` y `JCacheWidget` son dos formas eficaces de administrar los elementos en la caché.

Para utilizar este paquete después de haberlo instalado, puedes hacerlo de la siguiente manera:

### Importar la biblioteca

```dart
import 'package:jcache/jcache.dart';
```

### Inicializar la caché

```dart
await JCacheManager.init();
```

### Ejemplo de datos

```dart
/// Unique key for the user data
final userKey = 'user';

/// URL of the user's image
final userImageUrl = 'https://example.com/image.png';

/// Local path of the user's image
final userImagePath = '/path/local/image.png';

/// Map containing the user's data
final userData = {
  'name': 'John Doe',
  'age': 35,
  'resourceUrl': userImageUrl,
  'resourcePath': userImagePath,
};
```

## JCacheManager

`JCacheManager` es una clase integral que proporciona una serie de métodos para administrar eficientemente la caché. Cada elemento en la caché se almacena con una clave única y tiene un tiempo de expiración definido, después del cual se elimina automáticamente. Esto asegura un manejo eficiente de la memoria y evita que los elementos en la caché se vuelvan obsoletos.

A continuación, se presentan algunas de las operaciones clave que puedes realizar con `JCacheManager`:

#### Almacenar Datos en la Caché

Para almacenar datos en la caché, puedes utilizar el método `setData`. Este método toma una clave y un valor como argumentos:

```dart
await JCacheManager.setData(key: userKey, value: userData);
```

#### Recuperar Datos de la Caché

Para recuperar datos de la caché, puedes utilizar el método `getData`. Este método devuelve los datos asociados en formato `JSON` con la clave proporcionada:

```dart
Map<String, dynamic>? data = await JCacheManager.getData(userKey);
```

#### Almacenar la Ruta del Archivo en la Caché

Para almacenar la ruta de un archivo en la caché, puedes utilizar el método `setFile`. Este método toma una URL y una ruta como argumentos:

```dart
await JCacheManager.setFile(url: userImageUrl, path: userImagePath);
```

#### Recuperar la Ruta del Archivo de la Caché

Para recuperar la ruta de un archivo de la caché, puedes utilizar el método `getFile`. Este método devuelve la ruta del archivo asociado con la clave proporcionada:

```dart
String? filePath = await JCacheManager.getFile(userKey);
```

#### Escuchar Cambios en un Elemento

Para escuchar los cambios en un elemento específico, puedes utilizar el método `watch`. Este método devuelve un `Stream` que emite eventos cada vez que los datos asociados con la clave proporcionada cambian:

```dart
Stream<JCacheManagerData> userStream = JCacheManager.watch(userKey);
````

```dart
userStream.listen((event) {
  debugPrint('Data changed: ${event.data}');
});
```

#### Eliminar un Elemento de la Caché

Para eliminar un elemento de la caché, puedes utilizar el método `remove`. Este método elimina el elemento asociado con la clave proporcionada:

```dart
JCacheManager.remove(userKey);
```

#### Eliminar todos los Elementos de la Caché

Para limpiar la caché, puedes utilizar el método `clear`. Este método elimina todos los elementos de la caché:

```dart
JCacheManager.clear();
```

#### Obtener Todas las Claves en la Caché

Para obtener todas las claves en la caché, puedes utilizar el método `getKeys`. Este método devuelve una lista de todas las claves en la caché:

```dart
List<String> keys = await JCacheManager.getKeys();
```
#### Imprimir un Elemento de la Caché

Para imprimir un elemento de la caché, puedes utilizar el método `print`. Este método imprime el elemento asociado con la clave proporcionada:

```dart
JCacheManager.print(userKey);
```

#### Consultar el Número de Elementos en la Caché

Para obtener el número de elementos en la caché, puedes utilizar la propiedad `length`:

```dart
int numItems = JCacheManager.length;
```

#### Verificar si la Caché está Vacía

Para verificar si la caché está vacía, puedes utilizar la propiedad `isEmpty`:

```dart
bool isEmpty = JCacheManager.isEmpty;
```

#### Verificar si la Caché No está Vacía

Para verificar si la caché no está vacía, puedes utilizar la propiedad `isNotEmpty`:

```dart
bool isNotEmpty = JCacheManager.isNotEmpty;
```

#### Comprobar si la Caché Contiene un Elemento

Para comprobar si la caché contiene un elemento con una clave dada, puedes utilizar el método `contains`:

```dart
bool isMember = JCacheManager.contains(userKey);
```

#### Eliminar los Datos y Archivos Expirados

Para eliminar los datos y archivos expirados de la caché, puedes utilizar el método `garbageCollector`. Este método puede ser útil para liberar espacio de almacenamiento:

```dart
await JCacheManager.garbageCollector();
```

#### Liberar los Recursos de la Caché

Para liberar los recursos de la caché cuando ya no se necesiten, puedes utilizar el método dispose. Este método debe ser llamado cuando la aplicación se cierra:

```dart
await JCacheManager.dispose();
```

## JCacheWidget

`JCacheWidget` es un widget de Flutter diseñado específicamente para la descarga y administración en caché de archivos. Este widget es especialmente útil cuando se trabaja con archivos que se descargan de Internet, como imágenes, documentos, audios, videos, entre otros.

Cuando se utiliza `JCacheWidget`, el widget intentará primero recuperar el archivo de la caché local. Si el archivo es local, `JCacheWidget` simplemente lo registra en la caché y lo proporciona cuando se solicita. Si el archivo se descarga de Internet, `JCacheWidget` lo descarga, lo almacena en la caché y luego lo proporciona cuando se solicita. Todo este proceso se realiza de manera óptima y automática.

Las ventajas de utilizar `JCacheWidget` incluyen:

- **Eficiencia de la red**: Al reducir la cantidad de descargas necesarias, `JCacheWidget` mejora la eficiencia de la red. Esto puede ser especialmente útil en aplicaciones que manejan una gran cantidad de archivos o datos.
- **Experiencia del usuario**: Al permitir un acceso más rápido a los archivos ya descargados, incluso cuando el dispositivo está `offline`, `JCacheWidget` mejora la experiencia del usuario. Esto puede resultar en una aplicación más fluida y receptiva.
- **Control total sobre el proceso de descarga**: Con `JCacheWidget`, tienes un control total sobre el proceso de descarga. Puedes iniciar la descarga, cancelarla, y liberar los recursos de la caché cuando ya no se necesiten.
- **Flexibilidad**: `JCacheWidget` es muy flexible y puede ser utilizado para una amplia variedad de tareas de almacenamiento en caché. Puedes utilizarlo para almacenar en caché cualquier tipo de archivo, ya sea local o descargado de Internet.

Aquí te dejo un ejemplo de cómo puedes utilizar `JCacheWidget` en tu aplicación:

```dart
JCacheWidget(
  // URL of the file to download
  url: userImageUrl,
  // Expiry time of the file in days
  expiryDays: 5,
  // Events:
  onInitialized: (event, controller) {
    // Widget to display during initialization
    return const Icon(Icons.image);
  },
  onDownloading: (event, controller) {
    // Widget to display while downloading
    return const CircularProgressIndicator();
  },
  onCompleted: (event, controller) {
    // Widget to display when the download is completed
    File archive = File(event.resourcePath!);
    return Image.file(archive);
  },
  onError: (event, controller) {
    // Widget to display in case of error
    return const Text('Error...');
  },  
  onCancelled: (event, controller) {
    // Widget to display if the download is cancelled
    return const Text('Cancelled...');
  },
);
```

En cada uno de los manejadores de eventos, se pasan dos argumentos: `event` y `controller`.

- `event` es una instancia de `JFileDownloadEvent`, que contiene información sobre el estado actual de la descarga, incluyendo la URL del recurso, el estado de la descarga, el progreso de la descarga y otras más.
- `controller` es una instancia de `JDownloadController`, que proporciona métodos para controlar el proceso de descarga. Puedes utilizar controller para iniciar la descarga, cancelar la descarga y más.

## JDownloadController

`JDownloadController` es una clase que proporciona métodos para controlar el proceso de descarga. Con `JDownloadController`, puedes iniciar la descarga, cancelarla, y liberar los recursos de la caché cuando ya no se necesiten. Además, `JDownloadController` te permite escuchar los cambios en el proceso de descarga, lo que te permite actualizar la interfaz de usuario en tiempo real a medida que avanza la descarga.

Aquí tienes un ejemplo sencillo de cómo podrías utilizar `JDownloadController` en tu aplicación:

```dart
// Create an instance of JDownloadController
JDownloadController controller = JDownloadController();

// Start the download
String filePath = await controller.startDownload(
  // URL of the file to download
  userImageUrl,
  // Expiry time of the file in days
  expiryDays: 5,
);

// Listen to changes in the download process
controller.progressStream.listen((JFileDownloadEvent event) {
  print('Status: ${event.status}');
  print('Progress: ${event.progress}');
  
  // Cancel the download if progress is more than 50%,
  // progress is a value between [0, 1]
  if (event.progress > 0.5) {
    controller.cancelDownload();
  }
});

// Release the cache resources when no longer needed
await controller.dispose();
```

## Ejemplos

- [`Cache Network Image`](https://github.com/javierfernandezvaca/JCACHE/tree/master/examples/cached_network_image) - Este ejemplo demuestra cómo puedes utilizar **JCache** para crear un componente similar al paquete [`cached_network_image`](https://pub.dev/packages/cached_network_image) de Flutter. Muestra cómo puedes descargar y almacenar en caché imagenes desde Internet para un acceso rápido y eficiente.
- [`News`](https://github.com/javierfernandezvaca/JCACHE/tree/master/examples/news) - Este es un ejemplo integral que muestra cómo puedes utilizar JCache en una aplicación de noticias en tiempo real. La aplicación utiliza el servicio de noticias de **https://newsapi.org** para obtener las noticias y las almacena en la caché para un acceso rápido. Además, las imágenes de las noticias se almacenan en caché automáticamente con el widget de caché. Al final, se muestra una lista de todas las noticias e imágenes almacenadas en caché, y la aplicación funciona incluso cuando estás offline.

## Resumen

**JCache** es un paquete de Flutter diseñado para el almacenamiento en caché de archivos y datos. Maneja archivos de cualquier tipo y almacena datos en formato `JSON`. Además, permite definir un tiempo de expiración para cada elemento en caché.

Con `JCacheWidget`, puedes descargar y almacenar en caché archivos de manera fácil y eficiente. `JCacheManager` se encarga de todas las operaciones de caché, proporcionando una gestión eficiente de la memoria.

`JDownloadController` te ofrece un control total sobre el proceso de descarga. Puedes iniciar la descarga, cancelarla y liberar los recursos de la caché cuando ya no se necesiten.

En resumen, JCache mejora la eficiencia de tu aplicación, proporciona un acceso más rápido a los datos y archivos necesarios, y te ofrece un control completo sobre el almacenamiento en caché. ¡Feliz codificación! 😊