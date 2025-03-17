import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:jcache/jcache.dart';

// Definición de la clase Usuario
class Usuario {
  String nombre;
  String email;
  int edad;

  Usuario({
    required this.nombre,
    required this.email,
    required this.edad,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'email': email,
      'edad': edad,
    };
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      edad: json['edad'] as int,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugger();
  // Inicializar JCacheManager
  await JCacheManager.init();
  // Crear una lista de usuarios de ejemplo
  List<Usuario> usuariosParaCachear = [
    Usuario(nombre: 'Ana García', email: 'ana.garcia@example.com', edad: 28),
    Usuario(nombre: 'Pedro López', email: 'pedro.lopez@example.com', edad: 32),
  ];
  // --- Cachear la lista de usuarios ---
  try {
    // Convertir la lista de objetos Usuario a una lista de Maps para JSON
    List<dynamic> listaUsuariosJson =
        usuariosParaCachear.map((usuario) => usuario.toJson()).toList();
    await JCacheManager.setData(
        key: 'lista_usuarios', value: listaUsuariosJson);
    debugPrint('Lista de usuarios cacheada exitosamente.');
  } catch (e) {
    debugPrint('Error al cachear la lista de usuarios: $e');
    // Salir si falla el cacheo
    return;
  }
  // --- Obtener la lista de usuarios de la caché ---
  try {
    dynamic datosCacheados = await JCacheManager.getData('lista_usuarios');
    if (datosCacheados != null && datosCacheados is List) {
      List<Usuario> usuariosRecuperados = datosCacheados
          .map((itemJson) {
            if (itemJson is Map<String, dynamic>) {
              return Usuario.fromJson(itemJson);
            } else {
              debugPrint(
                  'Error: Elemento en la caché no es un Map<String, dynamic>');
              // o lanzar excepción, según tu manejo de errores
              return null;
            }
          })
          .whereType<Usuario>()
          .toList();

      debugPrint('Lista de usuarios recuperada de la caché:');
      for (var usuario in usuariosRecuperados) {
        debugPrint('- ${usuario.nombre}, ${usuario.email}, ${usuario.edad}');
      }
    } else {
      debugPrint(
          'No se encontraron usuarios en la caché o los datos están en formato incorrecto.');
    }
  } catch (e) {
    debugPrint('Error al obtener la lista de usuarios de la caché: $e');
  }
  // Liberar recursos al finalizar (opcional en este ejemplo corto)
  await JCacheManager.dispose();
}
