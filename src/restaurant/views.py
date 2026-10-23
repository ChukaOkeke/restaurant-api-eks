import os
import json
import boto3
from django.shortcuts import render
from django.http import JsonResponse
from rest_framework import generics, viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import MenuItem, Booking
from .serializers import MenuSerializer, BookingSerializer
from django.core.cache import cache
from django.conf import settings


# Create your views here.
# Lightweight unauthenticated health-check endpoint for K8s Probes and AWS ALB.
def healthz(request):
    return JsonResponse({"status": "healthy"}, status=200)


# Function-based view to render the homepage to the client.
def index(request):
    return render(request, 'restaurant/index.html')


# Class-based view to handle Menu items (Synchronous Path with Redis Cache-Aside Pattern).
class MenuItemsView(generics.ListCreateAPIView):
    queryset = MenuItem.objects.all()  # Fetch all menu items from the database
    serializer_class = MenuSerializer  # Serialize the menu items

    def get(self, request, *args, **kwargs):
        cache_key = 'menu_items_list'
        
        # 1. Try reading from Redis cache safely
        try:
            cached_data = cache.get(cache_key)
            if cached_data is not None:
                return Response(cached_data, status=status.HTTP_200_OK)
        except Exception:
            pass  # Fall back to database query if Redis is unreachable

        # 2. Cache Miss or Redis offline: Fall back to database query
        response = super().get(request, *args, **kwargs)

        # 3. Try storing in Redis safely
        try:
            cache.set(cache_key, response.data, timeout=getattr(settings, 'CACHE_TTL', 300))
        except Exception:
            pass

        return response

    def perform_create(self, serializer):
        serializer.save()
        try:
            cache.delete('menu_items_list')
        except Exception:
            pass


# Class-based view to handle a single Menu item (Synchronous Path with Redis Cache-Aside Pattern).
class SingleMenuItemView(generics.RetrieveUpdateAPIView, generics.DestroyAPIView):
    queryset = MenuItem.objects.all()  # Fetch menu item from the database
    serializer_class = MenuSerializer  # Serialize the menu item

    def get(self, request, *args, **kwargs):
        pk = kwargs.get('pk')
        cache_key = f'menu_item_{pk}'
        
        # 1. Check cache for this specific item
        try:
            cached_data = cache.get(cache_key)
            if cached_data is not None:
                return Response(cached_data, status=status.HTTP_200_OK)
        except Exception:
            pass

        # 2. Cache Miss: Fetch from RDS PostgreSQL
        response = super().get(request, *args, **kwargs)
        
        # 3. Store in Redis
        try:
            cache.set(cache_key, response.data, timeout=getattr(settings, 'CACHE_TTL', 300))
        except Exception:
            pass
            
        return response

    def perform_update(self, serializer):
        serializer.save()
        pk = self.kwargs.get('pk')
        # Invalidate both the specific item cache and the general menu list cache
        try:
            cache.delete(f'menu_item_{pk}')
            cache.delete('menu_items_list')
        except Exception:
            pass

    def perform_destroy(self, instance):
        pk = instance.pk
        instance.delete()
        # Invalidate both caches on deletion
        try:
            cache.delete(f'menu_item_{pk}')
            cache.delete('menu_items_list')
        except Exception:
            pass
        

# Viewset view to handle Bookings (Asynchronous Path).
class BookingViewSet(viewsets.ModelViewSet):
    queryset = Booking.objects.all()  # Fetch all bookings from the database
    serializer_class = BookingSerializer  # Serialize the bookings
    permission_classes = [IsAuthenticated]  # Only authenticated users can access booking endpoints

    def create(self, request, *args, **kwargs):
        """
        Intercepts POST requests, validates the data, and pushes it to SQS 
        for asynchronous processing instead of synchronous database writes.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        queue_url = os.getenv('SQS_QUEUE_URL')
        
        # Fallback for local SQLite testing or if the queue is missing in the environment.
        if not queue_url or os.getenv('CI_MODE') == 'True':
            self.perform_create(serializer)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        booking_data = serializer.validated_data
        
        # Prepare the payload for SQS (converting datetime to ISO string).
        sqs_payload = {
            "name": booking_data.get('name'),
            "no_of_guests": booking_data.get('no_of_guests'),
            "booking_date": booking_data.get('booking_date').isoformat() if booking_data.get('booking_date') else None
        }

        try:
            # Native SDK usage — authorization relies on EKS Pod Identity Agent.
            sqs_client = boto3.client('sqs', region_name=os.getenv('AWS_REGION', 'eu-west-1'))
            sqs_client.send_message(
                QueueUrl=queue_url,
                MessageBody=json.dumps(sqs_payload)
            )
            
            return Response(
                {"message": "Booking request received. Processing asynchronously."},
                status=status.HTTP_202_ACCEPTED
            )
            
        except Exception as e:
            print(f"SQS Dispatch Error: {str(e)}")
            return Response(
                {"error": "Failed to queue booking request."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )