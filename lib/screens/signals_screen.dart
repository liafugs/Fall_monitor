import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_controller.dart';
import '../services/data_processing_service.dart';

class SignalsScreen extends StatelessWidget {
  const SignalsScreen({super.key});

  static List<FlSpot> _spots(List<ProcessedSample> d, double Function(ProcessedSample) f) {
    if (d.isEmpty) return [];
    final last = d.last.t;
    return d.map((p) => FlSpot((p.t - last) / 1000.0, f(p))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final d = List<ProcessedSample>.of(context.watch<AppController>().dsp.display);
    final charts = <(String, String, Color, double Function(ProcessedSample))>[
      ('Aceleração X', 'g', Colors.red, (p) => p.imu.ax),
      ('Aceleração Y', 'g', Colors.green, (p) => p.imu.ay),
      ('Aceleração Z', 'g', Colors.blue, (p) => p.imu.az),
      ('Aceleração resultante', 'g', Colors.black87, (p) => p.a),
      ('Velocidade angular X', '°/s', Colors.red, (p) => p.imu.gx),
      ('Velocidade angular Y', '°/s', Colors.green, (p) => p.imu.gy),
      ('Velocidade angular Z', '°/s', Colors.blue, (p) => p.imu.gz),
      ('Velocidade angular resultante', '°/s', Colors.black87, (p) => p.w),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final ch in charts) SignalChart(title: '${ch.$1} (${ch.$2})', color: ch.$3, spots: _spots(d, ch.$4)),
      ],
    );
  }
}

class SignalChart extends StatelessWidget {
  final String title;
  final List<FlSpot> spots;
  final Color color;
  const SignalChart({super.key, required this.title, required this.spots, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            height: 110,
            child: LineChart(
              LineChartData(
                minX: -10,
                maxX: 0,
                lineTouchData: const LineTouchData(enabled: false),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                    isCurved: false,
                    dotData: const FlDotData(show: false),
                    color: color,
                    barWidth: 1.5,
                  ),
                ],
              ),
              duration: Duration.zero,
            ),
          ),
        ]),
      );
}
