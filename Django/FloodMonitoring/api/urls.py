from django.urls import path
from .views import (
    VehicleThresholdList, 
    SensorList,
    SensorDataList, 
    EmergencyContactList, 
    AllEmergencyContactData, 
    AllSensorData, 
    AllThresholdData,
    GetSensorHistory
)

urlpatterns = [
    # Your existing individual endpoints
    path('thresholds/', VehicleThresholdList.as_view(), name='threshold-list'),
    path('sensors/', SensorList.as_view(), name='sensor-list'),
    path('contacts/', EmergencyContactList.as_view(), name='contact-list'),
    path('sensor-data/', SensorDataList.as_view(), name='sensor-data-list'),

    # New endpoint to get all data in one request
    path('get-all-contacts/', AllEmergencyContactData.as_view(), name='all-contacts'),
    path('get-all-sensors/', AllSensorData.as_view(), name='all-sensors'),
    path('get-all-thresholds/', AllThresholdData.as_view(), name='all-thresholds'),

    # New endpoint to get sensor history  
    path('get-sensor-history/', GetSensorHistory.as_view(), name='get-sensor-history'),
]