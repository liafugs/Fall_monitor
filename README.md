# Monitor de Quedas (Flutter)

ESP32 + IMU → BLE → app → processamento → detecção por regras → análise pós-queda → índice de severidade → alerta → histórico.

## Rodar
```
flutter create --org br.exemplo --project-name fall_monitor .   # gera android/ e ios/
flutter pub get
flutter run
```
Sem hardware: aba **Início → Usar simulador** (caminha, cai, fica ~19 s imóvel, volta a caminhar; ciclo de 40 s).

### Permissões
- **Android** (`android/app/src/main/AndroidManifest.xml`):
  `BLUETOOTH_SCAN` (`usesPermissionFlags="neverForLocation"`), `BLUETOOTH_CONNECT`,
  e para Android ≤ 11: `BLUETOOTH`, `BLUETOOTH_ADMIN`, `ACCESS_FINE_LOCATION`. `minSdkVersion 21`.
- **iOS** (`ios/Runner/Info.plist`): `NSBluetoothAlwaysUsageDescription`.

## Protocolo do ESP32
Servidor BLE com o nome iniciado por `FallSensor`, serviço `4fafc201-1fb5-459e-8fcc-c5c9c331914b`,
característica (NOTIFY) `beb5483e-36e1-4688-b7f5-ea07361b26a8` (altere em `utils/constants.dart`).
Cada notificação = uma amostra em texto UTF-8: `ax,ay,az,gx,gy,gz` (aceleração em **g**, giro em **°/s**), ~50 Hz.
O app carimba o tempo na recepção.

## Estrutura
- `utils/thresholds.dart` — todos os limiares/pesos (editáveis em Ajustes, salvos em `thresholds.json`).
- `services/fall_detection_service.dart` — interface `FallDetector` + `RuleBasedFallDetector`. Para ML, implemente `FallDetector` e troque em `AppController._buildDetector()`.
- `app_controller.dart` — orquestra os serviços e o fluxo de alerta.
- Dados: `events.json` (processados), `raw_<id>.csv` (brutos de cada evento), CSVs de teste (com atividade e flags do detector).

## Lógica
1. Pico de A ≥ `impactAccelG` abre um candidato. 2. Após `settleSec`, exige ω ≥ `impactGyroDps` ao redor do impacto
e mudança de orientação (ângulo entre vetor de gravidade médio pré e pós) ≥ `orientationChangeDeg`.
3. Aprovado: "possível queda" → tela "Você está bem?" (timeout configurável → alerta superior).
4. Até `postWindowSec` mede movimentação pós-impacto, maior período de imobilidade e retomada do movimento.
5. Índice 0–100 = soma ponderada de pico de aceleração, ω, orientação e imobilidade (normalizados).

## Limitações da v1
- Sem serviço em segundo plano: o monitoramento exige o app aberto (próximo passo: foreground service no Android).
- Envio a contatos externos não implementado (gancho em `AppController.respond`).
- Limiares são experimentais; o índice é estimativa computacional, não avaliação médica.
- Não foi compilado/testado aqui; rode `flutter analyze` e ajuste versões de pacotes se necessário.
