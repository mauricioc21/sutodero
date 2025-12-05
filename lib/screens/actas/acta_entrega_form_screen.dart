import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/inventory_property.dart';
import '../../models/acta_model.dart';
import '../../services/acta_service.dart';
import '../../widgets/signature_pad_dialog.dart';
import '../../config/app_theme.dart';

/// Formulario de Acta de Entrega a Arrendatario
class ActaEntregaFormScreen extends StatefulWidget {
  final InventoryProperty property;

  const ActaEntregaFormScreen({
    super.key,
    required this.property,
  });

  @override
  State<ActaEntregaFormScreen> createState() => _ActaEntregaFormScreenState();
}

class _ActaEntregaFormScreenState extends State<ActaEntregaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ActaService _actaService = ActaService();
  
  // Controladores
  final TextEditingController _arrendatarioController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _novedadController = TextEditingController();
  
  // Estado
  final List<String> _novedades = [];
  String? _firmaRecibido; // Base64
  String? _firmaEntrega; // Base64
  ActaModel? _actaGuardada;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _fechaController.text = DateTime.now().toString().split(' ')[0];
    _cargarActaExistente();
  }

  @override
  void dispose() {
    _arrendatarioController.dispose();
    _cedulaController.dispose();
    _fechaController.dispose();
    _novedadController.dispose();
    super.dispose();
  }

  /// Cargar acta existente si hay una guardada
  Future<void> _cargarActaExistente() async {
    setState(() => _isLoading = true);
    
    try {
      final acta = await _actaService.obtenerUltimaActa(
        widget.property.id,
        'entrega',
      );
      
      if (acta != null && mounted) {
        setState(() {
          _actaGuardada = acta;
          _arrendatarioController.text = acta.arrendatarioNombre;
          _cedulaController.text = acta.arrendatarioCedula;
          _fechaController.text = acta.fecha;
          _novedades.clear();
          _novedades.addAll(acta.novedades);
          _firmaRecibido = acta.firmaRecibido;
          _firmaEntrega = acta.firmaEntrega;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar acta: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Agregar novedad a la lista
  void _agregarNovedad() {
    if (_novedadController.text.trim().isNotEmpty) {
      setState(() {
        _novedades.add(_novedadController.text.trim());
        _novedadController.clear();
      });
    }
  }

  /// Eliminar novedad de la lista
  void _eliminarNovedad(int index) {
    setState(() {
      _novedades.removeAt(index);
    });
  }

  /// Guardar datos del acta en Firestore (sin generar PDF)
  Future<void> _guardarActa() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final acta = ActaModel(
        id: _actaGuardada?.id ?? '',
        propertyId: widget.property.id,
        propertyAddress: widget.property.direccion,
        propertyType: widget.property.tipo.toString(),
        tipoActa: 'entrega',
        arrendatarioNombre: _arrendatarioController.text.trim(),
        arrendatarioCedula: _cedulaController.text.trim(),
        fecha: _fechaController.text.trim(),
        novedades: _novedades,
        firmaRecibido: _firmaRecibido,
        firmaEntrega: _firmaEntrega,
        pdfUrl: _actaGuardada?.pdfUrl,
        pdfGenerado: _actaGuardada?.pdfGenerado ?? false,
        createdAt: _actaGuardada?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final actaGuardada = await _actaService.guardarActa(acta);
      
      setState(() {
        _actaGuardada = actaGuardada;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Datos guardados correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error al guardar datos';
        
        // Detectar error de permisos de Firestore
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Error de permisos de Firebase.\n\n'
              'Solución:\n'
              '1. Ve a Firebase Console\n'
              '2. Firestore Database → Rules\n'
              '3. Cambia a: allow read, write: if true;\n'
              '4. Publica los cambios';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Error de conexión. Verifica tu internet.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Ver Error',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error Detallado'),
                    content: SingleChildScrollView(
                      child: Text(e.toString()),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Generar PDF y subirlo a Firebase Storage
  Future<void> _generarPdf() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos requeridos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Guardar primero si no está guardado
    if (_actaGuardada == null) {
      await _guardarActa();
      if (_actaGuardada == null) return;
    }

    setState(() => _isGeneratingPdf = true);

    try {
      // Generar PDF
      final pdfBytes = await _crearPdfBytes();
      
      // Subir a Firebase Storage
      final fileName = 'acta_entrega_${_actaGuardada!.id}.pdf';
      final pdfUrl = await _actaService.subirPdf(
        _actaGuardada!.id,
        pdfBytes,
        fileName,
      );

      // Actualizar estado local
      setState(() {
        _actaGuardada = _actaGuardada!.copyWith(
          pdfUrl: pdfUrl,
          pdfGenerado: true,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF generado y guardado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error al generar PDF';
        
        // Detectar tipos de error
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Error de permisos de Firebase Storage.\n\n'
              'Solución:\n'
              '1. Ve a Firebase Console\n'
              '2. Storage → Rules\n'
              '3. Cambia a: allow read, write: if true;\n'
              '4. Publica los cambios';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Error de conexión. Verifica tu internet.';
        } else if (e.toString().contains('storage')) {
          errorMessage = 'Error de Firebase Storage. Verifica configuración.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Ver Error',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error Detallado'),
                    content: SingleChildScrollView(
                      child: Text(e.toString()),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  /// Crear bytes del PDF
  Future<Uint8List> _crearPdfBytes() async {
    final pdf = pw.Document();

    // Decodificar firmas si existen
    pw.MemoryImage? firmaRecibidoImage;
    pw.MemoryImage? firmaEntregaImage;

    if (_firmaRecibido != null) {
      try {
        firmaRecibidoImage = pw.MemoryImage(base64Decode(_firmaRecibido!));
      } catch (e) {
        debugPrint('Error decodificando firma recibido: $e');
      }
    }

    if (_firmaEntrega != null) {
      try {
        firmaEntregaImage = pw.MemoryImage(base64Decode(_firmaEntrega!));
      } catch (e) {
        debugPrint('Error decodificando firma entrega: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado Century 21
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1A1A1A'),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'SU TODERO',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#D4AF37'),
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Título del acta
              pw.Center(
                child: pw.Text(
                  'ACTA DE ENTREGA A ARRENDATARIO',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Información de la propiedad
              pw.Text(
                'INFORMACIÓN DE LA PROPIEDAD',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Dirección: ${widget.property.direccion}'),
              pw.Text('Tipo: ${widget.property.tipo.toString()}'),
              pw.SizedBox(height: 16),

              // Información del arrendatario
              pw.Text(
                'INFORMACIÓN DEL ARRENDATARIO',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Nombre Completo: ${_arrendatarioController.text}'),
              pw.Text('Cédula: ${_cedulaController.text}'),
              pw.Text('Fecha: ${_fechaController.text}'),
              pw.SizedBox(height: 16),

              // Texto legal
              pw.Text(
                'Por medio del presente documento, se hace constar la entrega del inmueble descrito '
                'anteriormente al ARRENDATARIO, quien manifiesta haberlo recibido a entera satisfacción '
                'en las siguientes condiciones:',
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 16),

              // Novedades
              if (_novedades.isNotEmpty) ...[
                pw.Text(
                  'NOVEDADES O CONDICIONES DEL INMUEBLE:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: _novedades.asMap().entries.map((entry) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text('${entry.key + 1}. ${entry.value}'),
                    );
                  }).toList(),
                ),
                pw.SizedBox(height: 16),
              ],

              pw.Spacer(),

              // Firmas
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Firma Recibido
                  pw.Column(
                    children: [
                      if (firmaRecibidoImage != null)
                        pw.Container(
                          width: 200,
                          height: 100,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(),
                          ),
                          child: pw.Image(firmaRecibidoImage),
                        )
                      else
                        pw.Container(
                          width: 200,
                          height: 100,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(),
                          ),
                        ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'RECIBÍ INMUEBLE',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('CC: ${_cedulaController.text}'),
                      pw.Text('Fecha: ${_fechaController.text}'),
                    ],
                  ),

                  // Firma Entregué
                  pw.Column(
                    children: [
                      if (firmaEntregaImage != null)
                        pw.Container(
                          width: 200,
                          height: 100,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(),
                          ),
                          child: pw.Image(firmaEntregaImage),
                        )
                      else
                        pw.Container(
                          width: 200,
                          height: 100,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(),
                          ),
                        ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'ENTREGUÉ INMUEBLE',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('SU TODERO'),
                      pw.Text('Fecha: ${_fechaController.text}'),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Pie de página
              pw.Center(
                child: pw.Text(
                  'Generado por SU TODERO - Sistema de Gestión de Propiedades',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Abrir diálogo de firma digital
  Future<void> _capturarFirma(String tipoFirma) async {
    final titulo = tipoFirma == 'recibido' 
        ? 'Firma: RECIBÍ INMUEBLE' 
        : 'Firma: ENTREGUÉ INMUEBLE';
    
    final firmaBase64 = await showDialog<String>(
      context: context,
      builder: (context) => SignaturePadDialog(title: titulo),
    );

    if (firmaBase64 != null && mounted) {
      setState(() {
        if (tipoFirma == 'recibido') {
          _firmaRecibido = firmaBase64;
        } else {
          _firmaEntrega = firmaBase64;
        }
      });

      // Actualizar en Firestore si ya está guardado
      if (_actaGuardada != null) {
        try {
          await _actaService.actualizarFirma(
            _actaGuardada!.id,
            tipoFirma,
            firmaBase64,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Advertencia: Firma capturada pero no guardada: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Firma ${tipoFirma == "recibido" ? "recibido" : "entrega"} capturada'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Descargar PDF existente
  void _descargarPdf() {
    if (_actaGuardada?.pdfUrl != null) {
      // Abrir URL en nueva pestaña
      // ignore: avoid_web_libraries_in_flutter
      // html.window.open(_actaGuardada!.pdfUrl!, '_blank');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Abriendo PDF...'),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            label: 'VER',
            textColor: Colors.white,
            onPressed: () {
              // Abrir URL del PDF
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool pdfYaGenerado = _actaGuardada?.pdfGenerado ?? false;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acta de Entrega'),
          backgroundColor: AppTheme.dorado,
          foregroundColor: AppTheme.negro,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acta de Entrega a Arrendatario'),
        backgroundColor: AppTheme.dorado,
        foregroundColor: AppTheme.negro,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información de la propiedad
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROPIEDAD',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Dirección: ${widget.property.direccion}'),
                      Text('Tipo: ${widget.property.tipo.toString()}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Formulario arrendatario
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DATOS DEL ARRENDATARIO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _arrendatarioController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _cedulaController,
                        decoration: const InputDecoration(
                          labelText: 'Cédula *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _fechaController,
                        decoration: const InputDecoration(
                          labelText: 'Fecha (YYYY-MM-DD) *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Campo requerido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Novedades
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NOVEDADES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _novedadController,
                              decoration: const InputDecoration(
                                hintText: 'Escribe una novedad',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _agregarNovedad(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _agregarNovedad,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.dorado,
                              foregroundColor: AppTheme.negro,
                            ),
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (_novedades.isNotEmpty)
                        ...List.generate(_novedades.length, (index) {
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.dorado,
                              foregroundColor: AppTheme.negro,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(_novedades[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarNovedad(index),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botones de firma
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FIRMAS DIGITALES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _capturarFirma('recibido'),
                              icon: Icon(_firmaRecibido != null 
                                  ? Icons.check_circle 
                                  : Icons.edit),
                              label: Text(_firmaRecibido != null 
                                  ? 'Firma Recibido ✓' 
                                  : 'Firmar Recibido'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _firmaRecibido != null 
                                    ? Colors.green 
                                    : AppTheme.dorado,
                                foregroundColor: _firmaRecibido != null 
                                    ? Colors.white 
                                    : AppTheme.negro,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _capturarFirma('entrega'),
                              icon: Icon(_firmaEntrega != null 
                                  ? Icons.check_circle 
                                  : Icons.edit),
                              label: Text(_firmaEntrega != null 
                                  ? 'Firma Entrega ✓' 
                                  : 'Firmar Entrega'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _firmaEntrega != null 
                                    ? Colors.green 
                                    : AppTheme.dorado,
                                foregroundColor: _firmaEntrega != null 
                                    ? Colors.white 
                                    : AppTheme.negro,
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _guardarActa,
                      icon: _isSaving 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Guardar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_isGeneratingPdf || pdfYaGenerado) 
                          ? (pdfYaGenerado ? _descargarPdf : null) 
                          : _generarPdf,
                      icon: _isGeneratingPdf
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Icon(pdfYaGenerado ? Icons.download : Icons.picture_as_pdf),
                      label: Text(pdfYaGenerado 
                          ? 'Descargar PDF' 
                          : 'Generar PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pdfYaGenerado 
                            ? Colors.green 
                            : AppTheme.dorado,
                        foregroundColor: pdfYaGenerado 
                            ? Colors.white 
                            : AppTheme.negro,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
