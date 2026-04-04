from django.urls import path
from .views import login_view, dashboard_view, logout_view, sensors_crud_view, threshold_crud_view, emergency_crud_view

urlpatterns = [
    path('', login_view, name='login'),
    path('dashboard/', dashboard_view, name='dashboard'),

    path('logout/', logout_view, name='logout'),

    path('sensors/', sensors_crud_view, name='sensor_crud'),
    path('thresholds/', threshold_crud_view, name='threshold_crud'),
    path('emergency-contacts/', emergency_crud_view, name='contact_crud'),
]