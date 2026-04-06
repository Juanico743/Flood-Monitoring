from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import generics
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.db.models import Avg
from django.db.models.functions import TruncHour, TruncDay, TruncMonth
from dateutil.relativedelta import relativedelta
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

# API view to get sensor history for the past 24 hours
class GetSensorHistory(APIView):
    def post(self, request):
        sensor_id = request.data.get('sensor_id')
        sensor = get_object_or_404(Sensor, sensor_id=sensor_id)
        sensor_height_cm = sensor.height * 100 

        now_local = timezone.localtime(timezone.now())
        end_time = now_local.replace(minute=0, second=0, microsecond=0)
        start_time = end_time - timedelta(hours=23)

        data_query = SensorData.objects.filter(
            sensor_id=sensor_id,
            timestamp__range=(start_time, end_time)
        ).values('timestamp', 'water_level')

        hourly_totals = {} 
        
        for entry in data_query:
            local_ts = timezone.localtime(entry['timestamp'])
            hour_key = local_ts.strftime('%Y-%m-%d %H:00')
            
            if hour_key not in hourly_totals:
                hourly_totals[hour_key] = []
            hourly_totals[hour_key].append(float(entry['water_level'] or 0.0))

        history_map = {
            key: sum(val_list) / len(val_list) 
            for key, val_list in hourly_totals.items()
        }
        
        spots = []
        labels = [] 
        
        for i in range(24):
            current_slot = start_time + timedelta(hours=i)
            slot_str = current_slot.strftime('%Y-%m-%d %H:00')
            
            time_label = current_slot.strftime('%b %d, %H:%M') 
            labels.append(time_label)

            distance_to_water = history_map.get(slot_str, sensor_height_cm)
            flood_height_cm = max(0, sensor_height_cm - distance_to_water)
            level_in_feet = round(flood_height_cm / 30.48, 2)
            
            spots.append({"x": float(i), "y": level_in_feet})

        return Response({
            "success": True,
            "labels": labels, 
            "hourlyData": spots
        })

# API view to get web chart data for selected sensor and time range
class GetWebChartData(APIView):
    def post(self, request):
        sensor_id = request.data.get('sensor_id') 
        time_range = request.data.get('range', 'hour') 
        
        now = timezone.localtime(timezone.now())
        
        if time_range == 'year':
            start_time = (now - relativedelta(months=11)).replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            slots = 12
        elif time_range == 'month':
            start_time = (now - timedelta(days=30)).replace(hour=0, minute=0, second=0, microsecond=0)
            slots = 31
        elif time_range == 'week':
            start_time = (now - timedelta(days=7)).replace(hour=0, minute=0, second=0, microsecond=0)
            slots = 8
        elif time_range == 'day':
            start_time = (now - timedelta(hours=23)).replace(minute=0, second=0, microsecond=0)
            slots = 24
        else: # hour
            base_now = now.replace(minute=(now.minute // 5) * 5, second=0, microsecond=0)
            start_time = base_now - timedelta(minutes=55)
            slots = 12

        query = SensorData.objects.filter(timestamp__range=(start_time, now))
        if sensor_id != 'all':
            query = query.filter(sensor_id=sensor_id)
            sensors = Sensor.objects.filter(sensor_id=sensor_id)
        else:
            sensors = Sensor.objects.all()

        raw_data = query.values('sensor_id', 'timestamp', 'water_level')
        history_totals = {} 

        for entry in raw_data:
            local_ts = timezone.localtime(entry['timestamp'])
            s_id = entry['sensor_id']
            
            if time_range == 'year':
                bucket_dt = local_ts.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            elif time_range in ['month', 'week']:
                bucket_dt = local_ts.replace(hour=0, minute=0, second=0, microsecond=0)
            elif time_range == 'day':
                bucket_dt = local_ts.replace(minute=0, second=0, microsecond=0)
            else: # hour
                minute_bucket = (local_ts.minute // 5) * 5
                bucket_dt = local_ts.replace(minute=minute_bucket, second=0, microsecond=0)
            
            key = (s_id, bucket_dt.isoformat())
            if key not in history_totals:
                history_totals[key] = []
            history_totals[key].append(float(entry['water_level'] or 0.0))

        history_map = {
            key: sum(val_list) / len(val_list) 
            for key, val_list in history_totals.items()
        }

        datasets = []
        for s in sensors:
            sensor_height_cm = float(s.height) * 100
            points = []
            
            for i in range(slots):
                if time_range == 'year':
                    current_slot = start_time + relativedelta(months=i)
                elif time_range in ['month', 'week']:
                    current_slot = start_time + timedelta(days=i)
                elif time_range == 'day':
                    current_slot = start_time + timedelta(hours=i)
                else: # hour
                    current_slot = start_time + timedelta(minutes=i*5)
                
                slot_str = current_slot.isoformat()
                
                dist_to_water = history_map.get((s.sensor_id, slot_str), sensor_height_cm)
                
                flood_cm = max(0, sensor_height_cm - dist_to_water)
                level_ft = round(flood_cm / 30.48, 2)
                
                points.append({"x": slot_str, "y": level_ft})
            
            datasets.append({
                "label": f"{s.sensor_id} ({s.location_name})",
                "data": points
            })

        return Response({"success": True, "datasets": datasets})
