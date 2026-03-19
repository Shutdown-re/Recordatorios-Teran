import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class FrequencyPicker extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String label;
  final bool enabled;

  const FrequencyPicker({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.label = 'Frecuencia',
    this.enabled = true,
  });

  @override
  State<FrequencyPicker> createState() => _FrequencyPickerState();
}

class _FrequencyPickerState extends State<FrequencyPicker> {
  late String _selectedFrequency;

  @override
  void initState() {
    super.initState();
    _selectedFrequency = widget.initialValue ?? AppConstants.frecuencias[0];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                widget.label,
                style: AppTheme.body2.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFrequency,
              onChanged: widget.enabled
                  ? (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedFrequency = newValue;
                        });
                        widget.onChanged(newValue);
                      }
                    }
                  : null,
              items: AppConstants.frecuencias.map((String frequency) {
                return DropdownMenuItem<String>(
                  value: frequency,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      frequency,
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
              isExpanded: true,
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(
                  FontAwesomeIcons.chevronDown,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              dropdownColor: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
              menuMaxHeight: 400,
              itemHeight: 50,
              style: const TextStyle(color: AppTheme.textColor, fontSize: 14),
              selectedItemBuilder: (BuildContext context) {
                return AppConstants.frecuencias.map<Widget>((String item) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Indicador visual de la frecuencia
        _buildFrequencyIndicator(),
      ],
    );
  }

  Widget _buildFrequencyIndicator() {
    final isDaily = _selectedFrequency.contains('día');
    final isMonthly = _selectedFrequency.contains('mes');
    final isYearly = _selectedFrequency.contains('año');

    String indicatorText = '';
    IconData indicatorIcon = FontAwesomeIcons.calendar;

    if (isDaily) {
      indicatorText = 'Mantenimiento frecuente';
      indicatorIcon = FontAwesomeIcons.calendarDay;
    } else if (isMonthly) {
      indicatorText = 'Mantenimiento mensual';
      indicatorIcon = FontAwesomeIcons.calendarWeek;
    } else if (isYearly) {
      indicatorText = 'Mantenimiento anual';
      indicatorIcon = FontAwesomeIcons.calendarCheck;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(indicatorIcon, size: 14, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 8),
          Text(indicatorText, style: AppTheme.caption),
        ],
      ),
    );
  }
}

// Selector de frecuencia con vista previa
class FrequencyPickerWithPreview extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const FrequencyPickerWithPreview({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<FrequencyPickerWithPreview> createState() =>
      _FrequencyPickerWithPreviewState();
}

class _FrequencyPickerWithPreviewState
    extends State<FrequencyPickerWithPreview> {
  late String _selectedFrequency;

  @override
  void initState() {
    super.initState();
    _selectedFrequency = widget.initialValue ?? AppConstants.frecuencias[0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selecciona la frecuencia', style: AppTheme.heading3),

          const SizedBox(height: 8),

          Text(
            'Define cada cuánto tiempo se debe realizar el mantenimiento',
            style: AppTheme.body2,
          ),

          const SizedBox(height: 16),

          FrequencyPicker(
            initialValue: _selectedFrequency,
            onChanged: (value) {
              setState(() {
                _selectedFrequency = value;
              });
              widget.onChanged(value);
            },
          ),

          const SizedBox(height: 16),

          // Vista previa
          _buildFrequencyPreview(),
        ],
      ),
    );
  }

  Widget _buildFrequencyPreview() {
    final now = DateTime.now();
    final days = _calculateDays(_selectedFrequency);
    final nextDate = now.add(Duration(days: days));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.calendarCheck,
            color: AppTheme.accentColor,
            size: 20,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Próximo mantenimiento:',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _formatPreviewDate(nextDate),
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'En $days días',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateDays(String frequency) {
    switch (frequency) {
      case '1 día':
        return 1;
      case '2 días':
        return 2;
      case '3 días':
        return 3;
      case '4 días':
        return 4;
      case '5 días':
        return 5;
      case '6 días':
        return 6;
      case '7 días':
        return 7;
      case '8 días':
        return 8;
      case '9 días':
        return 9;
      case '10 días':
        return 10;
      case '11 días':
        return 11;
      case '12 días':
        return 12;
      case '13 días':
        return 13;
      case '14 días':
        return 14;
      case '15 días':
        return 15;
      case '1 mes':
        return 30;
      case '2 meses':
        return 60;
      case '3 meses':
        return 90;
      case '4 meses':
        return 120;
      case '5 meses':
        return 150;
      case '6 meses':
        return 180;
      case '7 meses':
        return 210;
      case '8 meses':
        return 240;
      case '9 meses':
        return 270;
      case '10 meses':
        return 300;
      case '11 meses':
        return 330;
      case '1 año':
        return 365;
      case '1.5 años':
        return 548;
      case '2 años':
        return 730;
      case '2.5 años':
        return 913;
      case '3 años':
        return 1095;
      default:
        return 30;
    }
  }

  String _formatPreviewDate(DateTime date) {
    final day = date.day;
    final month = date.month;
    final year = date.year;
    return '$day/${month.toString().padLeft(2, '0')}/$year';
  }
}
