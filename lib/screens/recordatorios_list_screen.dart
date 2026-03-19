import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../models/recordatorio.dart';
import '../services/alarm_service.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import '../utils/date_utils.dart' as date_util;
import '../widgets/custom_app_bar.dart';
import '../widgets/recordatorio_card.dart';
import 'edit_recordatorio_screen.dart';

class RecordatoriosListScreen extends StatefulWidget {
  const RecordatoriosListScreen({super.key});

  @override
  State<RecordatoriosListScreen> createState() =>
      _RecordatoriosListScreenState();
}

class _RecordatoriosListScreenState extends State<RecordatoriosListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Recordatorio> _recordatorios = [];
  List<Recordatorio> _filteredRecordatorios = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _selectionMode = false;
  final Set<Recordatorio> _selectedRecordatorios = {};
  String _searchQuery = '';
  String _selectedFilter =
      'todos'; // 'todos', 'pendientes', 'proximos', 'vencidos'
  String _selectedSort = 'fecha'; // 'fecha', 'cliente', 'equipo'

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    _loadRecordatorios();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecordatorios() async {
    try {
      final storageService = context.read<StorageService>();
      final loadedRecordatorios = await storageService.getRecordatorios();

      setState(() {
        _recordatorios = loadedRecordatorios;
        _applyFiltersAndSort();
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      debugPrint('Error cargando recordatorios: $e');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    // Aplicar filtro
    List<Recordatorio> filtered = _recordatorios;

    switch (_selectedFilter) {
      case 'pendientes':
        filtered = filtered.where((r) => !r.estaVencido()).toList();
        break;
      case 'proximos':
        filtered = filtered
            .where((r) => r.esProximo() && !r.estaVencido())
            .toList();
        break;
      case 'vencidos':
        filtered = filtered.where((r) => r.estaVencido()).toList();
        break;
    }

    // Aplicar búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((recordatorio) {
        return recordatorio.cliente.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            recordatorio.equipo.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            recordatorio.ubicacion.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            recordatorio.telefono.contains(_searchQuery);
      }).toList();
    }

    // Aplicar ordenamiento
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'cliente':
          return a.cliente.compareTo(b.cliente);
        case 'equipo':
          return a.equipo.compareTo(b.equipo);
        case 'fecha':
        default:
          return a.fechaProximoMantenimiento.compareTo(
            b.fechaProximoMantenimiento,
          );
      }
    });

    setState(() {
      _filteredRecordatorios = filtered;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedRecordatorios.clear();
      }
    });
  }

  void _toggleRecordatorioSelection(Recordatorio recordatorio) {
    setState(() {
      if (_selectedRecordatorios.contains(recordatorio)) {
        _selectedRecordatorios.remove(recordatorio);
      } else {
        _selectedRecordatorios.add(recordatorio);
      }

      if (_selectedRecordatorios.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedRecordatorios.length == _filteredRecordatorios.length) {
        _selectedRecordatorios.clear();
      } else {
        _selectedRecordatorios.addAll(_filteredRecordatorios);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedRecordatorios.isEmpty) return;

    final confirmed = await _showConfirmationDialog(
      'Eliminar ${_selectedRecordatorios.length} recordatorio(s)',
      '¿Estás seguro de eliminar los recordatorios seleccionados? Esta acción no se puede deshacer.',
    );

    if (!confirmed) return;

    try {
      final storageService = context.read<StorageService>();
      final alarmService = context.read<AlarmService>();

      for (final recordatorio in _selectedRecordatorios) {
        if (recordatorio.id != null) {
          await alarmService.cancelarAlarma(recordatorio);
          await storageService.eliminarRecordatorio(recordatorio.id!);
        }
      }

      setState(() {
        _selectedRecordatorios.clear();
        _selectionMode = false;
      });

      await _loadRecordatorios();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedRecordatorios.length} recordatorio(s) eliminado(s)',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      debugPrint('Error eliminando recordatorios: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar recordatorios'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _toggleAlarmasSelected() async {
    if (_selectedRecordatorios.isEmpty) return;

    try {
      final alarmService = context.read<AlarmService>();
      final storageService = context.read<StorageService>();

      final conAlarma = _selectedRecordatorios
          .where((r) => r.alarmaProgramada)
          .length;
      final sinAlarma = _selectedRecordatorios.length - conAlarma;

      // Si la mayoría tiene alarma, desactivar todas. Si no, activar todas.
      final activar = conAlarma <= sinAlarma;

      for (final recordatorio in _selectedRecordatorios) {
        if (activar && !recordatorio.alarmaProgramada) {
          await alarmService.programarAlarma(recordatorio);
          await alarmService.programarNotificacionPrevia(recordatorio);
          final updated = recordatorio.copyWith(alarmaProgramada: true);
          await storageService.actualizarRecordatorio(updated);
        } else if (!activar && recordatorio.alarmaProgramada) {
          await alarmService.cancelarAlarma(recordatorio);
          final updated = recordatorio.copyWith(alarmaProgramada: false);
          await storageService.actualizarRecordatorio(updated);
        }
      }

      await _loadRecordatorios();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activar
                ? 'Alarmas activadas para ${_selectedRecordatorios.length} recordatorio(s)'
                : 'Alarmas desactivadas para ${_selectedRecordatorios.length} recordatorio(s)',
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      debugPrint('Error gestionando alarmas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al gestionar alarmas'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _editRecordatorio(Recordatorio recordatorio) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditRecordatorioScreen(recordatorio: recordatorio),
      ),
    );

    if (result == true) {
      await _loadRecordatorios();
    }
  }

  void _showRecordatorioDetails(Recordatorio recordatorio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondaryColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(
                              recordatorio.colorEstado,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(recordatorio.colorEstado),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              recordatorio.iconoEstado,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recordatorio.cliente,
                                style: AppTheme.heading3.copyWith(fontSize: 20),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(recordatorio.equipo, style: AppTheme.body2),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Información detallada
                    _buildDetailSection(
                      title: '📋 Información del Cliente',
                      children: [
                        _buildDetailItem('Nombre:', recordatorio.cliente),
                        _buildDetailItem(
                          'Teléfono:',
                          recordatorio.telefono.isNotEmpty
                              ? recordatorio.telefono
                              : 'No especificado',
                        ),
                        _buildDetailItem(
                          'Email:',
                          recordatorio.email.isNotEmpty
                              ? recordatorio.email
                              : 'No especificado',
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildDetailSection(
                      title: '🔧 Detalles del Mantenimiento',
                      children: [
                        _buildDetailItem('Equipo:', recordatorio.equipo),
                        _buildDetailItem(
                          'Fecha del servicio:',
                          recordatorio.fechaServicioCompleta(),
                        ),
                        _buildDetailItem(
                          'Frecuencia:',
                          recordatorio.frecuencia,
                        ),
                        _buildDetailItem(
                          'Próximo mantenimiento:',
                          recordatorio.fechaProximoCompleta(),
                        ),
                        _buildDetailItem(
                          'Días restantes:',
                          '${recordatorio.diasParaProximo()} días',
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildDetailSection(
                      title: '📍 Ubicación',
                      children: [
                        _buildDetailItem(
                          'Dirección:',
                          recordatorio.ubicacion.isNotEmpty
                              ? recordatorio.ubicacion
                              : 'No especificada',
                        ),
                      ],
                    ),

                    if (recordatorio.observaciones.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildDetailSection(
                        title: '📝 Observaciones',
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              recordatorio.observaciones,
                              style: const TextStyle(
                                color: AppTheme.textColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    _buildDetailSection(
                      title: '🔔 Configuración de Alarmas',
                      children: [
                        _buildDetailItem(
                          'Alarma programada:',
                          recordatorio.alarmaProgramada ? 'Sí' : 'No',
                        ),
                        if (recordatorio.fechaAlarma != null)
                          _buildDetailItem(
                            'Fecha de alarma:',
                            date_util.DateUtils.formatDateTime(
                              recordatorio.fechaAlarma!,
                            ),
                          ),
                        if (recordatorio.fechaNotificacion != null)
                          _buildDetailItem(
                            'Notificación previa:',
                            date_util.DateUtils.formatDateTime(
                              recordatorio.fechaNotificacion!,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textColor,
                              side: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cerrar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _editRecordatorio(recordatorio);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.secondaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Editar'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceColor,
            title: Text(
              title,
              style: const TextStyle(color: AppTheme.textColor),
            ),
            content: Text(
              message,
              style: const TextStyle(color: AppTheme.textSecondaryColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Todos', 'todos'),
          _buildFilterChip('Pendientes', 'pendientes'),
          _buildFilterChip('Próximos', 'proximos'),
          _buildFilterChip('Vencidos', 'vencidos'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    final count = _getCountByFilter(value);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : AppTheme.textSecondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Colors.white
                      : AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
            _applyFiltersAndSort();
          });
        },
        backgroundColor: AppTheme.surfaceColor,
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.secondaryColor : AppTheme.textColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
        ),
      ),
    );
  }

  int _getCountByFilter(String filter) {
    switch (filter) {
      case 'pendientes':
        return _recordatorios.where((r) => !r.estaVencido()).length;
      case 'proximos':
        return _recordatorios
            .where((r) => r.esProximo() && !r.estaVencido())
            .length;
      case 'vencidos':
        return _recordatorios.where((r) => r.estaVencido()).length;
      default:
        return _recordatorios.length;
    }
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSort,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedSort = value;
                _applyFiltersAndSort();
              });
            }
          },
          items: const [
            DropdownMenuItem(
              value: 'fecha',
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.calendarAlt, size: 14),
                  SizedBox(width: 8),
                  Text('Por fecha'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'cliente',
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.user, size: 14),
                  SizedBox(width: 8),
                  Text('Por cliente'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'equipo',
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.tools, size: 14),
                  SizedBox(width: 8),
                  Text('Por equipo'),
                ],
              ),
            ),
          ],
          dropdownColor: AppTheme.surfaceColor,
          icon: const Icon(FontAwesomeIcons.chevronDown, size: 14),
          style: const TextStyle(color: AppTheme.textColor, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildSelectionActions() {
    if (!_selectionMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedRecordatorios.length} seleccionado(s)',
            style: const TextStyle(
              color: AppTheme.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _selectedRecordatorios.length == _filteredRecordatorios.length
                  ? FontAwesomeIcons.square
                  : FontAwesomeIcons.checkSquare,
              size: 18,
            ),
            onPressed: _selectAll,
            color: AppTheme.primaryColor,
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.bell, size: 18),
            onPressed: _toggleAlarmasSelected,
            color: AppTheme.primaryColor,
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.trashAlt, size: 18),
            onPressed: _deleteSelected,
            color: AppTheme.errorColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            FontAwesomeIcons.search,
            size: 16,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFiltersAndSort();
                });
              },
              decoration: const InputDecoration(
                hintText: 'Buscar clientes, equipos, ubicaciones...',
                hintStyle: TextStyle(color: AppTheme.textSecondaryColor),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(color: AppTheme.textColor, fontSize: 14),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(FontAwesomeIcons.times, size: 14),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _applyFiltersAndSort();
                });
              },
              color: AppTheme.textSecondaryColor,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.calendarPlus,
              size: 64,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay recordatorios',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedFilter != 'todos'
                  ? 'No hay recordatorios con el filtro aplicado'
                  : 'Agrega tu primer recordatorio para comenzar',
              style: AppTheme.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_selectedFilter != 'todos')
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedFilter = 'todos';
                    _applyFiltersAndSort();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.secondaryColor,
                ),
                child: const Text('Mostrar todos'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: CustomAppBar(
        title: 'Todos los Recordatorios',
        showBackButton: true,
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(FontAwesomeIcons.times),
              onPressed: _toggleSelectionMode,
              color: AppTheme.primaryColor,
            )
          else
            IconButton(
              icon: const Icon(FontAwesomeIcons.checkSquare),
              onPressed: _toggleSelectionMode,
              color: AppTheme.primaryColor,
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(opacity: _fadeAnimation.value, child: child);
        },
        child: Column(
          children: [
            // Barra de selección
            _buildSelectionActions(),

            // Barra de búsqueda
            _buildSearchBar(),

            // Filtros y ordenamiento
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: _buildFilterChips()),
                  const SizedBox(width: 12),
                  _buildSortDropdown(),
                ],
              ),
            ),

            // Contador de resultados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${_filteredRecordatorios.length} resultado(s)',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (_isRefreshing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                ],
              ),
            ),

            // Lista de recordatorios
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _isRefreshing = true;
                        });
                        await _loadRecordatorios();
                      },
                      color: AppTheme.primaryColor,
                      child: _filteredRecordatorios.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: _filteredRecordatorios.length,
                              itemBuilder: (context, index) {
                                final recordatorio =
                                    _filteredRecordatorios[index];
                                final isSelected = _selectedRecordatorios
                                    .contains(recordatorio);

                                return _selectionMode
                                    ? SelectableRecordatorioCard(
                                        recordatorio: recordatorio,
                                        initiallySelected: isSelected,
                                        onSelectionChanged: (selected) {
                                          _toggleRecordatorioSelection(
                                            recordatorio,
                                          );
                                        },
                                        onTap: () {
                                          _toggleRecordatorioSelection(
                                            recordatorio,
                                          );
                                        },
                                      )
                                    : RecordatorioCard(
                                        recordatorio: recordatorio,
                                        onTap: () => _showRecordatorioDetails(
                                          recordatorio,
                                        ),
                                        onEdit: () =>
                                            _editRecordatorio(recordatorio),
                                        onDelete: () =>
                                            _deleteRecordatorio(recordatorio),
                                        onAlarm: () =>
                                            _toggleAlarma(recordatorio),
                                      );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares para acciones individuales
  Future<void> _deleteRecordatorio(Recordatorio recordatorio) async {
    final confirmed = await _showConfirmationDialog(
      'Eliminar recordatorio',
      '¿Estás seguro de eliminar el recordatorio de ${recordatorio.cliente}?',
    );

    if (!confirmed) return;

    try {
      final storageService = context.read<StorageService>();
      final alarmService = context.read<AlarmService>();

      if (recordatorio.id != null) {
        await alarmService.cancelarAlarma(recordatorio);
        await storageService.eliminarRecordatorio(recordatorio.id!);

        await _loadRecordatorios();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recordatorio de ${recordatorio.cliente} eliminado'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error eliminando recordatorio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar el recordatorio'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _toggleAlarma(Recordatorio recordatorio) async {
    try {
      final alarmService = context.read<AlarmService>();
      final storageService = context.read<StorageService>();

      if (recordatorio.alarmaProgramada) {
        await alarmService.cancelarAlarma(recordatorio);
        final updated = recordatorio.copyWith(alarmaProgramada: false);
        await storageService.actualizarRecordatorio(updated);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alarma cancelada para ${recordatorio.cliente}'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      } else {
        await alarmService.programarAlarma(recordatorio);
        await alarmService.programarNotificacionPrevia(recordatorio);
        final updated = recordatorio.copyWith(alarmaProgramada: true);
        await storageService.actualizarRecordatorio(updated);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alarma programada para ${recordatorio.cliente}'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }

      await _loadRecordatorios();
    } catch (e) {
      debugPrint('Error gestionando alarma: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al gestionar la alarma'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

// Widget para tarjetas seleccionables (versión simplificada para esta pantalla)
class SelectableRecordatorioCard extends StatefulWidget {
  final Recordatorio recordatorio;
  final bool initiallySelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback? onTap;

  const SelectableRecordatorioCard({
    super.key,
    required this.recordatorio,
    required this.initiallySelected,
    required this.onSelectionChanged,
    this.onTap,
  });

  @override
  State<SelectableRecordatorioCard> createState() =>
      _SelectableRecordatorioCardState();
}

class _SelectableRecordatorioCardState
    extends State<SelectableRecordatorioCard> {
  late bool _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.initiallySelected;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          setState(() {
            _isSelected = !_isSelected;
            widget.onSelectionChanged(_isSelected);
          });
        }
      },
      onLongPress: () {
        setState(() {
          _isSelected = !_isSelected;
          widget.onSelectionChanged(_isSelected);
        });
      },
      child: Stack(
        children: [
          RecordatorioCard(
            recordatorio: widget.recordatorio,
            compact: true,
            showActions: false,
          ),

          // Overlay de selección
          if (_isSelected)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(
                  AppTheme.defaultBorderRadius,
                ),
                border: Border.all(color: AppTheme.primaryColor, width: 2),
              ),
            ),

          // Checkbox de selección
          Positioned(
            top: 8,
            right: 8,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _isSelected
                    ? AppTheme.primaryColor.withOpacity(0.9)
                    : AppTheme.surfaceColor.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.borderColor,
                ),
              ),
              child: _isSelected
                  ? const Icon(
                      FontAwesomeIcons.check,
                      size: 14,
                      color: AppTheme.secondaryColor,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
