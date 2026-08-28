from django.contrib import admin
from .models import MenuItem, Booking

# Register your models here.
admin.site.register(MenuItem) # Registering the MenuItem model
admin.site.register(Booking) # Registering the Booking model