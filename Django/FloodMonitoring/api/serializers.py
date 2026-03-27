from rest_framework import serializers
from .models import VehicleFloodThreshold, Sensor, EmergencyContact, SensorData

class EmergencyContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmergencyContact
        fields = '__all__'

class VehicleThresholdSerializer(serializers.ModelSerializer):
    class Meta:
        model = VehicleFloodThreshold
        fields = '__all__'

class SensorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Sensor
        fields = '__all__'

class SensorDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = SensorData
        fields = '__all__'