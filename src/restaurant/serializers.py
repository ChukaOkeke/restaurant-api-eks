from rest_framework import serializers
from .models import MenuItem, Booking

# Serializer for Menu model -- convert model instance into JSON
class MenuSerializer(serializers.ModelSerializer):
    class Meta:
        model = MenuItem
        fields = '__all__'

# Serializer for Booking model -- convert model instance into JSON
class BookingSerializer(serializers.ModelSerializer): 
    class Meta:
        model = Booking
        fields = '__all__'