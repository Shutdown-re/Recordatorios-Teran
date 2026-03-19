import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class EquipmentPicker extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String label;
  final bool enabled;
  final bool showIcon;

  const EquipmentPicker({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.label = 'Equipo/Servicio',
    this.enabled = true,
    this.showIcon = true,
  });

  @override
  State<EquipmentPicker> createState() => _EquipmentPickerState();
}

class _EquipmentPickerState extends State<EquipmentPicker> {
  late String _selectedEquipment;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedEquipment = widget.initialValue ?? AppConstants.equipos[0];
  }

  List<String> get _filteredEquipos {
    if (_searchQuery.isEmpty) {
      return AppConstants.equipos;
    }
    return AppConstants.equipos.where((equipo) {
      return equipo.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
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
                FontAwesomeIcons.tools,
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

        GestureDetector(
          onTap: widget.enabled ? _showEquipmentSelector : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                if (widget.showIcon) ...[
                  _getEquipmentIcon(_selectedEquipment),
                  const SizedBox(width: 12),
                ],

                Expanded(
                  child: Text(
                    _selectedEquipment,
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 12),

                Icon(
                  FontAwesomeIcons.chevronDown,
                  size: 16,
                  color: widget.enabled
                      ? AppTheme.textSecondaryColor
                      : AppTheme.textSecondaryColor.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Indicador del tipo de equipo
        _buildEquipmentTypeIndicator(),
      ],
    );
  }

  Widget _buildEquipmentTypeIndicator() {
    final equipmentType = _getEquipmentType(_selectedEquipment);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _getEquipmentIcon(_selectedEquipment),
          const SizedBox(width: 8),
          Text(equipmentType, style: AppTheme.caption),
        ],
      ),
    );
  }

  String _getEquipmentType(String equipment) {
    if (equipment.contains('Aire Acondicionado')) {
      return 'Equipo de climatización';
    } else if (equipment.contains('Mantenimiento') ||
        equipment.contains('Limpieza')) {
      return 'Servicio de mantenimiento';
    } else if (equipment.contains('Reparación') ||
        equipment.contains('Cambio')) {
      return 'Servicio de reparación';
    } else if (equipment.contains('Instalación')) {
      return 'Instalación';
    } else if (equipment.contains('Revisión') ||
        equipment.contains('Calibración')) {
      return 'Servicio de revisión';
    } else {
      return 'Servicio técnico';
    }
  }

  Widget _getEquipmentIcon(String equipment) {
    final icon = AppConstants.equipoIconos[equipment] ?? '🔧';
    return Text(icon, style: const TextStyle(fontSize: 16));
  }

  void _showEquipmentSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Seleccionar Equipo', style: AppTheme.heading3),
                        IconButton(
                          icon: const Icon(FontAwesomeIcons.times),
                          onPressed: () => Navigator.pop(context),
                          color: AppTheme.textColor,
                        ),
                      ],
                    ),
                  ),

                  // Barra de búsqueda
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(
                          AppTheme.defaultBorderRadius,
                        ),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Buscar equipo...',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondaryColor,
                          ),
                          border: InputBorder.none,
                          icon: Icon(
                            FontAwesomeIcons.search,
                            size: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        style: const TextStyle(color: AppTheme.textColor),
                        autofocus: false,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lista de equipos
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredEquipos.length,
                      itemBuilder: (context, index) {
                        final equipment = _filteredEquipos[index];
                        final isSelected = equipment == _selectedEquipment;

                        return ListTile(
                          leading: _getEquipmentIcon(equipment),
                          title: Text(
                            equipment,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  FontAwesomeIcons.check,
                                  color: AppTheme.primaryColor,
                                  size: 16,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedEquipment = equipment;
                            });
                            widget.onChanged(equipment);
                            Navigator.pop(context);
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                        );
                      },
                    ),
                  ),

                  // Botón personalizado
                  if (_searchQuery.isNotEmpty && _filteredEquipos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: OutlinedButton(
                        onPressed: () {
                          final customEquipment = _searchQuery;
                          setState(() {
                            _selectedEquipment = customEquipment;
                          });
                          widget.onChanged(customEquipment);
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.defaultBorderRadius,
                            ),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text(
                          'Usar búsqueda como equipo personalizado',
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Selector de equipo con categorías
class EquipmentCategoryPicker extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const EquipmentCategoryPicker({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<EquipmentCategoryPicker> createState() =>
      _EquipmentCategoryPickerState();
}

class _EquipmentCategoryPickerState extends State<EquipmentCategoryPicker> {
  late String _selectedEquipment;
  String _selectedCategory = 'Todos';

  final Map<String, List<String>> _categories = {
    'Todos': AppConstants.equipos,
    'Aire Acondicionado': [
      'Aire Acondicionado Split',
      'Aire Acondicionado Mini Split',
      'Aire Acondicionado Central',
      'Aire Acondicionado Portátil',
      'Aire Acondicionado de Ventana',
    ],
    'Mantenimiento': [
      'Mantenimiento Preventivo A/A',
      'Limpieza de Evaporador',
      'Limpieza de Condensador',
      'Limpieza de Ductos',
      'Recarga de Gas Refrigerante',
      'Cambio de Filtros',
    ],
    'Reparación': [
      'Reparación Eléctrica',
      'Reparación de Tarjeta Electrónica',
      'Cambio de Tubería de Cobre',
      'Cambio de Compresor',
      'Reparación de Equipo Completo',
      'Falla de Equipo Eléctrico',
      'Falla Mecánica',
    ],
    'Instalación y Revisión': [
      'Instalación Nuevo Equipo',
      'Revisión General Anual',
      'Calibración de Termostatos',
      'Prueba de Presiones',
      'Mantenimiento y Diagnóstico',
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedEquipment = widget.initialValue ?? AppConstants.equipos[0];
  }

  List<String> get _currentCategoryEquipos {
    return _categories[_selectedCategory] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selecciona el equipo o servicio', style: AppTheme.heading3),

          const SizedBox(height: 8),

          Text(
            'Elige el tipo de equipo que requiere mantenimiento',
            style: AppTheme.body2,
          ),

          const SizedBox(height: 16),

          // Selector de categorías
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.keys.map((category) {
                final isSelected = category == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: AppTheme.surfaceColor,
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.secondaryColor
                          : AppTheme.textColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.borderColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Grid de equipos
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _currentCategoryEquipos.length,
            itemBuilder: (context, index) {
              final equipment = _currentCategoryEquipos[index];
              final isSelected = equipment == _selectedEquipment;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedEquipment = equipment;
                  });
                  widget.onChanged(equipment);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(
                      AppTheme.defaultBorderRadius,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _getEquipmentIcon(equipment),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          equipment,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textColor,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Equipo seleccionado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.checkCircle,
                  color: AppTheme.accentColor,
                  size: 20,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Equipo seleccionado:',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _selectedEquipment,
                        style: const TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 14,
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
      ),
    );
  }

  Widget _getEquipmentIcon(String equipment) {
    final icon = AppConstants.equipoIconos[equipment] ?? '🔧';
    return Text(icon, style: const TextStyle(fontSize: 16));
  }
}
