import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_controller.dart';
import '../models/fall_event.dart';
import '../utils/constants.dart';

class FallAlertScreen extends StatelessWidget {
  const FallAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final r = c.response;
    final waiting = r == null;
    final bg = waiting
        ? Colors.orange.shade100
        : (r == UserResponse.okay ? Colors.green.shade100 : Colors.red.shade100);

    final title = waiting
        ? 'Possível queda detectada.'
        : (r == UserResponse.needHelp
            ? 'Emergência registrada.'
            : 'Sem resposta. Alerta de nível superior gerado.');

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.warning_amber_rounded, size: 96),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              if (waiting) ...[
                const SizedBox(height: 12),
                const Text('Você está bem?', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                Text('Responda em ${c.alertSecondsLeft} s'),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                    onPressed: () {
                      c.respond(UserResponse.okay);
                      c.dismissAlert();
                      Navigator.of(context).pop();
                    },
                    child: const Text('ESTOU BEM', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                    onPressed: () => c.respond(UserResponse.needHelp),
                    child: const Text('PRECISO DE AJUDA', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                const Text('O envio a contatos externos ainda não está implementado.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    c.dismissAlert();
                    Navigator.of(context).pop();
                  },
                  child: const Text('FECHAR'),
                ),
              ],
              const SizedBox(height: 24),
              Text(Constants.disclaimer,
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ),
      ),
    );
  }
}
