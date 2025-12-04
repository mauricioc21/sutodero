import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

enum RequestStatus {
  pending('Pendiente'),
  approved('Aprobada'),
  rejected('Rechazada');

  final String displayName;
  const RequestStatus(this.displayName);

  static RequestStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
      case 'pendiente':
        return RequestStatus.pending;
      case 'approved':
      case 'aprobada':
        return RequestStatus.approved;
      case 'rejected':
      case 'rechazada':
        return RequestStatus.rejected;
      default:
        return RequestStatus.pending;
    }
  }
}

class RoleChangeRequest {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final UserRole currentRole;
  final UserRole requestedRole;
  final RequestStatus status;
  final DateTime requestDate;
  final String? adminId;
  final String? adminName;
  final DateTime? responseDate;
  final String? comments;

  RoleChangeRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.currentRole,
    required this.requestedRole,
    required this.status,
    required this.requestDate,
    this.adminId,
    this.adminName,
    this.responseDate,
    this.comments,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'currentRole': currentRole.name,
      'requestedRole': requestedRole.name,
      'status': status.name,
      'requestDate': Timestamp.fromDate(requestDate),
      'adminId': adminId,
      'adminName': adminName,
      'responseDate': responseDate != null ? Timestamp.fromDate(responseDate!) : null,
      'comments': comments,
    };
  }

  // Crear desde Map de Firestore
  factory RoleChangeRequest.fromMap(Map<String, dynamic> map, String id) {
    return RoleChangeRequest(
      id: id,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userEmail: map['userEmail'] as String,
      currentRole: UserRole.fromString(map['currentRole'] as String),
      requestedRole: UserRole.fromString(map['requestedRole'] as String),
      status: RequestStatus.fromString(map['status'] as String),
      requestDate: (map['requestDate'] as Timestamp).toDate(),
      adminId: map['adminId'] as String?,
      adminName: map['adminName'] as String?,
      responseDate: map['responseDate'] != null
          ? (map['responseDate'] as Timestamp).toDate()
          : null,
      comments: map['comments'] as String?,
    );
  }

  // Crear copia con cambios
  RoleChangeRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    UserRole? currentRole,
    UserRole? requestedRole,
    RequestStatus? status,
    DateTime? requestDate,
    String? adminId,
    String? adminName,
    DateTime? responseDate,
    String? comments,
  }) {
    return RoleChangeRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      currentRole: currentRole ?? this.currentRole,
      requestedRole: requestedRole ?? this.requestedRole,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      responseDate: responseDate ?? this.responseDate,
      comments: comments ?? this.comments,
    );
  }

  // Getters de conveniencia
  bool get isPending => status == RequestStatus.pending;
  bool get isApproved => status == RequestStatus.approved;
  bool get isRejected => status == RequestStatus.rejected;
  
  String get statusDisplayName => status.displayName;
  String get currentRoleDisplayName => currentRole.displayName;
  String get requestedRoleDisplayName => requestedRole.displayName;
}
