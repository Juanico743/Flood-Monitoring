from django.shortcuts import render, redirect
from django.db.models import Q
from api.models import AdminAuthentication, Sensor
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

