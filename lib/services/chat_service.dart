import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _firebaseAvailable = true;

  ChatService() {
    _checkFirebaseAvailability();
  }

  Future<void> _checkFirebaseAvailability() async {
    try {
      await _firestore.collection('_test').limit(1).get();
    } catch (e) {
      _firebaseAvailable = false;
      if (kDebugMode) {
        debugPrint('⚠️ Firebase no disponible para chat: $e');
      }
    }
  }

  /// Enviar mensaje
  Future<ChatMessage?> sendMessage({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
  }) async {
    try {
      if (!_firebaseAvailable) {
        if (kDebugMode) {
          debugPrint('⚠️ Firebase no disponible, no se puede enviar mensaje');
        }
        return null;
      }

      final message = ChatMessage(
        id: '',
        ticketId: ticketId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        imageUrl: imageUrl,
      );

      final docRef = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('messages')
          .add(message.toMap());

      return message.copyWith(id: docRef.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error enviando mensaje: $e');
      }
      return null;
    }
  }

  /// Stream de mensajes de un ticket
  Stream<List<ChatMessage>> getMessagesStream(String ticketId) {
    if (!_firebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Obtener mensajes de un ticket (una vez)
  Future<List<ChatMessage>> getMessages(String ticketId) async {
    try {
      if (!_firebaseAvailable) return [];

      final snapshot = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error obteniendo mensajes: $e');
      }
      return [];
    }
  }

  /// Marcar mensajes como leídos
  Future<void> markMessagesAsRead({
    required String ticketId,
    required String currentUserId,
  }) async {
    try {
      if (!_firebaseAvailable) return;

      final snapshot = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error marcando mensajes como leídos: $e');
      }
    }
  }

  /// Contar mensajes no leídos de un ticket
  Future<int> getUnreadCount({
    required String ticketId,
    required String currentUserId,
  }) async {
    try {
      if (!_firebaseAvailable) return 0;

      final snapshot = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error contando mensajes no leídos: $e');
      }
      return 0;
    }
  }

  /// Enviar mensaje del sistema (notificaciones automáticas)
  Future<void> sendSystemMessage({
    required String ticketId,
    required String content,
  }) async {
    await sendMessage(
      ticketId: ticketId,
      senderId: 'system',
      senderName: 'Sistema',
      content: content,
      type: MessageType.system,
    );
  }

  /// Eliminar mensaje (solo el remitente puede eliminar)
  Future<bool> deleteMessage({
    required String ticketId,
    required String messageId,
    required String currentUserId,
  }) async {
    try {
      if (!_firebaseAvailable) return false;

      final doc = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (doc.exists && doc.data()?['senderId'] == currentUserId) {
        await doc.reference.delete();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error eliminando mensaje: $e');
      }
      return false;
    }
  }
}
