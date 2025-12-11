import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/models/ticket_model.dart';

void main() {
  group('Ticket Creation & Serialization Tests', () {
    test('TicketModel should correctly serialize to Map', () {
      final date = DateTime(2023, 1, 1, 12, 0);
      final ticket = TicketModel(
        id: 'test-id-123',
        codigo: 'TKT-123',
        titulo: 'Reparación de Prueba',
        descripcion: 'Detalle de prueba',
        estado: TicketStatus.nuevo,
        prioridad: TicketPriority.alta,
        fechaCreacion: date,
        userId: 'coord-user-1',
        tipoServicio: ServiceType.electricidad,
        clienteId: 'client-1',
        clienteNombre: 'Cliente Test',
        ubicacionDireccion: 'Calle Falsa 123',
        fechaActualizacion: date,
      );

      final map = ticket.toMap();

      expect(map['id'], 'test-id-123');
      expect(map['titulo'], 'Reparación de Prueba');
      expect(map['userId'], 'coord-user-1'); // Critical for Coordinator visibility
      expect(map['estado'], 'nuevo');
      expect(map['fechaCreacion'], isA<Timestamp>());
    });

    test('TicketModel should correctly deserialize from Map', () {
      final date = DateTime.now();
      final map = {
        'id': 'test-id-456',
        'codigo': 'TKT-456',
        'titulo': 'Fuga de Agua',
        'descripcion': 'Urgente',
        'estado': 'en_ejecucion',
        'prioridad': 'urgente',
        'fechaCreacion': Timestamp.fromDate(date),
        'fechaActualizacion': Timestamp.fromDate(date),
        'userId': 'coord-user-1',
        'tipoServicio': 'plomeria',
        'cliente': {
          'id': 'client-2',
          'nombre': 'Cliente 2',
        },
        'ubicacion': {
          'direccion': 'Avenida Siempre Viva',
        }
      };

      final ticket = TicketModel.fromMap(map, 'test-id-456');

      expect(ticket.id, 'test-id-456');
      expect(ticket.estado, TicketStatus.en_ejecucion);
      expect(ticket.userId, 'coord-user-1'); // Critical check
      expect(ticket.clienteNombre, 'Cliente 2');
    });
  });
}
