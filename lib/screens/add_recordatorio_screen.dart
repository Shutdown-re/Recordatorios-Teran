import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../models/recordatorio.dart';
import '../services/alarm_service.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import '../utils/date_utils.dart' as date_util;
import '../utils/constants.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/frequency_picker.dart';
import '../widgets/equipment_picker.dart';
import 'mapas_screen.dart';

class AddRecordatorioScreen extends StatefulWidget {
  const AddRecordatorioScreen({super.key});

  @override
  State<AddRecordatorioScreen> createState() => _AddRecordatorioScreenState();
}

class _AddRecordatorioScreenState extends State<AddRecordatorioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _ubicacionTextController = TextEditingController();

  DateTime? _fechaServicio;
  DateTime? _horaAlarma; // Hora opcional para la alarma
  String _selectedFrequency = AppConstants.frecuencias[0];
  String _selectedEquipment = AppConstants.equipos[0];
  String _ubicacion = '';
  double? _mapLatitud;
  double? _mapLongitud;

  bool _isSaving = false;
  bool _programarAlarma = true;

  @override
  void dispose() {
    _clienteController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final initialDate = _fechaServicio ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.secondaryColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textColor,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppTheme.surfaceColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _fechaServicio = selectedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final initialTime = _horaAlarma != null
        ? TimeOfDay(hour: _horaAlarma!.hour, minute: _horaAlarma!.minute)
        : TimeOfDay.now();

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.secondaryColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textColor,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppTheme.surfaceColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final now = DateTime.now();
      setState(() {
        _horaAlarma = DateTime(
          now.year,
          now.month,
          now.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapasScreen(modoSeleccion: true),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        _ubicacion = result['direccion'] ?? '';
        _mapLatitud = result['latitud'];
        _mapLongitud = result['longitud'];
      });
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa $fieldName';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!AppConstants.emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!AppConstants.phoneRegex.hasMatch(value.trim())) {
      return 'Ingresa un teléfono válido';
    }
    return null;
  }

  Future<void> _saveRecordatorio() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaServicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una fecha de servicio'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Validar que al menos una ubicación esté especificada
    if (_ubicacionTextController.text.trim().isEmpty && _ubicacion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor especifica una ubicación (texto o mapa)'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final storageService = context.read<StorageService>();
      final alarmService = context.read<AlarmService>();

      // Calcular fecha próxima mantenimiento
      final fechaProximo = Recordatorio.calcularFechaProximo(
        _fechaServicio!,
        _selectedFrequency,
      );

      // Si el usuario seleccionó una hora específica, combinarla con la fecha
      // Si no seleccionó hora, usar la hora actual del dispositivo
      final now = DateTime.now();
      DateTime fechaFinal = _horaAlarma != null
          ? DateTime(
              _fechaServicio!.year,
              _fechaServicio!.month,
              _fechaServicio!.day,
              _horaAlarma!.hour,
              _horaAlarma!.minute,
            )
          : DateTime(
              _fechaServicio!.year,
              _fechaServicio!.month,
              _fechaServicio!.day,
              now.hour,
              now.minute,
            );

      // Calcular fechaProximo con la misma hora
      DateTime fechaProximoFinal = DateTime(
        fechaProximo.year,
        fechaProximo.month,
        fechaProximo.day,
        fechaFinal.hour,
        fechaFinal.minute,
      );

      // Combinar ambas ubicaciones (descripción + mapa)
      String ubicacionFinal = _ubicacionTextController.text.trim();
      if (_ubicacion.isNotEmpty &&
          _mapLatitud != null &&
          _mapLongitud != null) {
        ubicacionFinal =
            '$ubicacionFinal\n📍 ${_ubicacion}\n[${_mapLatitud?.toStringAsFixed(4)}, ${_mapLongitud?.toStringAsFixed(4)}]';
      } else if (_ubicacion.isNotEmpty) {
        ubicacionFinal = '$ubicacionFinal\n📍 ${_ubicacion}';
      }

      // Crear nuevo recordatorio
      final nuevoRecordatorio = Recordatorio(
        cliente: _clienteController.text.trim(),
        telefono: _telefonoController.text.trim(),
        email: _emailController.text.trim(),
        fechaServicio: fechaFinal,
        frecuencia: _selectedFrequency,
        equipo: _selectedEquipment,
        ubicacion: ubicacionFinal,
        observaciones: _observacionesController.text.trim(),
        fechaProximoMantenimiento: fechaProximoFinal,
        diasFrecuencia: Recordatorio.calcularDiasFrecuencia(_selectedFrequency),
        alarmaProgramada: _programarAlarma,
      );

      // Guardar en base de datos
      final id = await storageService.guardarRecordatorio(nuevoRecordatorio);

      // Programar alarma si está habilitado
      if (_programarAlarma) {
        final recordatorioConId = nuevoRecordatorio.copyWith(id: id);
        await alarmService.programarAlarma(recordatorioConId);
        await alarmService.programarNotificacionPrevia(recordatorioConId);
      }

      // Mostrar éxito
      _showSuccessDialog(nuevoRecordatorio);
    } catch (e) {
      debugPrint('Error guardando recordatorio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al guardar el recordatorio'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessDialog(Recordatorio recordatorio) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Row(
          children: [
            Icon(FontAwesomeIcons.checkCircle, color: AppTheme.successColor),
            SizedBox(width: 12),
            Text(
              '✅ Recordatorio Guardado',
              style: TextStyle(color: AppTheme.textColor),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El recordatorio ha sido guardado exitosamente.',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 16),
              _buildSuccessDetail('👤 Cliente:', recordatorio.cliente),
              _buildSuccessDetail('🔧 Equipo:', recordatorio.equipo),
              _buildSuccessDetail(
                '📅 Fecha próximo:',
                date_util.DateUtils.formatDateLong(
                  recordatorio.fechaProximoMantenimiento,
                ),
              ),
              _buildSuccessDetail('⏰ Frecuencia:', recordatorio.frecuencia),
              const SizedBox(height: 16),
              if (_programarAlarma) ...[
                const Text(
                  '🔔 Alarmas programadas:',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Alarma principal el día del mantenimiento\n'
                  '• Notificación recordatorio 1 día antes',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context, true); // Regresar a home con éxito
            },
            child: const Text('Continuar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              _resetForm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Agregar otro'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
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

  void _resetForm() {
    _formKey.currentState?.reset();
    _clienteController.clear();
    _telefonoController.clear();
    _emailController.clear();
    _observacionesController.clear();
    _ubicacionTextController.clear();
    setState(() {
      _fechaServicio = null;
      _selectedFrequency = AppConstants.frecuencias[0];
      _selectedEquipment = AppConstants.equipos[0];
      _ubicacion = '';
      _mapLatitud = null;
      _mapLongitud = null;
      _isSaving = false;
    });
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTheme.body2.copyWith(fontWeight: FontWeight.w500),
                ),
                if (required)
                  const Text(
                    ' *',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
              ],
            ),
          ),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: AppTheme.textColor),
            decoration: InputDecoration(
              hintText: 'Ingresa $label',
              hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
              filled: true,
              fillColor: AppTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppTheme.defaultBorderRadius,
                ),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppTheme.defaultBorderRadius,
                ),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppTheme.defaultBorderRadius,
                ),
                borderSide: const BorderSide(color: AppTheme.primaryColor),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  AppTheme.defaultBorderRadius,
                ),
                borderSide: const BorderSide(color: AppTheme.errorColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.calendarAlt,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fecha del Servicio',
                  style: AppTheme.body2.copyWith(fontWeight: FontWeight.w500),
                ),
                const Text(' *', style: TextStyle(color: AppTheme.errorColor)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(
                  AppTheme.defaultBorderRadius,
                ),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.calendarDay,
                    color: AppTheme.textSecondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _fechaServicio != null
                          ? date_util.DateUtils.formatDateLong(_fechaServicio!)
                          : 'Selecciona una fecha',
                      style: TextStyle(
                        color: _fechaServicio != null
                            ? AppTheme.textColor
                            : AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    FontAwesomeIcons.chevronDown,
                    color: AppTheme.textSecondaryColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (_fechaServicio != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.infoCircle,
                    size: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Próximo mantenimiento: ${date_util.DateUtils.formatDateLong(Recordatorio.calcularFechaProximo(_fechaServicio!, _selectedFrequency))}',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.clock,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hora de la Alarma',
                  style: AppTheme.body2.copyWith(fontWeight: FontWeight.w500),
                ),
                const Text(
                  ' (opcional)',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(
                  AppTheme.defaultBorderRadius,
                ),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.solidClock,
                    color: AppTheme.textSecondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _horaAlarma != null
                          ? '${_horaAlarma!.hour.toString().padLeft(2, '0')}:${_horaAlarma!.minute.toString().padLeft(2, '0')}'
                          : 'Hora actual del dispositivo',
                      style: TextStyle(
                        color: _horaAlarma != null
                            ? AppTheme.textColor
                            : AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (_horaAlarma != null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _horaAlarma = null;
                        });
                      },
                      child: Icon(
                        FontAwesomeIcons.times,
                        color: AppTheme.textSecondaryColor,
                        size: 14,
                      ),
                    )
                  else
                    Icon(
                      FontAwesomeIcons.chevronDown,
                      color: AppTheme.textSecondaryColor,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.mapMarkerAlt,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ubicación del Servicio',
                  style: AppTheme.body2.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Opción 1: Descripción por texto
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1️⃣ Por Descripción:',
                  style: AppTheme.body2.copyWith(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _ubicacionTextController,
                  style: const TextStyle(color: AppTheme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Ej: Calle 5 #10-20, Apto 301',
                    hintStyle: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.defaultBorderRadius,
                      ),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.defaultBorderRadius,
                      ),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.defaultBorderRadius,
                      ),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    prefixIcon: const Icon(
                      FontAwesomeIcons.pen,
                      size: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Opción 2: Seleccionar desde el mapa
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2️⃣ Desde Mapa (con coordenadas):',
                  style: AppTheme.body2.copyWith(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _selectLocation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(
                        AppTheme.defaultBorderRadius,
                      ),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.map,
                          color: AppTheme.textSecondaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _ubicacion.isNotEmpty
                                ? _ubicacion
                                : 'Abre el mapa y selecciona',
                            style: TextStyle(
                              color: _ubicacion.isNotEmpty
                                  ? AppTheme.textColor
                                  : AppTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          FontAwesomeIcons.chevronRight,
                          color: AppTheme.textSecondaryColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info de coordenadas si existen
          if (_mapLatitud != null && _mapLongitud != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentColor, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.checkCircle,
                    size: 14,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubicación del Mapa:',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Lat: ${_mapLatitud?.toStringAsFixed(4)}, Lng: ${_mapLongitud?.toStringAsFixed(4)}',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlarmaOption() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _programarAlarma
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _programarAlarma
                    ? AppTheme.primaryColor
                    : AppTheme.borderColor,
              ),
            ),
            child: Icon(
              FontAwesomeIcons.bell,
              color: _programarAlarma
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Programar Alarma',
                  style: AppTheme.body1.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recibirás una alarma en pantalla completa el día del mantenimiento',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
          Switch(
            value: _programarAlarma,
            onChanged: (value) {
              setState(() {
                _programarAlarma = value;
              });
            },
            activeThumbColor: AppTheme.primaryColor,
            activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: CustomAppBar(title: 'Nuevo Recordatorio', showBackButton: true),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                'Agregar Nuevo Mantenimiento',
                style: AppTheme.heading2.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'Completa los datos del mantenimiento programado',
                style: AppTheme.body2,
              ),
              const SizedBox(height: 24),

              // Información del cliente
              Text(
                '📋 Información del Cliente',
                style: AppTheme.heading3.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),

              _buildFormField(
                label: 'Nombre del Cliente',
                icon: FontAwesomeIcons.user,
                controller: _clienteController,
                validator: (value) =>
                    _validateRequired(value, 'el nombre del cliente'),
              ),

              _buildFormField(
                label: 'Teléfono',
                icon: FontAwesomeIcons.phone,
                controller: _telefonoController,
                validator: _validatePhone,
                keyboardType: TextInputType.phone,
                required: false,
              ),

              _buildFormField(
                label: 'Email',
                icon: FontAwesomeIcons.envelope,
                controller: _emailController,
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
                required: false,
              ),

              const SizedBox(height: 24),

              // Detalles del mantenimiento
              Text(
                '🔧 Detalles del Mantenimiento',
                style: AppTheme.heading3.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),

              // Fecha del servicio
              _buildDateSelector(),

              // Hora de la alarma (opcional)
              _buildTimeSelector(),

              // Frecuencia
              FrequencyPicker(
                initialValue: _selectedFrequency,
                onChanged: (value) {
                  setState(() {
                    _selectedFrequency = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Equipo
              EquipmentPicker(
                initialValue: _selectedEquipment,
                onChanged: (value) {
                  setState(() {
                    _selectedEquipment = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Ubicación
              _buildLocationSelector(),

              // Observaciones
              _buildFormField(
                label: 'Observaciones',
                icon: FontAwesomeIcons.stickyNote,
                controller: _observacionesController,
                validator: (value) => null,
                maxLines: 3,
                required: false,
              ),

              const SizedBox(height: 24),

              // Opción de alarma
              _buildAlarmaOption(),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textColor,
                        side: const BorderSide(color: AppTheme.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.defaultBorderRadius,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveRecordatorio,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.secondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.defaultBorderRadius,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.secondaryColor,
                              ),
                            )
                          : const Text('Guardar Recordatorio'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
