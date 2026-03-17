from django.urls import path
from .views import (
    VehicleThresholdList, 
    SensorList, 
    EmergencyContactList, 
    AllEmergencyContactData, 
    AllSensorData, 
    AllThresholdData
)

urlpatterns = [
    # Your existing individual endpoints
    path('thresholds/', VehicleThresholdList.as_view(), name='threshold-list'),
    path('sensors/', SensorList.as_view(), name='sensor-list'),
    path('contacts/', EmergencyContactList.as_view(), name='contact-list'),

    # New endpoint to get all data in one request
    path('get-all-contacts/', AllEmergencyContactData.as_view(), name='all-contacts'),
    path('get-all-sensors/', AllSensorData.as_view(), name='all-sensors'),
    path('get-all-thresholds/', AllThresholdData.as_view(), name='all-thresholds'),
]