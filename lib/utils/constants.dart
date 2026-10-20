class Constants {
  static const appName = 'Monitor de Quedas';

  // BLE: o ESP32 deve anunciar um nome iniciado por este prefixo.
  static const deviceNamePrefix = 'FallSensor';
  static const serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  static const simulationHz = 50;
  static const chartWindowSeconds = 10;

  static const disclaimer =
      'O índice de severidade é uma estimativa computacional da severidade do '
      'evento de queda. Não é uma avaliação médica da gravidade nem indica a '
      'existência de lesão.';

  static const testActivities = [
    'Caminhada',
    'Sentar',
    'Levantar',
    'Deitar',
    'Movimento brusco',
    'Tropeço sem queda',
    'Queda para frente',
    'Queda para trás',
    'Queda lateral',
  ];
}
