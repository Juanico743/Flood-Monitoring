import requests
from .models import Sensor, SensorData

# Fetch data from all Blynk sensors
def fetch_all_blynk_data():
    sensors = Sensor.objects.all()
    
    if not sensors.exists():
        print("No sensors found in database.")
        return

    for sensor in sensors:
        url = f"https://blynk.cloud/external/api/get?token={sensor.token}&{sensor.pin}"
        
        try:
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                value = response.text.strip()
                
                SensorData.objects.create(
                    sensor=sensor,
                    water_level=float(value)
                )
                print(f"Saved {sensor.sensor_id}: {value}cm")
            else:
                print(f"Blynk Error ({sensor.sensor_id}): Status {response.status_code}")
        except Exception as e:
            print(f"Connection failed for {sensor.sensor_id}: {e}")