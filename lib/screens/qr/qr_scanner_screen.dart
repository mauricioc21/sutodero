import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/qr_service.dart';
import '../../services/inventory_service.dart';
import '../../services/ticket_service.dart';
import '../inventory/property_detail_screen.dart';
import '../inventory/room_detail_screen.dart';
import '../tickets/ticket_detail_screen.dart';
import '../../config/app_theme.dart';

/// Pantalla para escanear códigos QR
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final QRService _qrService = QRService();
  final InventoryService _inventoryService = InventoryService();
  final TicketService _ticketService = TicketService();
  
  MobileScannerController? controller;
  String? scannedCode;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture barcodeCapture) async {
    if (isProcessing) return;
    
    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    await _processQRCode(code);
  }

  Future<void> _processQRCode(String code) async {
    if (isProcessing) return;
    
    setState(() {
      isProcessing = true;
      scannedCode = code;
    });

    // Parsear QR code
    final qrData = _qrService.parseQRCode(code);
    
    if (qrData == null || !mounted) {
      _showError('Código QR no válido');
      setState(() => isProcessing = false);
      return;
    }

    // Navegar según el tipo
    try {
      switch (qrData.type) {
        case QREntityType.property:
          await _navigateToProperty(qrData.id);
          break;
        case QREntityType.room:
          await _navigateToRoom(qrData.id, qrData.metadata?['propertyId']);
          break;
        case QREntityType.ticket:
          await _navigateToTicket(qrData.id);
          break;
      }
    } catch (e) {
      _showError('Error al cargar: $e');
      setState(() => isProcessing = false);
    }
  }

  Future<void> _navigateToProperty(String propertyId) async {
    final property = await _inventoryService.getProperty(propertyId);
    
    if (property == null) {
      _showError('Propiedad no encontrada');
      setState(() => isProcessing = false);
      return;
    }

    if (!mounted) return;
    
    // Navegar y cerrar esta pantalla
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PropertyDetailScreen(property: property),
      ),
    );
  }

  Future<void> _navigateToRoom(String roomId, String? propertyId) async {
    final room = await _inventoryService.getRoom(roomId);
    
    if (room == null) {
      _showError('Espacio no encontrado');
      setState(() => isProcessing = false);
      return;
    }

    if (!mounted) return;
    
    // Navegar y cerrar esta pantalla
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RoomDetailScreen(room: room),
      ),
    );
  }

  Future<void> _navigateToTicket(String ticketId) async {
    final ticket = await _ticketService.getTicket(ticketId);
    
    if (ticket == null) {
      _showError('Ticket no encontrado');
      setState(() => isProcessing = false);
      return;
    }

    if (!mounted) return;
    
    // Navegar y cerrar esta pantalla
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TicketDetailScreen(ticketId: ticketId),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // En Web, mostrar mensaje informativo en lugar de cámara
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: AppTheme.negro,
        appBar: AppBar(
          title: const Text('Escanear QR'),
          backgroundColor: AppTheme.grisOscuro,
          foregroundColor: AppTheme.dorado,
        ),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: EdgeInsets.all(AppTheme.paddingLG),
            decoration: BoxDecoration(
              color: AppTheme.grisOscuro,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  size: 80,
                  color: Color(0xFFFAB334),
                ),
                SizedBox(height: AppTheme.spacingXL),
                const Text(
                  'Escaneo QR',
                  style: TextStyle(
                    color: Color(0xFFFAB334),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppTheme.spacingMD),
                const Text(
                  'El escaneo de códigos QR con cámara está disponible en la versión móvil de la aplicación.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppTheme.spacingXL),
                const Text(
                  '📱 Para escanear QR, descarga la app en Android.',
                  style: TextStyle(
                    color: Color(0xFFFF6B00),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // En móvil, mostrar cámara QR
    return Scaffold(
      backgroundColor: AppTheme.negro,
      body: Stack(
        children: [
          // Vista de cámara QR con MobileScanner
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),
          
          // Overlay con área de escaneo
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),
          
          // Header
          SafeArea(
            child: Container(
              padding: EdgeInsets.all(AppTheme.paddingMD),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.negro.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.blanco),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Escanear QR',
                    style: TextStyle(
                      color: AppTheme.blanco,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Botón de linterna
                  IconButton(
                    icon: const Icon(Icons.flash_off, color: AppTheme.blanco),
                    onPressed: () => controller?.toggleTorch(),
                  ),
                  // Botón de cambiar cámara
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: AppTheme.blanco),
                    onPressed: () => controller?.switchCamera(),
                  ),
                ],
              ),
            ),
          ),
          
          // Instrucciones
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(AppTheme.paddingLG),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: AppTheme.negro.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isProcessing)
                    const Column(
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFFFAB334),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Procesando...',
                          style: TextStyle(
                            color: AppTheme.blanco,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Apunta la cámara al código QR',
                      style: TextStyle(
                        color: AppTheme.blanco,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  SizedBox(height: AppTheme.spacingSM),
                  const Text(
                    'El escaneo es automático',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter para overlay de escaneo
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final Rect scanArea = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Pintar área oscura alrededor del área de escaneo
    final Paint backgroundPaint = Paint()
      ..color = AppTheme.negro.withValues(alpha: 0.5);
    
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(16)))
        ..fillType = PathFillType.evenOdd,
      backgroundPaint,
    );

    // Pintar borde del área de escaneo
    final Paint borderPaint = Paint()
      ..color = AppTheme.dorado
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanArea, const Radius.circular(16)),
      borderPaint,
    );

    // Pintar esquinas
    final Paint cornerPaint = Paint()
      ..color = AppTheme.dorado
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30;

    // Esquina superior izquierda
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // Esquina superior derecha
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top),
      Offset(left + scanAreaSize, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize, top + cornerLength),
      cornerPaint,
    );

    // Esquina inferior izquierda
    canvas.drawLine(
      Offset(left, top + scanAreaSize - cornerLength),
      Offset(left, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      cornerPaint,
    );

    // Esquina inferior derecha
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      Offset(left + scanAreaSize, top + scanAreaSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
