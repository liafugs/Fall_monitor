import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_controller.dart';
import '../utils/calculations.dart';
import '../utils/constants.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final last = c.dsp.display.isEmpty ? null : c.dsp.display.last;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Modo de testes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('Conecte o sensor (ou o simulador), escolha a atividade e inicie a aquisição. '
          'Ative também o monitoramento no Início para registrar as decisões do detector no CSV '
          '(coluna flag: 1 candidato rejeitado, 2 possível queda, 3 marcador manual).'),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: c.testLabel,
        decoration: const InputDecoration(labelText: 'Atividade em execução', border: OutlineInputBorder()),
        items: [for (final a in Constants.testActivities) DropdownMenuItem(value: a, child: Text(a))],
        onChanged: (v) => v == null ? null : c.setTestLabel(v),
      ),
      const SizedBox(height: 16),
      Text('Aquisição: ${c.testing ? 'ATIVA' : 'parada'}  •  Amostras: ${c.testSamples.length}'),
      Text('A = ${last == null ? '—' : '${fmtNum(last.a, 2)} g'}   '
          'ω = ${last == null ? '—' : '${fmtNum(last.w, 0)} °/s'}  (gráficos na aba Sinais)'),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: c.testing ? c.stopTest : c.startTest,
        icon: Icon(c.testing ? Icons.stop : Icons.fiber_manual_record),
        label: Text(c.testing ? 'Interromper aquisição' : 'Iniciar aquisição'),
      ),
      OutlinedButton.icon(
        onPressed: c.testing ? c.markEvent : null,
        icon: const Icon(Icons.flag),
        label: const Text('Marcar evento agora'),
      ),
      OutlinedButton.icon(
        onPressed: c.testSamples.isEmpty || c.testing ? null : c.exportTest,
        icon: const Icon(Icons.ios_share),
        label: const Text('Exportar dados (CSV)'),
      ),
    ]);
  }
}
