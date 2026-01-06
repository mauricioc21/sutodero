// Test DIRECTO de Firestore - Sin servicios intermedios
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestFirestoreDirect extends StatefulWidget {
  const TestFirestoreDirect({super.key});

  @override
  State<TestFirestoreDirect> createState() => _TestFirestoreDirectState();
}

class _TestFirestoreDirectState extends State<TestFirestoreDirect> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _resultado = 'Esperando prueba...';
  bool _isLoading = false;

  Future<void> _testWrite() async {
    setState(() {
      _isLoading = true;
      _resultado = '🔄 Iniciando prueba directa...';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _resultado = '❌ Error: Usuario no autenticado';
          _isLoading = false;
        });
        return;
      }

      debugPrint('👤 Usuario autenticado: ${user.uid}');
      debugPrint('📧 Email: ${user.email}');

      // Test 1: Escribir en colección de prueba
      debugPrint('\n📝 Test 1: Escribir en colección test_tickets...');
      
      final testData = {
        'cliente_id': user.uid,
        'clienteId': user.uid,
        'userId': user.uid,
        'maestro_id': null,
        'maestroId': null,
        'titulo': 'Test Directo Firestore',
        'descripcion': 'Prueba de escritura directa sin servicios',
        'estado': 'NUEVO',
        'prioridad': 'MEDIA',
        'fechaCreacion': FieldValue.serverTimestamp(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      debugPrint('📦 DATOS A ENVIAR:');
      testData.forEach((key, value) {
        debugPrint('   $key: $value');
      });

      // Intentar escribir en una colección de prueba primero
      final testRef = await _firestore.collection('test_tickets').add(testData);
      
      debugPrint('✅ Test 1 EXITOSO! ID: ${testRef.id}');
      
      // Test 2: Escribir en colección tickets real
      debugPrint('\n📝 Test 2: Escribir en colección tickets...');
      final ticketRef = await _firestore.collection('tickets').add(testData);
      
      debugPrint('✅ Test 2 EXITOSO! ID: ${ticketRef.id}');

      setState(() {
        _resultado = '''✅ PRUEBA EXITOSA!

Test 1 (test_tickets): ${testRef.id}
Test 2 (tickets): ${ticketRef.id}

Los datos se escribieron correctamente.
El problema NO es de código ni de campos.''';
        _isLoading = false;
      });

    } catch (e, stackTrace) {
      debugPrint('❌ ERROR EN PRUEBA DIRECTA:');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      setState(() {
        _resultado = '''❌ ERROR:

$e

Si el error es "permission-denied":
- Las reglas de Firestore están bloqueando
- Necesitas actualizar las reglas Y esperar 2-3 minutos
- O hay un problema de caché en Firebase

Si el error es diferente, hay otro problema.''';
        _isLoading = false;
      });
    }
  }

  Future<void> _testRead() async {
    setState(() {
      _isLoading = true;
      _resultado = '🔄 Leyendo tickets existentes...';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _resultado = '❌ Error: Usuario no autenticado';
          _isLoading = false;
        });
        return;
      }

      // Leer tickets
      debugPrint('\n📖 Leyendo colección tickets...');
      final snapshot = await _firestore.collection('tickets').get();
      
      debugPrint('📊 Total de tickets encontrados: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        setState(() {
          _resultado = '📭 No hay tickets en la base de datos.';
          _isLoading = false;
        });
        return;
      }

      final tickets = snapshot.docs.map((doc) {
        final data = doc.data();
        return '''
ID: ${doc.id}
Título: ${data['titulo'] ?? 'Sin título'}
Cliente: ${data['clienteId'] ?? data['cliente_id'] ?? 'Sin cliente'}
Estado: ${data['estado'] ?? 'Sin estado'}
---''';
      }).join('\n');

      setState(() {
        _resultado = '''✅ Tickets encontrados: ${snapshot.docs.length}

$tickets''';
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('❌ ERROR AL LEER: $e');
      setState(() {
        _resultado = '❌ Error al leer: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkRules() async {
    setState(() {
      _isLoading = true;
      _resultado = '🔄 Verificando configuración...';
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _resultado = '❌ Error: Usuario no autenticado';
          _isLoading = false;
        });
        return;
      }

      debugPrint('\n🔍 VERIFICANDO CONFIGURACIÓN:');
      debugPrint('Usuario UID: ${user.uid}');
      debugPrint('Email: ${user.email}');
      debugPrint('Email verificado: ${user.emailVerified}');
      debugPrint('Proyecto Firebase: sutoderoapp-ee318');

      // Intentar leer configuración de Firestore
      final settings = _firestore.settings;
      debugPrint('Firestore host: ${settings.host}');
      debugPrint('SSL habilitado: ${settings.sslEnabled}');
      debugPrint('Persistencia: ${settings.persistenceEnabled}');

      setState(() {
        _resultado = '''🔍 CONFIGURACIÓN:

Usuario: ${user.email}
UID: ${user.uid}
Email verificado: ${user.emailVerified}

Firestore:
Host: ${settings.host}
SSL: ${settings.sslEnabled}
Persistencia: ${settings.persistenceEnabled}

Proyecto: sutoderoapp-ee318

Todo parece correcto.
Intenta crear un ticket.''';
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('❌ ERROR: $e');
      setState(() {
        _resultado = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Directo Firestore'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PRUEBA DIRECTA DE FIRESTORE',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Esta pantalla prueba Firestore sin usar servicios intermedios.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkRules,
              icon: const Icon(Icons.settings),
              label: const Text('1. Verificar Configuración'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testRead,
              icon: const Icon(Icons.list),
              label: const Text('2. Leer Tickets Existentes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testWrite,
              icon: const Icon(Icons.create),
              label: const Text('3. Crear Ticket de Prueba'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _resultado,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
