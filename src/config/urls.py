"""
URL configuration for config project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from rest_framework import routers
from restaurant import views

router = routers.DefaultRouter()    # Create a router for BookingViewSet
router.register(r'tables', views.BookingViewSet)    # Register the BookingViewSet with the 

urlpatterns = [
    path('healthz', views.healthz, name='root-healthz'), # Dedicated root health probe for K8s Liveness/Readiness & AWS ALB
    path('admin/', admin.site.urls),
    path('api/', include('restaurant.urls')), # Include URLs from the restaurant app when this path is accessed, Includes /api/menu-items/, /api/healthz, etc.
    path('api/booking/', include(router.urls)),  # Include URLs from the table bookings router when this path is accessed, Resolves to /api/booking/tables/
    path('auth/', include('djoser.urls')),  # Djoser URLs for authentication
    path('auth/', include('djoser.urls.authtoken')),    # Djoser URLs for token authentication
]
