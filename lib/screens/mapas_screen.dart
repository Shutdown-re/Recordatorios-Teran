import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/recordatorio.dart';
import '../models/ubicacion.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class MapasScreen extends StatefulWidget {
  final Recordatorio? recordatorioSeleccionado;
  final bool modoSeleccion;

  const MapasScreen({
    super.key,
    this.recordatorioSeleccionado,
    this.modoSeleccion = false,
  });

  @override
  State<MapasScreen> createState() => _MapasScreenState();
}

class _MapasScreenState extends State<MapasScreen> {
  final LocationService locationService = LocationService();
  final List<Marker> markers = [];
  final _searchController = TextEditingController();
  final _listSearchController = TextEditingController();

  LatLng? posicionActual;
  LatLng? ubicacionSeleccionada;
  String? direccionSeleccionada;
  bool cargando = true;
  bool buscando = false;
  List<Recordatorio> recordatorios = [];
  Map<String, Ubicacion> ubicacionesCache = {};
  late MapController mapController;

  // Panel de lista
  bool _mostrarLista = false;
  String _filtroEstado = 'todos'; // todos, pendientes, proximos, vencidos
  String _busquedaLista = '';
  Recordatorio? _recordatorioResaltado;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _inicializarMapa();
  }

  Future<void> _inicializarMapa() async {
    final position = await locationService.obtenerPosicionActual();

    if (position != null) {
      setState(() {
        posicionActual = LatLng(position.latitude, position.longitude);
      });
    } else {
      setState(() {
        posicionActual = LatLng(4.5709, -74.2973);
      });
    }

    if (!widget.modoSeleccion) {
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );
      recordatorios = await storageService.getRecordatorios();
      await _cargarUbicaciones();
    }

    setState(() {
      cargando = false;
    });
  }

  // Filtrar recordatorios según estado y búsqueda
  List<Recordatorio> get _recordatoriosFiltrados {
    List<Recordatorio> filtrados = recordatorios;

    // Filtrar por estado
    switch (_filtroEstado) {
      case 'pendientes':
        filtrados = filtrados
            .where((r) => !r.estaVencido() && !r.esProximo())
            .toList();
        break;
      case 'proximos':
        filtrados = filtrados
            .where((r) => r.esProximo() && !r.estaVencido())
            .toList();
        break;
      case 'vencidos':
        filtrados = filtrados.where((r) => r.estaVencido()).toList();
        break;
    }

    // Filtrar por búsqueda de texto
    if (_busquedaLista.isNotEmpty) {
      final query = _busquedaLista.toLowerCase();
      filtrados = filtrados
          .where(
            (r) =>
                r.cliente.toLowerCase().contains(query) ||
                r.equipo.toLowerCase().contains(query) ||
                r.ubicacion.toLowerCase().contains(query),
          )
          .toList();
    }

    return filtrados;
  }

  Future<void> _cargarUbicaciones() async {
    markers.clear();

    if (posicionActual != null) {
      markers.add(
        Marker(
          point: posicionActual!,
          child: Tooltip(
            message: 'Tu ubicación',
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: AppTheme.secondaryColor,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    for (var recordatorio in recordatorios) {
      if (recordatorio.ubicacion.isNotEmpty) {
        if (!ubicacionesCache.containsKey(recordatorio.ubicacion)) {
          final ubicacion = await locationService.obtenerCoordenadasDeDir(
            recordatorio.ubicacion,
          );
          if (ubicacion != null) {
            ubicacionesCache[recordatorio.ubicacion] = ubicacion;
          }
        }

        if (ubicacionesCache.containsKey(recordatorio.ubicacion)) {
          final ubicacion = ubicacionesCache[recordatorio.ubicacion]!;
          final esResaltado = _recordatorioResaltado?.id == recordatorio.id;

          markers.add(
            Marker(
              point: LatLng(ubicacion.latitud, ubicacion.longitud),
              child: GestureDetector(
                onTap: () => _mostrarDetalles(recordatorio, ubicacion),
                child: Tooltip(
                  message: recordatorio.cliente,
                  child: Container(
                    decoration: BoxDecoration(
                      color: esResaltado
                          ? Color(recordatorio.colorEstado)
                          : AppTheme.cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: esResaltado
                            ? Colors.white
                            : AppTheme.accentColor,
                        width: esResaltado ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: esResaltado
                              ? Color(recordatorio.colorEstado).withOpacity(0.7)
                              : AppTheme.accentColor.withOpacity(0.5),
                          blurRadius: esResaltado ? 14 : 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.business,
                      color: esResaltado ? Colors.white : AppTheme.primaryColor,
                      size: esResaltado ? 28 : 24,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
  }

  // Navegar al recordatorio seleccionado en el mapa
  Future<void> _irAUbicacion(Recordatorio recordatorio) async {
    if (recordatorio.ubicacion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este recordatorio no tiene ubicación registrada'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _recordatorioResaltado = recordatorio;
    });

    // Recargar marcadores para resaltar el seleccionado
    await _cargarUbicaciones();

    if (ubicacionesCache.containsKey(recordatorio.ubicacion)) {
      final ubicacion = ubicacionesCache[recordatorio.ubicacion]!;
      mapController.move(LatLng(ubicacion.latitud, ubicacion.longitud), 16.0);

      // Cerrar panel de lista
      setState(() {
        _mostrarLista = false;
      });

      // Mostrar detalles automáticamente
      Future.delayed(const Duration(milliseconds: 400), () {
        _mostrarDetalles(recordatorio, ubicacion);
      });
    } else {
      // Intentar geocodificar
      setState(() {
        buscando = true;
      });
      final ubicacion = await locationService.obtenerCoordenadasDeDir(
        recordatorio.ubicacion,
      );
      setState(() {
        buscando = false;
      });

      if (ubicacion != null) {
        ubicacionesCache[recordatorio.ubicacion] = ubicacion;
        await _cargarUbicaciones();
        mapController.move(LatLng(ubicacion.latitud, ubicacion.longitud), 16.0);
        setState(() {
          _mostrarLista = false;
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          _mostrarDetalles(recordatorio, ubicacion);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo encontrar la ubicación: ${recordatorio.ubicacion}',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _mostrarDetalles(Recordatorio recordatorio, Ubicacion ubicacion) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Estado + Cliente
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(recordatorio.colorEstado).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Color(recordatorio.colorEstado).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    recordatorio.estado,
                    style: TextStyle(
                      color: Color(recordatorio.colorEstado),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    recordatorio.cliente,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDetalleRow(
              FontAwesomeIcons.mapMarkerAlt,
              'Ubicación',
              recordatorio.ubicacion,
            ),
            _buildDetalleRow(
              FontAwesomeIcons.tools,
              'Equipo',
              recordatorio.equipo,
            ),
            _buildDetalleRow(
              FontAwesomeIcons.calendarAlt,
              'Próximo servicio',
              DateFormat(
                "dd 'de' MMMM 'de' yyyy",
                'es_ES',
              ).format(recordatorio.fechaProximoMantenimiento),
            ),
            if (recordatorio.telefono.isNotEmpty)
              _buildDetalleRow(
                FontAwesomeIcons.phone,
                'Teléfono',
                recordatorio.telefono,
              ),
            if (recordatorio.email.isNotEmpty)
              _buildDetalleRow(
                FontAwesomeIcons.envelope,
                'Email',
                recordatorio.email,
              ),
            _buildDetalleRow(
              FontAwesomeIcons.globe,
              'Coordenadas',
              '${ubicacion.latitud.toStringAsFixed(4)}, ${ubicacion.longitud.toStringAsFixed(4)}',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceColor,
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      mapController.move(
                        LatLng(ubicacion.latitud, ubicacion.longitud),
                        18.0,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.secondaryColor,
                    ),
                    child: const Text('Acercar más'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // Quitar resaltado al cerrar detalles
      setState(() {
        _recordatorioResaltado = null;
      });
      _cargarUbicaciones();
    });
  }

  Widget _buildDetalleRow(IconData icon, String label, String valor) {
    if (valor.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 13, color: AppTheme.textColor),
            ),
          ),
        ],
      ),
    );
  }

  // =================== PANEL LATERAL DE LISTA ===================

  Widget _buildListPanel() {
    final filtrados = _recordatoriosFiltrados;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _mostrarLista ? MediaQuery.of(context).size.width * 0.85 : 0,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: _mostrarLista
          ? SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              FontAwesomeIcons.listUl,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Recordatorios',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppTheme.textSecondaryColor,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _mostrarLista = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Buscador
                        TextField(
                          controller: _listSearchController,
                          onChanged: (val) =>
                              setState(() => _busquedaLista = val),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar cliente, equipo...',
                            hintStyle: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 18,
                              color: AppTheme.textSecondaryColor,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Filtros por estado
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFiltroChip('Todos', 'todos'),
                              const SizedBox(width: 6),
                              _buildFiltroChip('Pendientes', 'pendientes'),
                              const SizedBox(width: 6),
                              _buildFiltroChip('Próximos', 'proximos'),
                              const SizedBox(width: 6),
                              _buildFiltroChip('Vencidos', 'vencidos'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Contador
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: AppTheme.surfaceColor,
                    child: Row(
                      children: [
                        Text(
                          '${filtrados.length} resultado${filtrados.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${recordatorios.where((r) => r.ubicacion.isNotEmpty).length} con ubicación',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Lista de recordatorios
                  Expanded(
                    child: filtrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  FontAwesomeIcons.searchLocation,
                                  size: 40,
                                  color: AppTheme.textSecondaryColor
                                      .withOpacity(0.5),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No se encontraron recordatorios',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 4, bottom: 80),
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final rec = filtrados[index];
                              final tieneUbicacion = rec.ubicacion.isNotEmpty;
                              return _buildRecordatorioListItem(
                                rec,
                                tieneUbicacion,
                              );
                            },
                          ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildFiltroChip(String label, String valor) {
    final seleccionado = _filtroEstado == valor;
    Color chipColor;
    switch (valor) {
      case 'pendientes':
        chipColor = AppTheme.pendingColor;
        break;
      case 'proximos':
        chipColor = AppTheme.upcomingColor;
        break;
      case 'vencidos':
        chipColor = AppTheme.overdueColor;
        break;
      default:
        chipColor = AppTheme.primaryColor;
    }

    return GestureDetector(
      onTap: () => setState(() => _filtroEstado = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado
              ? chipColor.withOpacity(0.2)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? chipColor : AppTheme.borderColor,
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
            color: seleccionado ? chipColor : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordatorioListItem(Recordatorio rec, bool tieneUbicacion) {
    final diasRestantes = rec.diasParaProximo();
    final estadoColor = Color(rec.colorEstado);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tieneUbicacion
              ? estadoColor.withOpacity(0.3)
              : AppTheme.borderColor.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: tieneUbicacion ? () => _irAUbicacion(rec) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icono de estado
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    tieneUbicacion
                        ? FontAwesomeIcons.mapMarkerAlt
                        : FontAwesomeIcons.mapMarkedAlt,
                    size: 16,
                    color: tieneUbicacion
                        ? estadoColor
                        : AppTheme.textSecondaryColor.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 10),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.cliente,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rec.equipo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tieneUbicacion) ...[
                        const SizedBox(height: 2),
                        Text(
                          rec.ubicacion.split('\n').first,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Días y flecha
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: estadoColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        diasRestantes < 0
                            ? 'Vencido'
                            : diasRestantes == 0
                            ? 'Hoy'
                            : '${diasRestantes}d',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: estadoColor,
                        ),
                      ),
                    ),
                    if (tieneUbicacion) ...[
                      const SizedBox(height: 4),
                      Icon(
                        FontAwesomeIcons.arrowRight,
                        size: 12,
                        color: AppTheme.textSecondaryColor.withOpacity(0.5),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'Sin ubicación',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondaryColor.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =================== BÚSQUEDA Y SELECCIÓN ===================

  Future<void> _buscarUbicacion() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa una dirección para buscar'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      buscando = true;
    });

    try {
      final ubicacion = await locationService.obtenerCoordenadasDeDir(
        _searchController.text.trim(),
      );

      if (ubicacion != null) {
        setState(() {
          ubicacionSeleccionada = LatLng(ubicacion.latitud, ubicacion.longitud);
          direccionSeleccionada = _searchController.text.trim();
          buscando = false;
        });
        mapController.move(ubicacionSeleccionada!, 15.0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Ubicación encontrada: ${ubicacion.direccion}'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          buscando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró la ubicación. Intenta con otra dirección',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        buscando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al buscar: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _fijarUbicacion() async {
    if (ubicacionSeleccionada == null || direccionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor busca y selecciona una ubicación primero'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'direccion': direccionSeleccionada,
      'latitud': ubicacionSeleccionada!.latitude,
      'longitud': ubicacionSeleccionada!.longitude,
    });
  }

  Future<void> _fijarMiUbicacion() async {
    if (posicionActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener tu ubicación'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      ubicacionSeleccionada = posicionActual;
      buscando = true;
    });

    try {
      final direccion = await locationService.obtenerDireccionDeCoord(
        posicionActual!.latitude,
        posicionActual!.longitude,
      );

      setState(() {
        direccionSeleccionada = direccion ?? 'Mi ubicación actual';
        buscando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Ubicación seleccionada: ${direccionSeleccionada!}'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        buscando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.modoSeleccion
              ? 'Selecciona una Ubicación'
              : 'Mapa de Ubicaciones',
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          if (!widget.modoSeleccion)
            IconButton(
              icon: Icon(
                _mostrarLista ? Icons.map : FontAwesomeIcons.listUl,
                size: _mostrarLista ? 24 : 18,
              ),
              tooltip: _mostrarLista
                  ? 'Ver mapa'
                  : 'Ver lista de recordatorios',
              onPressed: () => setState(() => _mostrarLista = !_mostrarLista),
            ),
        ],
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : posicionActual == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.location_off,
                    size: 48,
                    color: AppTheme.textSecondaryColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No se pudo obtener la ubicación',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                // Panel lateral de lista (se muestra/oculta)
                _buildListPanel(),
                // Mapa
                Expanded(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: widget.modoSeleccion
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Usa el buscador arriba o toca en el mapa para seleccionar',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null,
                        child: FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            center: posicionActual,
                            zoom: 12.0,
                            maxZoom: 18.0,
                            minZoom: 2.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.agenda_flutter',
                            ),
                            MarkerLayer(
                              markers: widget.modoSeleccion
                                  ? _construirMarcadoresSeleccion()
                                  : markers,
                            ),
                            RichAttributionWidget(
                              attributions: [
                                TextSourceAttribution(
                                  '© OpenStreetMap contributors',
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (widget.modoSeleccion)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: TextField(
                                    controller: _searchController,
                                    enabled: !buscando,
                                    decoration: InputDecoration(
                                      hintText: 'Buscar dirección...',
                                      hintStyle: const TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.surfaceColor,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppTheme.borderColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppTheme.borderColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppTheme.primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    onSubmitted: (_) => _buscarUbicacion(),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: buscando
                                            ? null
                                            : _buscarUbicacion,
                                        icon: buscando
                                            ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(
                                                        Colors.white
                                                            .withOpacity(0.7),
                                                      ),
                                                ),
                                              )
                                            : const Icon(Icons.search),
                                        label: Text(
                                          buscando ? 'Buscando...' : 'Buscar',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryColor,
                                          foregroundColor:
                                              AppTheme.secondaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: ubicacionSeleccionada == null
                                            ? null
                                            : _fijarUbicacion,
                                        icon: const Icon(Icons.location_on),
                                        label: const Text('Fijar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              ubicacionSeleccionada == null
                                              ? AppTheme.textSecondaryColor
                                              : AppTheme.accentColor,
                                          foregroundColor:
                                              AppTheme.secondaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (ubicacionSeleccionada != null &&
                                    direccionSeleccionada != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppTheme.accentColor,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      '✓ $direccionSeleccionada',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: widget.modoSeleccion
          ? FloatingActionButton(
              onPressed: _fijarMiUbicacion,
              tooltip: 'Usar mi ubicación actual',
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.secondaryColor,
              child: const Icon(Icons.my_location),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón de lista (solo si no está abierta)
                if (!_mostrarLista)
                  FloatingActionButton.small(
                    heroTag: 'list',
                    onPressed: () => setState(() => _mostrarLista = true),
                    tooltip: 'Ver lista de recordatorios',
                    backgroundColor: AppTheme.surfaceColor,
                    foregroundColor: AppTheme.primaryColor,
                    child: const Icon(FontAwesomeIcons.listUl, size: 16),
                  ),
                if (!_mostrarLista) const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'location',
                  onPressed: () {
                    if (!cargando && posicionActual != null) {
                      mapController.move(posicionActual!, 12.0);
                    }
                  },
                  tooltip: 'Centrar en mi ubicación',
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.secondaryColor,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
    );
  }

  List<Marker> _construirMarcadoresSeleccion() {
    final marcadores = <Marker>[];

    if (posicionActual != null) {
      marcadores.add(
        Marker(
          point: posicionActual!,
          child: Tooltip(
            message: 'Tu ubicación',
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: AppTheme.secondaryColor,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    if (ubicacionSeleccionada != null) {
      marcadores.add(
        Marker(
          point: ubicacionSeleccionada!,
          child: Tooltip(
            message: 'Ubicación seleccionada',
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.secondaryColor,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    return marcadores;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listSearchController.dispose();
    mapController.dispose();
    super.dispose();
  }
}
