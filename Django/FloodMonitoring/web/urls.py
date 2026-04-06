from django.urls import path
from .views import (
    # Authentication
    login_view, 
    dashboard_view, 
    logout_view,
    
    # Sensors CRUD
    sensors_crud_view, 
    add_sensor, 
    edit_sensor, 
    delete_sensor,
    
    # Thresholds CRUD
    threshold_crud_view, 
    add_threshold, 
    edit_threshold, 
    delete_threshold,
    
    # Emergency Contacts CRUD
    emergency_crud_view,
    add_contact,
    edit_contact,
    delete_contact
)

urlpatterns = [
    # Authentication and Dashboard
    path('', login_view, name='login'),
    path('dashboard/', dashboard_view, name='dashboard'),
    path('logout/', logout_view, name='logout'),

    # CRUD views for Sensors, Thresholds, and Emergency Contacts
    path('sensors/', sensors_crud_view, name='sensor_crud'),
    path('thresholds/', threshold_crud_view, name='threshold_crud'),
    path('emergency-contacts/', emergency_crud_view, name='emergency_crud'),

    # Sensor CRUD views
    path('sensors/add/', add_sensor, name='add_sensor'),
    path('sensors/edit/', edit_sensor, name='edit_sensor'),
    path('sensors/delete/', delete_sensor, name='delete_sensor'),

    # Threshold CRUD views
    path('thresholds/add/', add_threshold, name='add_threshold'),
    path('thresholds/edit/', edit_threshold, name='edit_threshold'),
    path('thresholds/delete/', delete_threshold, name='delete_threshold'),

    # Emergency Contacts CRUD views
    path('contacts/add/', add_contact, name='add_contact'),
    path('contacts/edit/', edit_contact, name='edit_contact'),
    path('contacts/delete/', delete_contact, name='delete_contact'),
]