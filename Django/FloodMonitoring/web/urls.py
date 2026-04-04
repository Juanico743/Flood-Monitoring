from django.urls import path
from .views import login_view, dashboard_view, logout_view

urlpatterns = [
    path('', login_view, name='login'),
    path('dashboard/', dashboard_view, name='dashboard'),

    path('logout/', logout_view, name='logout'),
]