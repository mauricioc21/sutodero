import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../utils/file_import.dart' as io;
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_theme.dart';
import 'create_report_screen.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({Key? key}) : super(key: key);

  @override
  _ReportListScreenState createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();
  bool _isLoading = false;

  List<MaestroReport> _drafts = [];
  List<MaestroReport> _sentReports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      final drafts = await _reportService.getDrafts(user.uid);
      final sent = await _reportService.getSentReports(user.uid);
      
      setState(() {
        _drafts = drafts;
        _sentReports = sent;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.dorado,
          labelColor: AppTheme.dorado,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Borradores'),
            Tab(text: 'Enviados'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildDraftsList(),
              _buildSentList(),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.dorado,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateReportScreen()),
          );
          if (result != null) _loadData();
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildDraftsList() {
    if (_drafts.isEmpty) {
      return const Center(child: Text('No tienes borradores guardados'));
    }
    return ListView.builder(
      itemCount: _drafts.length,
      itemBuilder: (context, index) {
        final draft = _drafts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.edit_note, color: Colors.orange, size: 36),
            title: Text(draft.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${DateFormat('dd/MM HH:mm').format(draft.fechaCreacion)} • ${draft.category.displayName}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              tooltip: 'Enviar ahora',
              onPressed: () => _syncDraft(draft),
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateReportScreen(draftToEdit: draft),
                ),
              );
              if (result != null) _loadData();
            },
          ),
        );
      },
    );
  }

  Widget _buildSentList() {
    if (_sentReports.isEmpty) {
      return const Center(child: Text('No has enviado reportes aún'));
    }
    return ListView.builder(
      itemCount: _sentReports.length,
      itemBuilder: (context, index) {
        final report = _sentReports[index];
        Color statusColor;
        IconData statusIcon;

        switch (report.status) {
          case ReportStatus.pendiente:
            statusColor = Colors.blue;
            statusIcon = Icons.access_time;
            break;
          case ReportStatus.en_revision:
            statusColor = Colors.orange;
            statusIcon = Icons.visibility;
            break;
          case ReportStatus.aprobado:
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case ReportStatus.rechazado:
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            break;
          case ReportStatus.requiere_ajustes:
            statusColor = Colors.purple;
            statusIcon = Icons.build_circle;
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.help;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(statusIcon, color: statusColor),
            ),
            title: Text(report.titulo),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.category.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                if (report.ticketCodigo != null)
                  Text('Ticket: ${report.ticketCodigo}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(DateFormat('dd/MM/yyyy').format(report.fechaEnvio ?? report.fechaCreacion), style: const TextStyle(fontSize: 11)),
              ],
            ),
            isThreeLine: true,
            onTap: () {
               _showReportDetail(report);
            },
          ),
        );
      },
    );
  }

  Future<void> _syncDraft(MaestroReport draft) async {
    setState(() => _isLoading = true);
    final success = await _reportService.sendReport(draft);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte sincronizado')));
      _loadData();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al sincronizar')));
    }
  }

  void _showReportDetail(MaestroReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(report.titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(label: Text(report.status.toString().split('.').last.toUpperCase()), backgroundColor: Colors.grey[200]),
                  const SizedBox(width: 8),
                  Chip(label: Text(report.category.displayName), backgroundColor: Colors.blue[50]),
                ],
              ),
              const Divider(),
              const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(report.descripcion),
              const SizedBox(height: 16),
              if (report.notasSupervisor != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.yellow[50], border: Border.all(color: Colors.yellow)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notas del Supervisor:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      Text(report.notasSupervisor!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (report.adjuntos.isNotEmpty) ...[
                const Text('Adjuntos:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: report.adjuntos.length,
                    itemBuilder: (context, index) {
                      final att = report.adjuntos[index];
                      // Mostrar imagen remota si existe, sino local, sino error
                      final imgProvider = (att.cloudUrl != null) 
                          ? NetworkImage(att.cloudUrl!) 
                          : (kIsWeb 
                              ? (att.localPath.isNotEmpty ? NetworkImage(att.localPath) : null)
                              : (att.localPath.isNotEmpty ? FileImage(io.File(att.localPath) as dynamic) : null));
                      
                      if (imgProvider == null) return const SizedBox();

                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(image: imgProvider as ImageProvider, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
