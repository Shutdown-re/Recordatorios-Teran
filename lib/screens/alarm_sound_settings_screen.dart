import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../utils/theme.dart';

class AlarmSoundSettingsScreen extends StatefulWidget {
  const AlarmSoundSettingsScreen({super.key});

  @override
  State<AlarmSoundSettingsScreen> createState() =>
      _AlarmSoundSettingsScreenState();
}

class _AlarmSoundSettingsScreenState extends State<AlarmSoundSettingsScreen> {
  late AudioService _audioService;
  late String _selectedSound;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _selectedSound = _audioService.getSelectedSound();
  }

  @override
  void dispose() {
    _audioService.stopSound();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _selectedSound);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          title: const Text(
            'Sonido de Alarma',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _selectedSound),
          ),
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const SizedBox(height: 10),
              const Text(
                'Selecciona un sonido para tu alarma',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              ..._buildSoundsList(),
              const SizedBox(height: 30),
              _buildPreviewSection(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSoundsList() {
    final sounds = _audioService.getSoundsList();
    final items = <Widget>[];

    for (final entry in sounds.entries) {
      final soundKey = entry.key;
      final displayName = _audioService.getSoundDisplayName(soundKey);
      final isSelected = soundKey == _selectedSound;

      items.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.2)
                : AppTheme.surfaceColor,
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: Radio<String>(
              value: soundKey,
              groupValue: _selectedSound,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSound = value;
                  });
                  _audioService.setSelectedSound(value);
                  _audioService.previewSound(value);
                }
              },
              activeColor: AppTheme.primaryColor,
            ),
            title: Text(
              displayName,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.play_circle_outline,
                color: AppTheme.primaryColor,
                size: 28,
              ),
              onPressed: () {
                _audioService.previewSound(soundKey);
              },
            ),
            onTap: () {
              setState(() {
                _selectedSound = soundKey;
              });
              _audioService.setSelectedSound(soundKey);
              _audioService.previewSound(soundKey);
            },
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔊 Sonido Seleccionado',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _audioService.getSoundDisplayName(_selectedSound),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                _audioService.previewSound(_selectedSound);
              },
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Reproducir Vista Previa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
