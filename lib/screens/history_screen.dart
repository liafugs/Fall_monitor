import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_controller.dart';
import '../models/fall_event.dart';
import '../models/severity_result.dart';
import '../utils/calculations.dart';
import '../utils/constants.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    if (c.events.isEmpty) {
      return const Center(child: Text('Nenhum evento registrado.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: c.events.length + 1,
      itemBuilder: (_, i) {
        if (i == c.events.length) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(Constants.disclaimer, style: Theme.of(context).textTheme.bodySmall),
          );
        }
        final e = c.events[i];
        final color = switch (e.severity.level) {
          SeverityLevel.baixa => Colors.green,
          SeverityLevel.moderada => Colors.orange,
          SeverityLevel.alta => Colors.red,
        };
        return Card(
          child: ListTile(
            leading: CircleAvatar(
                backgroundColor: color,
                child: Text('${e.severity.score}', style: const TextStyle(color: Colors.white))),
            title: Text(fmtDateTime(e.startMs)),
            subtitle: Text('Evento: Queda\n'
                'Impacto: ${fmtNum(e.peakAccelG)} g\n'
                'Imobilidade: ${fmtNum(e.immobilitySec, 0)} s\n'
                'Índice: ${e.severity.score}\n'
                'Classificação: ${e.severity.level.label}\n'
                'Resposta: ${e.response?.label ?? '—'}'),
            isThreeLine: false,
            onTap: () => _details(context, c, e),
          ),
        );
      },
    );
  }

  void _details(BuildContext context, AppController c, FallEvent e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detalhes do evento'),
        content: Text('Duração da análise: ${fmtNum(e.durationSec)} s\n'
            'Pico de velocidade angular: ${fmtNum(e.peakGyroDps, 0)} °/s\n'
            'Mudança de orientação: ${fmtNum(e.orientationChangeDeg, 0)}°\n'
            'Aceleração média pós: ${fmtNum(e.meanAccelPostG, 2)} g\n'
            'Velocidade angular média pós: ${fmtNum(e.meanGyroPostDps, 1)} °/s\n'
            'Nível de movimentação pós: ${fmtNum(e.motionLevelPost, 3)}\n'
            'Retomou movimento: ${e.recovered ? 'sim' : 'não'}\n'
            'Tempo até sinalizar: ${fmtNum(e.detectionDelaySec)} s\n\n'
            'Componentes (0–1): aceleração ${fmtNum(e.severity.cAccel, 2)}, '
            'giro ${fmtNum(e.severity.cGyro, 2)}, orientação ${fmtNum(e.severity.cOrient, 2)}, '
            'imobilidade ${fmtNum(e.severity.cImmo, 2)}'),
        actions: [
          TextButton(onPressed: () => c.shareRaw(e), child: const Text('Exportar dados brutos')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }
}
