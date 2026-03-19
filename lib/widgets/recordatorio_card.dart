import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/recordatorio.dart';
import '../utils/theme.dart';
import '../utils/date_utils.dart' as date_util;

class RecordatorioCard extends StatelessWidget {
  final Recordatorio recordatorio;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAlarm;
  final bool isSelected;
  final bool showActions;
  final bool compact;

  const RecordatorioCard({
    super.key,
    required this.recordatorio,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onAlarm,
    this.isSelected = false,
    this.showActions = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: AppTheme.defaultPadding,
        ),
        decoration: _buildCardDecoration(),
        child: compact ? _buildCompactContent() : _buildFullContent(),
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    final baseDecoration = isSelected
        ? AppTheme.cardDecorationElevated
        : AppTheme.cardDecoration;

    return baseDecoration.copyWith(
      color: Color(recordatorio.colorEstado).withOpacity(0.1),
      border: Border.all(
        color: Color(recordatorio.colorEstado).withOpacity(0.3),
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildFullContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con cliente y estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  recordatorio.cliente,
                  style: AppTheme.heading3.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(recordatorio.colorEstado).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color(recordatorio.colorEstado).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  recordatorio.estado,
                  style: TextStyle(
                    color: Color(recordatorio.colorEstado),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Información principal
          Row(
            children: [
              Icon(
                FontAwesomeIcons.tools,
                color: AppTheme.textSecondaryColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recordatorio.equipo,
                  style: AppTheme.body2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Fechas
          Row(
            children: [
              Icon(
                FontAwesomeIcons.calendarAlt,
                color: AppTheme.textSecondaryColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Próximo: ${date_util.DateUtils.formatDateLong(recordatorio.fechaProximoMantenimiento)}',
                  style: AppTheme.body2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Información adicional
          if (recordatorio.telefono.isNotEmpty)
            _buildInfoRow(
              icon: FontAwesomeIcons.phone,
              text: recordatorio.telefono,
            ),

          if (recordatorio.ubicacion.isNotEmpty)
            _buildInfoRow(
              icon: FontAwesomeIcons.mapMarkerAlt,
              text: recordatorio.ubicacion,
            ),

          if (recordatorio.observaciones.isNotEmpty)
            _buildInfoRow(
              icon: FontAwesomeIcons.stickyNote,
              text: 'Observaciones: ${recordatorio.observaciones}',
              maxLines: 2,
            ),

          const SizedBox(height: 12),

          // Footer con acciones y días restantes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${recordatorio.diasParaProximo()} días restantes',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),

              if (showActions) _buildActionButtons(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Indicador de estado
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Color(recordatorio.colorEstado),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(width: 12),

          // Contenido compacto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recordatorio.cliente,
                  style: AppTheme.body1.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Text(
                  recordatorio.equipo,
                  style: AppTheme.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                Text(
                  date_util.DateUtils.formatDate(
                    recordatorio.fechaProximoMantenimiento,
                  ),
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Botones de acción compactos
          if (showActions)
            Row(
              children: [
                if (onAlarm != null)
                  IconButton(
                    icon: Icon(
                      recordatorio.alarmaProgramada
                          ? FontAwesomeIcons.bell
                          : FontAwesomeIcons.bellSlash,
                      size: 16,
                      color: recordatorio.alarmaProgramada
                          ? AppTheme.accentColor
                          : AppTheme.textSecondaryColor,
                    ),
                    onPressed: onAlarm,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                if (onEdit != null)
                  IconButton(
                    icon: const Icon(FontAwesomeIcons.edit, size: 16),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textSecondaryColor, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTheme.body2.copyWith(fontSize: 12),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (onAlarm != null)
          IconButton(
            icon: Icon(
              recordatorio.alarmaProgramada
                  ? FontAwesomeIcons.bell
                  : FontAwesomeIcons.bellSlash,
              size: 18,
              color: recordatorio.alarmaProgramada
                  ? AppTheme.accentColor
                  : AppTheme.textSecondaryColor,
            ),
            onPressed: onAlarm,
            tooltip: recordatorio.alarmaProgramada
                ? 'Alarma programada'
                : 'Programar alarma',
          ),

        if (onEdit != null)
          IconButton(
            icon: const Icon(FontAwesomeIcons.edit, size: 18),
            onPressed: onEdit,
            tooltip: 'Editar',
          ),

        if (onDelete != null)
          IconButton(
            icon: const Icon(FontAwesomeIcons.trashAlt, size: 18),
            onPressed: onDelete,
            tooltip: 'Eliminar',
          ),
      ],
    );
  }
}

// Tarjeta para listado con opción de selección
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
