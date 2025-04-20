# JCACHE

**JCache** es un potente paquete de Flutter diseñado para proporcionar una solución robusta y eficiente de almacenamiento en caché. Optimizado para manejar cualquier tipo de archivo y datos JSON, JCache garantiza que tus recursos estén siempre disponibles y actualizados, mejorando significativamente el rendimiento de tu aplicación y la experiencia del usuario.

## 🚀 Características Principales

- **Gestión Universal de Caché**: Almacena y gestiona cualquier tipo de archivo o datos JSON con facilidad
- **Control Total de Descargas**: Sistema integrado para iniciar, pausar, reanudar y cancelar descargas
- **Caché Inteligente**: Gestión automática de expiración y limpieza de recursos
- **Widgets Optimizados**: Componentes Flutter pre-construidos para una integración sin problemas
- **Gestión de Estado**: Sistema robusto de eventos y controladores para monitorear el estado de la caché
- **Modo Offline**: Acceso a recursos incluso sin conexión a Internet

## 📦 Instalación

Agrega JCache a tu archivo `pubspec.yaml`:

```yaml
dependencies:
  jcache:
    git:
      url: https://github.com/javierfernandezvaca/JCACHE
      ref: master
```

## 🛠 Uso Básico

### Inicialización

```dart
import 'package:jcache/jcache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JCacheManager.init();
  runApp(const MyApp());
}
```

### Gestión Manual de Caché

```dart
// Almacenar datos
await JCacheManager.setData(
  key: 'usuario',
  value: {'nombre': 'Juan', 'edad': 30}
);

// Recuperar datos
final datos = await JCacheManager.getData('usuario');

// Eliminar datos
await JCacheManager.remove('usuario');
```

## 🎯 Características Detalladas

### JCacheManager

Clase principal para la gestión de caché con métodos para:

- Almacenamiento y recuperación de datos
- Gestión de archivos en caché
- Monitoreo de cambios
- Limpieza automática

```dart
// Ejemplo de uso avanzado
final controller = JDownloadController();

controller.progressStream.listen((event) {
  print('Progreso: ${event.progress * 100}%');
});

final filePath = await controller.startDownload(
  'https://ejemplo.com/archivo.pdf',
  expiryDays: 7,
);
```

### JCacheWidget

Widget flexible para la gestión visual de recursos en caché:

```dart
JCacheWidget(
  url: 'https://ejemplo.com/recurso',
  expiryDuration: const Duration(days: 1),
  onInitialized: (event, controller) => const InitializedView(),
  onDownloading: (event, controller) => DownloadProgressView(
    progress: event.progress,
  ),
  onCompleted: (event, controller) => CompletedResourceView(
    path: event.resourcePath!,
  ),
  onError: (event, controller) => const ErrorView(),
)
```

## 📱 Ejemplos

### Cached Network Image

Implementación optimizada para la gestión de imágenes en caché:

```dart
CachedNetworkImage(
  imageUrl: imageUrl,
  expiryDuration: const Duration(days: 1),
)
```

[Ver ejemplo completo](https://github.com/javierfernandezvaca/JCACHE/tree/master/examples/cached_network_image)

### Aplicación de Noticias

Ejemplo completo de una aplicación de noticias con soporte offline:

- Caché de artículos y medios
- Gestión de estado de conectividad
- Interfaz adaptativa

[Ver ejemplo completo](https://github.com/javierfernandezvaca/JCACHE/tree/master/examples/news)

## 🔧 API Completa

### JCacheManager

```dart
// Operaciones básicas
await JCacheManager.setData(key: key, value: value);
await JCacheManager.getData(key);
await JCacheManager.setFile(url: url, path: path);
await JCacheManager.getFile(key);

// Gestión de caché
await JCacheManager.remove(key);
await JCacheManager.clear();
await JCacheManager.garbageCollector();

// Monitoreo
JCacheManager.watch(key).listen((event) { /* ... */ });
JCacheManager.print(key);

// Utilidades
final keys = await JCacheManager.getKeys();
final count = JCacheManager.length;
final isEmpty = JCacheManager.isEmpty;
```

## 📝 Notas Importantes

- Inicializa JCache antes de usar cualquier funcionalidad
- Gestiona adecuadamente la expiración de recursos
- Implementa manejo de errores para casos de fallo de red
- Considera el almacenamiento disponible al definir políticas de caché

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](https://github.com/javierfernandezvaca/JCACHE/tree/master/LICENSE) para más detalles.
