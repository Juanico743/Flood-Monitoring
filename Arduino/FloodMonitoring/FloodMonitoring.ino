#define BLYNK_TEMPLATE_ID "TMPL6gAdg04Tj"
#define BLYNK_TEMPLATE_NAME "Actual Distance"
#define BLYNK_AUTH_TOKEN "rDsIi--IkEDcdOVLSBXh2DvfusmwPSFc"

#include <WiFi.h>
#include <WiFiClient.h>
#include <BlynkSimpleEsp32.h>

// char ssid[] = "Sheeesh";
// char pass[] = "_UmayGad_";

char ssid[] = "🐞 フアニコ 🐞";
char pass[] = "Juanico@19761964";

// A02YYUW TX -> ESP32 RX pin
#define RXD2 16

BlynkTimer timer;

void sendDistance() {
  if (Serial2.available() >= 4) {
    uint8_t buffer[4];
    Serial2.readBytes(buffer, 4);

    if (buffer[0] == 0xFF) { // check header
      float distance = ((buffer[1] << 8) + buffer[2]) / 10.0; // in cm (float)
      uint8_t sum = (buffer[0] + buffer[1] + buffer[2]) & 0xFF;

      if (sum == buffer[3]) { // checksum valid
        Serial.print("Distance: ");
        Serial.print(distance, 1); // print with 1 decimal place
        Serial.println(" cm");

        // Send to Blynk
        Blynk.virtualWrite(V0, distance);
      } else {
        Serial.println("Checksum error");
      }
    }
  }
}

void setup() {
  Serial.begin(9600);
  Serial2.begin(9600, SERIAL_8N1, RXD2, -1); // only RX

  Serial.println("Connecting to WiFi...");
  Blynk.begin(BLYNK_AUTH_TOKEN, ssid, pass);

  timer.setInterval(40L, sendDistance);
}

void loop() {
  Blynk.run();
  timer.run();
}