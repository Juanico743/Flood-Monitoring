#define BLYNK_TEMPLATE_ID "TMPL6gAdg04Tj"
#define BLYNK_TEMPLATE_NAME "Actual Distance"
#define BLYNK_AUTH_TOKEN "rDsIi--IkEDcdOVLSBXh2DvfusmwPSFc"

#define TINY_GSM_MODEM_SIM7600
#define BLYNK_HEARTBEAT 30 

#include <TinyGsmClient.h>
#include <BlynkSimpleTinyGSM.h>
#include "soc/soc.h"
#include "soc/rtc_cntl_reg.h"

// T-SIM7600 Hardware Pins
#define MODEM_TX             27
#define MODEM_RX             26
#define BOARD_PWRKEY         4
#define BOARD_POWERON        12  
#define MODEM_FLIGHT         25  

// A02YYUW Sensor Pins
#define SENSOR_RX            13 // Connected to Sensor TX
#define SENSOR_TX            15 // Connected to Sensor RX
#define DISTANCE_VPIN        V0

const char apn[]      = "internet"; 
const char gprsUser[] = "";
const char gprsPass[] = "";

HardwareSerial MySensor(1); 
HardwareSerial SerialAT(2); 
TinyGsm modem(SerialAT);
BlynkTimer timer;

void sendDistance() {
  uint32_t startTime = millis();
  bool foundData = false;

  // Clear the buffer of any electrical noise
  while (MySensor.available()) { MySensor.read(); }
  delay(100); // Wait for a fresh packet

  // Look for the 0xFF start bit for up to 1 second
  while (millis() - startTime < 1000) {
    if (MySensor.available() >= 4) {
      uint8_t buffer[4];
      if (MySensor.read() == 0xFF) {
        buffer[0] = 0xFF;
        MySensor.readBytes(&buffer[1], 3);
        
        uint8_t sum = (buffer[0] + buffer[1] + buffer[2]) & 0xFF;
        if (sum == buffer[3]) {
          float distance = ((buffer[1] << 8) + buffer[2]) / 10.0;
          
          Serial.print("Sensor Read: ");
          Serial.print(distance);
          Serial.println(" cm");

          if (Blynk.connected()) {
            Blynk.virtualWrite(DISTANCE_VPIN, distance);
          }
          foundData = true;
          break;
        }
      }
    }
  }

  if (!foundData) {
    Serial.println("Sensor Error: No valid data. Check 5V power!");
  }
}

void setup() {
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);
  Serial.begin(115200);

  pinMode(BOARD_PWRKEY, OUTPUT);
  pinMode(BOARD_POWERON, OUTPUT);
  pinMode(MODEM_FLIGHT, OUTPUT);

  // Wake the hardware
  digitalWrite(BOARD_POWERON, HIGH); 
  digitalWrite(MODEM_FLIGHT, HIGH);  
  
  digitalWrite(BOARD_PWRKEY, LOW);
  delay(100);
  digitalWrite(BOARD_PWRKEY, HIGH);
  delay(1000); 
  digitalWrite(BOARD_PWRKEY, LOW);
  
  delay(15000); // Wait for Smart Network

  // Initialize Serials with specific pins
  SerialAT.begin(115200, SERIAL_8N1, MODEM_RX, MODEM_TX);
  MySensor.begin(9600, SERIAL_8N1, SENSOR_RX, SENSOR_TX);

  Serial.println("Connecting to Blynk...");
  Blynk.begin(BLYNK_AUTH_TOKEN, modem, apn, gprsUser, gprsPass);

  timer.setInterval(2000L, sendDistance); 
}

void loop() {
  Blynk.run();
  timer.run();
}