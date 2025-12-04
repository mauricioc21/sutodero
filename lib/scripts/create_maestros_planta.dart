// Script para crear maestros de planta en Firestore
// Este script debe ejecutarse desde la aplicación Flutter

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Crear maestros de planta en Firebase
Future<void> createMaestrosPlanta() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  debugPrint('=' * 60);
  debugPrint('🔧 CREANDO MAESTROS DE PLANTA');
  debugPrint('=' * 60);

  // Maestro 1: Rodrigo
  try {
    debugPrint('\n👷 Maestro 1: Rodrigo');
    debugPrint('-' * 60);
    
    final rodrigoCredential = await auth.createUserWithEmailAndPassword(
      email: 'rodrigo.maestro@sutodero.com',
      password: 'SuTodero2025!',
    );
    
    await firestore.collection('users').doc(rodrigoCredential.user!.uid).set({
      'uid': rodrigoCredential.user!.uid,
      'nombre': 'Rodrigo',
      'email': 'rodrigo.maestro@sutodero.com',
      'rol': 'maestro',
      'telefono': '+57 300 123 4567',
      'fechaCreacion': FieldValue.serverTimestamp(),
      'activo': true,
    });
    
    debugPrint('✅ Rodrigo creado exitosamente');
    debugPrint('   UID: ${rodrigoCredential.user!.uid}');
    
  } catch (e) {
    debugPrint('⚠️ Error creando Rodrigo: $e');
    // Si ya existe, solo mostrar advertencia
    if (e.toString().contains('email-already-in-use')) {
      debugPrint('   El correo ya está en uso');
    }
  }

  // Maestro 2: Alexander
  try {
    debugPrint('\n👷 Maestro 2: Alexander');
    debugPrint('-' * 60);
    
    final alexanderCredential = await auth.createUserWithEmailAndPassword(
      email: 'alexander.maestro@sutodero.com',
      password: 'SuTodero2025!',
    );
    
    await firestore.collection('users').doc(alexanderCredential.user!.uid).set({
      'uid': alexanderCredential.user!.uid,
      'nombre': 'Alexander',
      'email': 'alexander.maestro@sutodero.com',
      'rol': 'maestro',
      'telefono': '+57 301 234 5678',
      'fechaCreacion': FieldValue.serverTimestamp(),
      'activo': true,
    });
    
    debugPrint('✅ Alexander creado exitosamente');
    debugPrint('   UID: ${alexanderCredential.user!.uid}');
    
  } catch (e) {
    debugPrint('⚠️ Error creando Alexander: $e');
    // Si ya existe, solo mostrar advertencia
    if (e.toString().contains('email-already-in-use')) {
      debugPrint('   El correo ya está en uso');
    }
  }

  debugPrint('\n' + '=' * 60);
  debugPrint('✅ PROCESO COMPLETADO');
  debugPrint('=' * 60);
  
  debugPrint('\n📋 CREDENCIALES DE ACCESO:');
  debugPrint('-' * 60);
  debugPrint('\n👤 Rodrigo:');
  debugPrint('   Email: rodrigo.maestro@sutodero.com');
  debugPrint('   Password: SuTodero2025!');
  
  debugPrint('\n👤 Alexander:');
  debugPrint('   Email: alexander.maestro@sutodero.com');
  debugPrint('   Password: SuTodero2025!');
  
  debugPrint('\n' + '=' * 60);
}
