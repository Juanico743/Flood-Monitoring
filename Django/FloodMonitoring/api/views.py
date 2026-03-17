from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import generics
from .models import EmergencyContact, VehicleFloodThreshold, Sensor
from .serializers import ( 
    VehicleThresholdSerializer, 
    SensorSerializer,
    EmergencyContactSerializer,
)

class VehicleThresholdList(generics.ListCreateAPIView):
    queryset = VehicleFloodThreshold.objects.all()
    serializer_class = VehicleThresholdSerializer

class SensorList(generics.ListCreateAPIView):
    queryset = Sensor.objects.all()
    serializer_class = SensorSerializer

class EmergencyContactList(generics.ListCreateAPIView):
    queryset = EmergencyContact.objects.all()
    serializer_class = EmergencyContactSerializer



# New API views to return all data in one request
class AllSensorData(APIView):
    def get(self, request):
        sensors = Sensor.objects.all()
        serializer = SensorSerializer(sensors, many=True)
        return Response({
            "success": True, 
            "sensors": serializer.data
        })

class AllThresholdData(APIView):
    def get(self, request):
        thresholds = VehicleFloodThreshold.objects.all()
        serializer = VehicleThresholdSerializer(thresholds, many=True)
        return Response({
            "success": True, 
            "thresholds": serializer.data
        })
        
class AllEmergencyContactData(APIView):
    def get(self, request):
        contacts = EmergencyContact.objects.all()
        serializer = EmergencyContactSerializer(contacts, many=True)
        return Response({
            "success": True, 
            "emergencyContacts": serializer.data
        })