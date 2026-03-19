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

class EditRecordatorioScreen extends StatefulWidget {
  final Recordatorio recordatorio;

  const EditRecordatorioScreen({super.key, required this.recordatorio});

  @override
  State<EditRecordatorioScreen> createState() => _EditRecordatorioScreenState();
}

class _EditRecordatorioScreenState extends State<EditRecordatorioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _observacionesController = TextEditingController();

  DateTime? _fechaServicio;
  DateTime? _horaAlarma;
  String _selectedFrequency = '';
  String _selectedEquipment = '';
  String _ubicacion = '';
  double? _latitud;
  double? _longitud;

  bool _isSaving = false;
  bool _programarAlarma = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadRecordatorioData();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _loadRecordatorioData() {
    final recordatorio = widget.recordatorio;

    _clienteController.text = recordatorio.cliente;
    _telefonoController.text = recordatorio.telefono;
    _emailController.text = recordatorio.email;
    _observacionesController.text = recordatorio.observaciones;

    _fechaServicio = recordatorio.fechaServicio;
    // Cargar la hora como DateTime para poder extraer hora/minuto
    _horaAlarma = recordatorio.fechaServicio;
    _selectedFrequency = recordatorio.frecuencia;
    _selectedEquipment = recordatorio.equipo;
    _ubicacion = recordatorio.ubicacion;
    _programarAlarma = recordatorio.alarmaProgramada;
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    if (!_hasChanges) return true;

    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceColor,
            title: const Text(
              '¿Descartar cambios?',
              style: TextStyle(color: AppTheme.textColor),
            ),
            content: const Text(
              'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ) ??
        false;
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
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectTime() async {
    if (_fechaServicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una fecha primero'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaServicio!),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.secondaryColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        _fechaServicio = DateTime(
          _fechaServicio!.year,
          _fechaServicio!.month,
          _fechaServicio!.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        _hasChanges = true;
      });
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapasScreen()),
    );

    if (result != null && result is Map) {
      setState(() {
        _ubicacion = result['direccion'] ?? _ubicacion;
        _latitud = result['latitud'] ?? _latitud;
        _longitud = result['longitud'] ?? _longitud;
        _hasChanges = true;
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

  Future<void> _saveChanges() async {
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

    setState(() {
      _isSaving = true;
    });

    try {
      final storageService = context.read<StorageService>();
      final alarmService = context.read<AlarmService>();

      // Cancelar alarmas antiguas
      await alarmService.cancelarAlarma(widget.recordatorio);

      // Calcular nueva fecha próxima mantenimiento
      final fechaProximo = Recordatorio.calcularFechaProximo(
        _fechaServicio!,
        _selectedFrequency,
      );

      // Si el usuario seleccionó una hora específica, combinarla con la fecha
      // Si no, usar la fecha como estaba en el recordatorio original
      DateTime fechaServicioFinal = _horaAlarma != null
          ? DateTime(
              _fechaServicio!.year,
              _fechaServicio!.month,
              _fechaServicio!.day,
              _horaAlarma!.hour,
              _horaAlarma!.minute,
            )
          : _fechaServicio!;

      // Calcular fechaProximo con la misma hora
      DateTime fechaProximoFinal = DateTime(
        fechaProximo.year,
        fechaProximo.month,
        fechaProximo.day,
        fechaServicioFinal.hour,
        fechaServicioFinal.minute,
      );

      // Actualizar recordatorio
      final recordatorioActualizado = widget.recordatorio.copyWith(
        cliente: _clienteController.text.trim(),
        telefono: _telefonoController.text.trim(),
        email: _emailController.text.trim(),
        fechaServicio: fechaServicioFinal,
        frecuencia: _selectedFrequency,
        equipo: _selectedEquipment,
        ubicacion: _ubicacion,
        observaciones: _observacionesController.text.trim(),
        fechaProximoMantenimiento: fechaProximoFinal,
        diasFrecuencia: Recordatorio.calcularDiasFrecuencia(_selectedFrequency),
        alarmaProgramada: _programarAlarma,
        fechaAlarma: null,
        fechaNotificacion: null,
        notificacionProgramada: false,
      );

      // Guardar cambios
      await storageService.actualizarRecordatorio(recordatorioActualizado);

      // Reprogramar alarmas si están habilitadas
      if (_programarAlarma) {
        await alarmService.programarAlarma(recordatorioActualizado);
        await alarmService.programarNotificacionPrevia(recordatorioActualizado);
      }

      // Mostrar éxito y regresar
      _showSuccessDialog(recordatorioActualizado);
    } catch (e) {
      debugPrint('Error actualizando recordatorio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el recordatorio'),
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
              '✅ Cambios Guardados',
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
                'El recordatorio ha sido actualizado exitosamente.',
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
                  '🔔 Alarmas reprogramadas:',
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
              ] else ...[
                const Text(
                  '🔕 Alarmas canceladas',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context, true); // Regresar con éxito
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Continuar'),
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
            onChanged: (_) => _onFieldChanged(),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha anterior: ${date_util.DateUtils.formatDateLong(widget.recordatorio.fechaServicio)}',
                          style: AppTheme.caption,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Próximo mantenimiento: ${date_util.DateUtils.formatDateLong(Recordatorio.calcularFechaProximo(_fechaServicio!, _selectedFrequency))}',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
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
                  'Hora del Servicio',
                  style: AppTheme.body2.copyWith(fontWeight: FontWeight.w500),
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
                    FontAwesomeIcons.clock,
                    color: AppTheme.textSecondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _fechaServicio != null
                          ? '${_fechaServicio!.hour.toString().padLeft(2, '0')}:${_fechaServicio!.minute.toString().padLeft(2, '0')}'
                          : 'Selecciona hora',
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
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    final hasLocation =
        _ubicacion.isNotEmpty || widget.recordatorio.ubicacion.isNotEmpty;

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
                  'Ubicación',
                  style: AppTheme.body2.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _selectLocation,
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
                    FontAwesomeIcons.map,
                    color: AppTheme.textSecondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasLocation
                              ? _ubicacion.isNotEmpty
                                    ? _ubicacion
                                    : widget.recordatorio.ubicacion
                              : 'Selecciona una ubicación en el mapa',
                          style: TextStyle(
                            color: hasLocation
                                ? AppTheme.textColor
                                : AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasLocation && _ubicacion.isEmpty)
                          Text('(Ubicación actual)', style: AppTheme.caption),
                      ],
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
          if (hasLocation) ...[
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
                    _ubicacion.isNotEmpty &&
                            _ubicacion != widget.recordatorio.ubicacion
                        ? FontAwesomeIcons.exchangeAlt
                        : FontAwesomeIcons.checkCircle,
                    size: 14,
                    color:
                        _ubicacion.isNotEmpty &&
                            _ubicacion != widget.recordatorio.ubicacion
                        ? AppTheme.warningColor
                        : AppTheme.successColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_ubicacion.isNotEmpty &&
                            _ubicacion != widget.recordatorio.ubicacion)
                          Text(
                            'Nueva ubicación: $_ubicacion',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else if (widget.recordatorio.ubicacion.isNotEmpty)
                          Text(
                            widget.recordatorio.ubicacion,
                            style: AppTheme.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
    final hadAlarma = widget.recordatorio.alarmaProgramada;
    final alarmaChanged = _programarAlarma != hadAlarma;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        border: Border.all(
          color: alarmaChanged
              ? _programarAlarma
                    ? AppTheme.successColor
                    : AppTheme.errorColor
              : AppTheme.borderColor,
          width: alarmaChanged ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
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
                      'Configuración de Alarmas',
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _programarAlarma
                          ? 'Alarma programada para el día del mantenimiento'
                          : 'Sin alarmas programadas',
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
                    _hasChanges = true;
                  });
                },
                activeThumbColor: AppTheme.primaryColor,
                activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
              ),
            ],
          ),
          if (alarmaChanged) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _programarAlarma
                    ? AppTheme.successColor.withOpacity(0.1)
                    : AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _programarAlarma
                      ? AppTheme.successColor.withOpacity(0.3)
                      : AppTheme.errorColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _programarAlarma
                        ? FontAwesomeIcons.bell
                        : FontAwesomeIcons.bellSlash,
                    size: 14,
                    color: _programarAlarma
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _programarAlarma
                          ? 'Se programará una nueva alarma para el día del mantenimiento'
                          : 'La alarma existente será cancelada',
                      style: AppTheme.caption.copyWith(
                        color: _programarAlarma
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
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

  Widget _buildChangeSummary() {
    final cambios = <String>[];

    if (_clienteController.text != widget.recordatorio.cliente) {
      cambios.add('Cliente');
    }
    if (_fechaServicio != widget.recordatorio.fechaServicio) {
      cambios.add('Fecha del servicio');
    }
    if (_selectedFrequency != widget.recordatorio.frecuencia) {
      cambios.add('Frecuencia');
    }
    if (_selectedEquipment != widget.recordatorio.equipo) {
      cambios.add('Equipo');
    }
    if (_ubicacion.isNotEmpty && _ubicacion != widget.recordatorio.ubicacion) {
      cambios.add('Ubicación');
    }
    if (_programarAlarma != widget.recordatorio.alarmaProgramada) {
      cambios.add('Configuración de alarmas');
    }

    if (cambios.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.exclamationTriangle,
                size: 16,
                color: AppTheme.warningColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Cambios detectados',
                style: AppTheme.body2.copyWith(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Se modificarán los siguientes campos:',
            style: AppTheme.caption,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: cambios.map((cambio) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  cambio,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _showUnsavedChangesDialog,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: CustomAppBar(
          title: 'Editar Recordatorio',
          showBackButton: true,
          onBackPressed: () async {
            final canPop = await _showUnsavedChangesDialog();
            if (canPop) {
              Navigator.pop(context);
            }
          },
          actions: [
            if (_hasChanges)
              IconButton(
                icon: const Icon(FontAwesomeIcons.save),
                onPressed: _isSaving ? null : _saveChanges,
                color: AppTheme.primaryColor,
                tooltip: 'Guardar cambios',
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumen de cambios
                _buildChangeSummary(),

                // Título
                Text(
                  'Editar Mantenimiento',
                  style: AppTheme.heading2.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Modifica los datos del mantenimiento existente',
                  style: AppTheme.body2,
                ),
                const SizedBox(height: 24),

                // Estado actual
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(
                      widget.recordatorio.colorEstado,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppTheme.defaultBorderRadius,
                    ),
                    border: Border.all(
                      color: Color(
                        widget.recordatorio.colorEstado,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(
                            widget.recordatorio.colorEstado,
                          ).withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(widget.recordatorio.colorEstado),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            widget.recordatorio.iconoEstado,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estado actual: ${widget.recordatorio.estado}',
                              style: AppTheme.body1.copyWith(
                                color: Color(widget.recordatorio.colorEstado),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Próximo mantenimiento: ${date_util.DateUtils.formatDateLong(widget.recordatorio.fechaProximoMantenimiento)}',
                              style: AppTheme.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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

                // Hora del servicio
                _buildTimeSelector(),

                // Frecuencia
                FrequencyPicker(
                  initialValue: _selectedFrequency.isNotEmpty
                      ? _selectedFrequency
                      : widget.recordatorio.frecuencia,
                  onChanged: (value) {
                    setState(() {
                      _selectedFrequency = value;
                      _hasChanges = true;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Equipo
                EquipmentPicker(
                  initialValue: _selectedEquipment.isNotEmpty
                      ? _selectedEquipment
                      : widget.recordatorio.equipo,
                  onChanged: (value) {
                    setState(() {
                      _selectedEquipment = value;
                      _hasChanges = true;
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
                        onPressed: _isSaving
                            ? null
                            : () async {
                                final canPop =
                                    await _showUnsavedChangesDialog();
                                if (canPop) {
                                  Navigator.pop(context);
                                }
                              },
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
                        onPressed: _isSaving || !_hasChanges
                            ? null
                            : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasChanges
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondaryColor,
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
                            : Text(
                                _hasChanges ? 'Guardar Cambios' : 'Sin cambios',
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
