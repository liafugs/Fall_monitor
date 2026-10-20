import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_controller.dart';
import '../utils/thresholds.dart';

const _fields = <(String, String, String)>[
  ('impactAccelG', 'Aceleração de impacto (candidato)', 'g'),
  ('impactGyroDps', 'Velocidade angular mínima no impacto', '°/s'),
  ('orientationChangeDeg', 'Mudança mínima de orientação', '°'),
  ('impactWindowSec', 'Janela de picos ao redor do impacto', 's'),
  ('preWindowSec', 'Janela pré-impacto (referência)', 's'),
  ('settleSec', 'Espera antes de avaliar orientação', 's'),
  ('postWindowSec', 'Janela de análise pós-impacto', 's'),
  ('refractorySec', 'Período refratário', 's'),
  ('lowMotionAccelDevG', 'Baixa movimentação: |A−1g| <', 'g'),
  ('lowMotionGyroDps', 'Baixa movimentação: ω <', '°/s'),
  ('maxPeakAccelG', 'Normalização: aceleração máxima', 'g'),
  ('maxPeakGyroDps', 'Normalização: ω máxima', '°/s'),
  ('maxOrientationDeg', 'Normalização: orientação máxima', '°'),
  ('maxImmobilitySec', 'Normalização: imobilidade máxima', 's'),
  ('wAccel', 'Peso: aceleração', ''),
  ('wGyro', 'Peso: velocidade angular', ''),
  ('wOrient', 'Peso: orientação', ''),
  ('wImmo', 'Peso: imobilidade', ''),
  ('lowMax', 'Limite superior da classe Baixa', ''),
  ('moderateMax', 'Limite superior da classe Moderada', ''),
  ('responseTimeoutSec', 'Tempo para o usuário responder', 's'),
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, TextEditingController> _ctl = {};

  @override
  void initState() {
    super.initState();
    _load(context.read<AppController>().thresholds);
  }

  void _load(Thresholds t) {
    for (final f in _fields) {
      _ctl.putIfAbsent(f.$1, () => TextEditingController()).text = t[f.$1].toString();
    }
  }

  @override
  void dispose() {
    for (final c in _ctl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final t = Thresholds();
    for (final f in _fields) {
      final v = double.tryParse(_ctl[f.$1]!.text.replaceAll(',', '.'));
      if (v == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Valor inválido: ${f.$2}')));
        return;
      }
      t[f.$1] = v;
    }
    await context.read<AppController>().updateThresholds(t);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Limiares salvos.')));
    }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        const Text(
            'Todos os limiares são parâmetros experimentais, não validados clinicamente. '
            'Ajuste-os a partir dos testes.'),
        const SizedBox(height: 12),
        for (final f in _fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _ctl[f.$1],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: f.$2, suffixText: f.$3, border: const OutlineInputBorder()),
            ),
          ),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
        TextButton(
            onPressed: () => setState(() => _load(Thresholds())),
            child: const Text('Restaurar padrões (depois toque em Salvar)')),
      ]);
}
