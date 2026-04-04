from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import generics
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.db.models import Avg
from django.db.models.functions import TruncHour, TruncDay, TruncMonth
from django.utils import timezone
from datetime import timedelta
from .models import EmergencyContact, VehicleFloodThreshold, Sensor, SensorData
from .serializers import ( 
    VehicleThresholdSerializer, 
    SensorSerializer,
    EmergencyContactSerializer,
    SensorDataSerializer,
)

class VehicleThresholdList(generics.ListCreateAPIView):
    queryset = VehicleFloodThreshold.objects.all()
    serializer_class = VehicleThresholdSerializer

class SensorList(generics.ListCreateAPIView):
    queryset = Sensor.objects.all()
    serializer_class = SensorSerializer

class SensorDataList(generics.ListCreateAPIView):
    queryset = SensorData.objects.all()
    serializer_class = SensorDataSerializer

class EmergencyContactList(generics.ListCreateAPIView):
    queryset = EmergencyContact.objects.all()
    serializer_class = EmergencyContactSerializer


# API views to return all data in one request
class AllSensorData(APIView):
    def get(self, request):
        sensors = Sensor.objects.all()
        serializer = SensorSerializer(sensors, many=True)
        return Response({
            "success": True, 
            "sensors": serializer.data
        })

# API views to return all data in one request
class AllThresholdData(APIView):
    def get(self, request):
        thresholds = VehicleFloodThreshold.objects.all()
        serializer = VehicleThresholdSerializer(thresholds, many=True)
        return Response({
            "success": True, 
            "thresholds": serializer.data
        })

# API views to return all data in one request    
class AllEmergencyContactData(APIView):
    def get(self, request):
        contacts = EmergencyContact.objects.all()
        serializer = EmergencyContactSerializer(contacts, many=True)
        return Response({
            "success": True, 
            "emergencyContacts": serializer.data
        })

# API view to get sensor history for the past 72 hours
class GetSensorHistory(APIView):
    def post(self, request):
        sensor_id = request.data.get('sensor_id')
        
        sensor = get_object_or_404(Sensor, sensor_id=sensor_id)
        sensor_height_cm = sensor.height * 100 

        end_time = timezone.now()
        start_time = end_time - timedelta(hours=72)

        data = (
            SensorData.objects.filter(
                sensor_id=sensor_id,
                timestamp__range=(start_time, end_time)
            )
            .annotate(hour=TruncHour('timestamp'))
            .values('hour')
            .annotate(avg_level=Avg('water_level')) 
            .order_by('hour')
        )

        history_map = {
            item['hour'].strftime('%Y-%m-%d %H:00'): float(item['avg_level'] or 0.0) 
            for item in data
        }
        
        spots = []
        labels = []
        
        for i in range(72):
            current_slot = (start_time + timedelta(hours=i)).replace(minute=0, second=0, microsecond=0)
            slot_str = current_slot.strftime('%Y-%m-%d %H:00')
            
            distance_to_water = history_map.get(slot_str, sensor_height_cm)
            
            flood_height_cm = sensor_height_cm - distance_to_water
            
            if flood_height_cm < 0:
                flood_height_cm = 0
            
            level_in_feet = flood_height_cm / 30.48 
            
            spots.append({"x": float(i), "y": round(level_in_feet, 2)})
            
            if i in [12, 36, 60]:
                labels.append(current_slot.strftime('%b %d'))

        return Response({
            "success": True,
            "labels": labels,
            "hourlyData": spots
        })

# API view to get web chart data for selected sensor and time range
class GetWebChartData(APIView):
    def post(self, request):
        sensor_id = request.data.get('sensor_id') 
        time_range = request.data.get('range', 'day') 
        
        end_time = timezone.now()
        
        # Determine Range and Aggregation
        if time_range == 'year':
            start_time = end_time - timedelta(days=365)
            trunc_func = TruncMonth('timestamp')
            slots = 12
            delta = timedelta(days=30) # Approximate for logic
        elif time_range == 'month':
            start_time = end_time - timedelta(days=30)
            trunc_func = TruncDay('timestamp')
            slots = 30
            delta = timedelta(days=1)
        else: # 'day'
            start_time = end_time - timedelta(hours=24)
            trunc_func = TruncHour('timestamp')
            slots = 24
            delta = timedelta(hours=1)

        # Fetch Data
        query = SensorData.objects.filter(timestamp__range=(start_time, end_time))
        if sensor_id != 'all':
            query = query.filter(sensor_id=sensor_id)
            sensors = [get_object_or_404(Sensor, sensor_id=sensor_id)]
        else:
            sensors = Sensor.objects.all()

        # Group data
        data_query = (
            query.annotate(slot=trunc_func)
            .values('slot', 'sensor_id')
            .annotate(avg_level=Avg('water_level'))
        )

        # Create a map for quick lookup
        history_map = {
            (item['sensor_id'], item['slot'].isoformat()): float(item['avg_level'] or 0.0)
            for item in data_query
        }

        # Format Response for Chart.js
        datasets = []
        for s in sensors:
            sensor_height_cm = s.height * 100
            points = []
            
            for i in range(slots):
                if time_range == 'year':
                    current_slot = (start_time + timedelta(days=i*30)).replace(day=1, hour=0, minute=0)
                else:
                    current_slot = (start_time + delta * i).replace(minute=0, second=0, microsecond=0)
                
                slot_str = current_slot.isoformat()
                
                # Calculation Logic
                dist_to_water = history_map.get((s.sensor_id, slot_str), sensor_height_cm)
                flood_cm = max(0, sensor_height_cm - dist_to_water)
                level_ft = round(flood_cm / 30.48, 2)
                
                points.append({"x": slot_str, "y": level_ft})
            
            datasets.append({
                "label": f"{s.sensor_id} ({s.location_name})",
                "data": points
            })

        return Response({
            "success": True,
            "datasets": datasets
        })


