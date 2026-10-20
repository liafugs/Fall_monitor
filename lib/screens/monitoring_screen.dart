import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_controller.dart';
import '../services/bluetooth_service.dart';
import '../utils/calculations.dart';
import '../utils/constants.dart';

/// Dashboard principal.
class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  static String _conn(ConnState s) => switch (s) {
        ConnState.disconnected => 'Desconectado',
        ConnState.scanning => 'Procurando sensor…',
        ConnState.connecting => 'Conectando…',
        ConnState.connected => 'Conectado',
        ConnState.simulating => 'Simulação',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final s = c.bt.state;
    final connected = s == ConnState.connected || s == ConnState.simulating;
    final busy = s == ConnState.scanning || s == ConnState.connecting;
    final last = c.dsp.display.isEmpty ? null : c.dsp.display.last;

    final (Color color, String estado) = switch (c.sysState) {
      SystemState.idle => (Colors.grey, 'Monitoramento parado'),
      SystemState.normal => (Colors.green, 'Movimento normal'),
      SystemState.possibleFall => (Colors.orange, 'Possível queda — analisando'),
      SystemState.fallConfirmed => (Colors.red, 'Queda confirmada'),
    };

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            SizedBox(width: 130, child: Text(k, style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text(v)),
          ]),
        );

    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(12)),
        child: Text(estado.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ),
      const SizedBox(height: 16),
      row('CONEXÃO', _conn(s)),
      row('DISPOSITIVO', c.bt.deviceName),
      row('MONITORAMENTO', c.monitoring ? 'Ativo' : 'Inativo'),
      row('ESTADO', estado),
      row('A (resultante)', last == null ? '—' : '${fmtNum(last.a, 2)} g'),
      row('ω (resultante)', last == null ? '—' : '${fmtNum(last.w, 0)} °/s'),
      if (c.lastError != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(c.lastError!, style: const TextStyle(color: Colors.red)),
        ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: connected ? c.toggleMonitoring : null,
        icon: Icon(c.monitoring ? Icons.stop : Icons.play_arrow),
        label: Text(c.monitoring ? 'Encerrar monitoramento' : 'Iniciar monitoramento'),
      ),
      if (c.sysState == SystemState.fallConfirmed)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton.tonal(
              onPressed: c.clearAlertState, child: const Text('Encerrar alerta')),
        ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: busy ? null : c.connectSensor,
        icon: const Icon(Icons.bluetooth),
        label: const Text('Conectar sensor (ESP32)'),
      ),
      OutlinedButton.icon(
        onPressed: busy ? null : c.startSimulation,
        icon: const Icon(Icons.smart_toy),
        label: const Text('Usar simulador (sem hardware)'),
      ),
      if (connected || busy)
        TextButton(onPressed: c.disconnect, child: const Text('Desconectar')),
      const SizedBox(height: 16),
      Text(Constants.disclaimer, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
