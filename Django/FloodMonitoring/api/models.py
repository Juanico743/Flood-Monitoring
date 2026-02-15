from django.db import models



# Model to define flood water level thresholds for different vehicle types
class VehicleFloodThreshold(models.Model):
    vehicle = models.CharField(max_length=100, help_text="Type of vehicle (e.g., Car, Motorcycle)")
    
    # Safe Range
    safe_min = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    safe_max = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Warning Range
    warning_min = models.DecimalField(max_digits=10, decimal_places=2)
    warning_max = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Danger Range (Min only, since Max is effectively infinity)
    danger_min = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return self.vehicle if self.vehicle else "General Threshold"




# Model to represent flood monitoring sensors and their data
class Sensor(models.Model):
    sensor_id = models.CharField(max_length=50, unique=True, help_text="e.g., sensor_01")
    location_name = models.CharField(max_length=255, blank=True, help_text="e.g., Near basketball Court")
    
    # Position
    latitude = models.DecimalField(max_digits=22, decimal_places=16)
    longitude = models.DecimalField(max_digits=22, decimal_places=16)
    
    # Connection Info
    token = models.CharField(max_length=255)
    pin = models.CharField(max_length=10)
    radius = models.FloatField(default=100.0)

    def __str__(self):
        return f"{self.sensor_id} - {self.location_name}"