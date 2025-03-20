/// Enumeración que define los tipos de datos que puede manejar JCacheManager.
///
/// Actualmente, JCacheManager soporta dos tipos principales de datos para
/// almacenar en caché:
///
/// - `data`:  Representa datos serializables en formato JSON (como Maps,
///     Listas, Strings, números, objetos personalizados serializables, etc.).
///     Este tipo se utiliza para almacenar resultados de APIs, configuraciones,
///     o cualquier dato estructurado que se pueda convertir a JSON.
///
/// - `file`:  Indica que se está almacenando la ruta a un archivo local en
///     la caché. Este tipo se usa para cachear la ubicación de archivos
///     descargados (imágenes, documentos, etc.) o generados localmente.
///
/// La distinción entre estos tipos permite a JCacheManager gestionar
/// de manera diferenciada el tratamiento y la validación de los elementos
/// en caché, especialmente en el caso de los archivos, donde se verifica
/// su existencia en el sistema de archivos al recuperarlos de la caché.
enum JCacheManagerDataType {
  data,
  file,
}

/// Clase que define la estructura de los datos almacenados en la caché de JCacheManager.
///
/// `JCacheManagerData` encapsula toda la información necesaria para gestionar
/// un elemento en caché, ya sea un dato serializable o la ruta a un archivo.
/// Cada instancia de `JCacheManagerData` representa un registro completo
/// dentro de la caché y contiene los siguientes atributos:
///
/// - `originalKey`: String - La clave original proporcionada por el usuario
///     al almacenar el dato o archivo. Esta clave se utiliza para la
///     identificación lógica del elemento en la aplicación.  Internamente,
///     JCacheManager utiliza una clave hash derivada de `originalKey` para
///     el almacenamiento en Hive, pero `originalKey` se conserva para
///     propósitos de trazabilidad y depuración.
///
/// - `data`: Map<String, dynamic> -  Un Map que contiene los datos
///     propiamente dichos del elemento en caché.  La estructura y el contenido
///     de este Map varían según el `dataType`:
///     - Para `dataType` == `JCacheManagerDataType.data`:  `data` contendrá
///       al menos las claves 'key' (replicando la clave original) y 'data'
///       (almacenando el valor serializable).  Podría contener información
///       adicional específica del tipo de dato si fuera necesario en el futuro.
///     - Para `dataType` == `JCacheManagerDataType.file`:  `data` contendrá
///       claves específicas para la gestión de archivos, como 'resourceUrl'
///       (la URL asociada al archivo, si aplica) y 'resourcePath' (la ruta
///       local del archivo en el sistema de archivos).
///
/// - `dataType`: JCacheManagerDataType -  Indica el tipo de dato almacenado
///     (data o file), según la enumeración `JCacheManagerDataType`.
///
/// - `expiryDuration`: Duration -  La duración de expiración configurada para
///     este elemento específico de la caché.  Después de este período de tiempo
///     transcurrido desde `updatedAt`, el elemento se considera expirado y
///     podrá ser eliminado por el recolector de basura.
///
/// - `createdAt`: DateTime -  Fecha y hora en la que el elemento fue
///     creado originalmente en la caché.  Esta fecha se establece solo una vez,
///     en el momento de la primera inserción del elemento.
///
/// - `updatedAt`: DateTime -  Fecha y hora de la última vez que el elemento
///     fue actualizado o accedido en la caché.  Esta fecha se actualiza cada
///     vez que se modifica o se recupera el elemento (si se proporciona una
///     nueva `expiryDuration` en `getData` o `getFile`).
///
/// `JCacheManagerData` proporciona métodos `fromJson` y `toJson` para
/// facilitar la serialización y deserialización de la estructura desde y
/// hacia formato JSON, lo cual es esencial para el almacenamiento persistente
/// en Hive y para la manipulación de los datos en la librería.
class JCacheManagerData {
  /// Clave original proporcionada por el usuario.
  String originalKey;

  /// Mapa que contiene los datos del elemento en caché.
  Map<String, dynamic> data;

  /// Tipo de dato almacenado en caché.
  JCacheManagerDataType dataType;

  /// Duración de expiración para este elemento.
  Duration expiryDuration;

  /// Fecha y hora de creación del elemento.
  DateTime createdAt;

  /// Fecha y hora de la última actualización del elemento.
  DateTime updatedAt;

  /// Constructor para crear una instancia de [JCacheManagerData].
  ///
  /// Requiere todos los parámetros para asegurar que cada registro de caché
  /// esté completamente definido.
  JCacheManagerData({
    required this.originalKey,
    required this.data,
    required this.dataType,
    required this.expiryDuration,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory method para crear una instancia de [JCacheManagerData] desde un mapa JSON.
  ///
  /// Utiliza la estructura de un mapa JSON (deserializado desde Hive) para
  /// reconstruir un objeto [JCacheManagerData]. Esencial para la
  /// deserialización de datos desde el almacenamiento persistente.
  ///
  /// Parámetros:
  ///
  /// - `jsonData`: Map<String, dynamic> - Mapa JSON que representa los datos
  ///     serializados de un [JCacheManagerData].
  ///
  /// Devoluciones:
  ///
  /// - [JCacheManagerData] - Una nueva instancia de [JCacheManagerData]
  ///     creada a partir del mapa JSON proporcionado.
  static JCacheManagerData fromJson(Map<String, dynamic> jsonData) {
    return JCacheManagerData(
      originalKey: jsonData['originalKey'] as String,
      data: jsonData['data'] as Map<String, dynamic>,
      dataType: jsonData['dataType'] == 'data'
          ? JCacheManagerDataType.data
          : JCacheManagerDataType.file,
      expiryDuration: Duration(
        milliseconds: jsonData['expiryDuration'],
      ),
      createdAt: DateTime.parse(jsonData['createdAt'] as String),
      updatedAt: DateTime.parse(jsonData['updatedAt'] as String),
    );
  }

  /// Método para convertir una instancia de [JCacheManagerData] a un mapa JSON.
  ///
  /// Serializa la instancia de [JCacheManagerData] a un mapa JSON que puede
  /// ser almacenado en Hive.  Este método es el inverso de [fromJson].
  ///
  /// Devoluciones:
  ///
  /// - Map<String, dynamic> - Un mapa JSON que representa la instancia de
  ///     [JCacheManagerData] serializada.
  Map<String, dynamic> toJson() {
    return {
      'originalKey': originalKey,
      'data': data,
      'dataType': dataType == JCacheManagerDataType.data ? 'data' : 'file',
      'expiryDuration': expiryDuration.inMilliseconds,
      'createdAt': createdAt.toString(),
      'updatedAt': updatedAt.toString(),
    };
  }
}
