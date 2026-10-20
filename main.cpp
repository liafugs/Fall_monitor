// Firmware do sensor vestível: MPU6050 -> ESP32 -> BLE (notify) -> app.
// Formato de cada notificação (texto UTF-8): "ax,ay,az,gx,gy,gz\n"
//   aceleração em g, velocidade angular em °/s, ~50 Hz.
//
// Ligação (MPU6050 -> ESP32): VCC->3V3, GND->GND, SDA->GPIO21, SCL->GPIO22, AD0->GND (0x68).

#include <Arduino.h>
#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// Devem ser iguais aos de lib/utils/constants.dart do app.
#define DEVICE_NAME   "FallSensor-01"   // o app procura nomes que começam com "FallSensor"
#define SERVICE_UUID  "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_UUID     "beb5483e-36e1-4688-b7f5-ea07361b26a8"

#define SDA_PIN 21
#define SCL_PIN 22
#define MPU_ADDR 0x68
#define SAMPLE_HZ 50

#define ACC_LSB_PER_G     2048.0f  // faixa ±16 g
#define GYRO_LSB_PER_DPS  32.8f    // faixa ±1000 °/s

static BLECharacteristic *pChar = nullptr;
static volatile bool clientConnected = false;

class ServerCB : public BLEServerCallbacks {
  void onConnect(BLEServer *) override { clientConnected = true; }
  void onDisconnect(BLEServer *) override {
    clientConnected = false;
    BLEDevice::startAdvertising();  // volta a anunciar para reconexão
  }
};

static void writeReg(uint8_t reg, uint8_t val) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(reg);
  Wire.write(val);
  Wire.endTransmission();
}

static bool readMpu(float v[6]) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x3B);  // ACCEL_XOUT_H
  if (Wire.endTransmission(false) != 0) return false;
  if (Wire.requestFrom((uint8_t)MPU_ADDR, (uint8_t)14) != 14) return false;
  int16_t r[7];
  for (int i = 0; i < 7; i++) {
    uint8_t hi = Wire.read();
    uint8_t lo = Wire.read();
    r[i] = (int16_t)((hi << 8) | lo);
  }
  v[0] = r[0] / ACC_LSB_PER_G;      // ax
  v[1] = r[1] / ACC_LSB_PER_G;      // ay
  v[2] = r[2] / ACC_LSB_PER_G;      // az
  v[3] = r[4] / GYRO_LSB_PER_DPS;   // gx (r[3] é temperatura)
  v[4] = r[5] / GYRO_LSB_PER_DPS;   // gy
  v[5] = r[6] / GYRO_LSB_PER_DPS;   // gz
  return true;
}

void setup() {
  Serial.begin(115200);
  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(400000);

  writeReg(0x6B, 0x00);  // acorda a MPU6050
  delay(100);
  writeReg(0x1A, 0x03);  // filtro passa-baixa digital (~44 Hz)
  writeReg(0x1B, 0x10);  // giroscópio ±1000 °/s
  writeReg(0x1C, 0x18);  // acelerômetro ±16 g

  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x75);  // WHO_AM_I
  Wire.endTransmission(false);
  Wire.requestFrom((uint8_t)MPU_ADDR, (uint8_t)1);
  Serial.printf("WHO_AM_I = 0x%02X (MPU6050 original = 0x68)\n", Wire.read());

  BLEDevice::init(DEVICE_NAME);
  BLEDevice::setMTU(185);  // cabe a linha CSV inteira em uma notificação
  BLEServer *server = BLEDevice::createServer();
  server->setCallbacks(new ServerCB());
  BLEService *service = server->createService(SERVICE_UUID);
  pChar = service->createCharacteristic(CHAR_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  pChar->addDescriptor(new BLE2902());
  service->start();

  BLEAdvertising *adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(SERVICE_UUID);
  adv->setScanResponse(true);
  BLEDevice::startAdvertising();
  Serial.println("Anunciando como " DEVICE_NAME);
}

void loop() {
  static uint32_t next = micros();
  const uint32_t period = 1000000UL / SAMPLE_HZ;
  if ((int32_t)(micros() - next) < 0) return;
  next += period;

  float v[6];
  if (!readMpu(v)) return;

  if (clientConnected) {
    char buf[96];
    int n = snprintf(buf, sizeof(buf), "%.3f,%.3f,%.3f,%.1f,%.1f,%.1f\n",
                     v[0], v[1], v[2], v[3], v[4], v[5]);
    pChar->setValue((uint8_t *)buf, n);
    pChar->notify();
  }
}
