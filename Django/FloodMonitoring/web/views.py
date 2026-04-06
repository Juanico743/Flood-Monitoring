from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from django.db.models import Q, Max
from api.models import AdminAuthentication, Sensor, VehicleFloodThreshold, EmergencyContact
from django.core.paginator import Paginator
from django.utils import timezone
from datetime import datetime
from decimal import Decimal
import re

def login_view(request):
    if 'admin_id' in request.session:
        login_time_str = request.session.get('login_time')
        login_time = datetime.fromisoformat(login_time_str)
        
        elapsed_time = (timezone.now() - login_time).total_seconds()
        
        if elapsed_time < 7200:
            return redirect('dashboard')
        else:
        
            request.session.flush()

    if request.method == "POST":
        user_input = request.POST.get('username')
        password_input = request.POST.get('password')
        
        user = AdminAuthentication.objects.filter(
            Q(username=user_input) | Q(email=user_input)
        ).first()
        
        if user and user.password == password_input:
            
            request.session['admin_id'] = user.id
            request.session['username'] = user.username
            request.session['login_time'] = timezone.now().isoformat()
            return redirect('dashboard')
        else:
            return render(request, 'web/login.html', {'error': 'Invalid credentials'})

    return render(request, 'web/login.html')


def dashboard_view(request):
    if 'admin_id' not in request.session:
        return redirect('login')
        
    sensors = Sensor.objects.all() 
    return render(request, 'web/dashboard.html', {
        'sensors': sensors,
        'username': request.session.get('username')
    })


def logout_view(request):
    request.session.flush() 
    return redirect('login')






def sensors_crud_view(request):
    if 'admin_id' not in request.session:
        return redirect('login')

    sensor_list = Sensor.objects.all().order_by('sensor_id') 
    
    paginator = Paginator(sensor_list, 6)
    page_number = request.GET.get('page')
    sensors = paginator.get_page(page_number)

    username = request.session.get('username', 'Admin') 
    
    return render(request, 'web/data_management/sensors_crud.html', {
        'sensors': sensors, 
        'username': username  
    })

def threshold_crud_view(request):
    if 'admin_id' not in request.session:
        return redirect('login')

    threshold_list = VehicleFloodThreshold.objects.all().order_by('id') 
    
    paginator = Paginator(threshold_list, 8)
    page_number = request.GET.get('page')
    thresholds = paginator.get_page(page_number)

    username = request.session.get('username', 'Admin')
    
    return render(request, 'web/data_management/thresholds_crud.html', {
        'thresholds': thresholds,
        'username': username  
    })

def emergency_crud_view(request):
    if 'admin_id' not in request.session:
        return redirect('login')
        
    contacts_list = EmergencyContact.objects.all().order_by('name') 
    
    paginator = Paginator(contacts_list, 8) 
    
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    username = request.session.get('username', 'Admin')
    
    return render(request, 'web/data_management/emergency_crud.html', {
        'emergencyContacts': page_obj, 
        'username': username  
    })




def generate_next_sensor_id():
    last_sensor = Sensor.objects.all().order_by('sensor_id').last()
    
    if not last_sensor:
        return "sensor_01"
    
    match = re.search(r'(\d+)$', last_sensor.sensor_id)
    if match:
        next_number = int(match.group(1)) + 1
        return f"sensor_{next_number:02d}"
    
    return "sensor_01"


def add_sensor(request):
    if request.method == 'POST':
        # AUTOMATIC ID GENERATION
        new_id = generate_next_sensor_id()
        
        Sensor.objects.create(
            sensor_id=new_id, # Use the generated ID
            location_name=request.POST.get('location_name'),
            latitude=request.POST.get('latitude'),
            longitude=request.POST.get('longitude'),
            token=request.POST.get('token'),
            pin=request.POST.get('pin'),
            radius=request.POST.get('radius', 100.0),
            height=request.POST.get('height', 1.0)
        )
        messages.success(request, f"Added new sensor: {new_id}")
    return redirect('sensor_crud')

def edit_sensor(request):
    if request.method == 'POST':
        sensor_id = request.POST.get('sensor_id')
        sensor = get_object_or_404(Sensor, sensor_id=sensor_id)
        
        sensor.location_name = request.POST.get('location_name')
        sensor.latitude = request.POST.get('latitude')
        sensor.longitude = request.POST.get('longitude')
        sensor.token = request.POST.get('token')
        sensor.pin = request.POST.get('pin')
        sensor.radius = request.POST.get('radius')
        sensor.height = request.POST.get('height')
        sensor.save()
        
        messages.success(request, f"Updated sensor '{sensor_id}' settings.")
    return redirect('sensor_crud')

def delete_sensor(request):
    if request.method == 'POST':
        sensor_id = request.POST.get('sensor_id')
        sensor = get_object_or_404(Sensor, sensor_id=sensor_id)
        sensor.delete()
        messages.success(request, f"Deleted sensor '{sensor_id}'.")
    return redirect('sensor_crud')



def add_threshold(request):
    if request.method == 'POST':
        vehicle = request.POST.get('vehicle')
        w_min = Decimal(request.POST.get('warning_min'))
        d_min = Decimal(request.POST.get('danger_min'))

        # Simple Validation
        if w_min >= d_min:
            messages.error(request, "Warning point must be lower than Danger point.")
            return redirect('threshold_crud')

        if VehicleFloodThreshold.objects.filter(vehicle__iexact=vehicle).exists():
            messages.error(request, f"Threshold for '{vehicle}' already exists.")
            return redirect('threshold_crud')

        VehicleFloodThreshold.objects.create(
            vehicle=vehicle,
            safe_min=0,
            safe_max=w_min - Decimal('0.01'), 
            warning_min=w_min,
            warning_max=d_min - Decimal('0.01'), 
            danger_min=d_min,
        )
        messages.success(request, f"Added threshold for '{vehicle}'.")
    return redirect('threshold_crud')

def edit_threshold(request):
    if request.method == 'POST':
        threshold_id = request.POST.get('threshold_id')
        threshold = get_object_or_404(VehicleFloodThreshold, id=threshold_id)
        
        w_min = Decimal(request.POST.get('warning_min'))
        d_min = Decimal(request.POST.get('danger_min'))

        if w_min >= d_min:
            messages.error(request, "Warning point must be lower than Danger point.")
            return redirect('threshold_crud')

        threshold.vehicle = request.POST.get('vehicle')
        threshold.safe_min = 0
        threshold.safe_max = w_min - Decimal('0.01')
        threshold.warning_min = w_min
        threshold.warning_max = d_min - Decimal('0.01')
        threshold.danger_min = d_min
        threshold.save()
        
        messages.success(request, f"Updated {threshold.vehicle} settings.")
    return redirect('threshold_crud')

def delete_threshold(request):
    if request.method == 'POST':
        threshold_id = request.POST.get('threshold_id')
        threshold = get_object_or_404(VehicleFloodThreshold, id=threshold_id)
        
        vehicle_name = threshold.vehicle
        
        # --- THE MISSING PART ---
        threshold.delete() 
        # ------------------------
        
        messages.success(request, f"Deleted {vehicle_name} settings.")
        
    return redirect('threshold_crud')



def add_contact(request):
    if request.method == 'POST':
        name = request.POST.get('name')
        phone = request.POST.get('phone_number')
        description = request.POST.get('description')
        
        EmergencyContact.objects.create(
            name=name,
            phone_number=phone,
            description=description
        )
        messages.success(request, f"Contact '{name}' added successfully!")
    return redirect('contact_crud') # Replace with your actual URL name

def edit_contact(request):
    if request.method == 'POST':
        contact_id = request.POST.get('contact_id')
        contact = get_object_or_404(EmergencyContact, id=contact_id)
        
        contact.name = request.POST.get('name')
        contact.phone_number = request.POST.get('phone_number')
        contact.description = request.POST.get('description')
        contact.save()
        
        messages.success(request, f"Updated {contact.name} successfully.")
    return redirect('contact_crud')

def delete_contact(request):
    if request.method == 'POST':
        contact_id = request.POST.get('contact_id')
        contact = get_object_or_404(EmergencyContact, id=contact_id)
        name = contact.name
        contact.delete()
        messages.success(request, f"Removed {name} from directory.")
    return redirect('contact_crud')




