from django.shortcuts import render, redirect
from django.db.models import Q
from api.models import AdminAuthentication, Sensor, VehicleFloodThreshold, EmergencyContact
from django.utils import timezone
from datetime import datetime


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

    sensors = Sensor.objects.all()
    username = request.session.get('username', 'Admin') 
    
    return render(request, 'web/data_management/sensors_crud.html', {
        'sensors': sensors,
        'username': username  
    })

def threshold_crud_view(request):
    if 'admin_id' not in request.session:
        return redirect('login')

    thresholds = VehicleFloodThreshold.objects.all()
    username = request.session.get('username', 'Admin')
    
    return render(request, 'web/data_management/thresholds_crud.html', {
        'thresholds': thresholds,
        'username': username  
    })

def emergency_crud_view(request):
    if 'admin_id' not in request.session:
        return redirect('login')
        
    contacts = EmergencyContact.objects.all()
    username = request.session.get('username', 'Admin')
    
    return render(request, 'web/data_management/emergency_crud.html', {
        'emergencyContacts': contacts,
        'username': username  
    })
