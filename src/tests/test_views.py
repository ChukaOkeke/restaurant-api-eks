from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from restaurant.models import MenuItem
from restaurant.serializers import MenuSerializer

# TestCase class to test MenuItemsView view
class MenuViewTest(TestCase):
    # Method to add test instances to the MenuItem model
    def setUp(self):
        self.client = APIClient()   # Initialize the APIClient to simulate API requests
        # Create test instances of the MenuItem model
        MenuItem.objects.create(title="IceCream", price=1500, inventory=100)
        MenuItem.objects.create(title="Pizza", price=3000, inventory=80)

    # Method to test GET request to fetch all menu items
    def test_getall(self):
        items = MenuItem.objects.all()   # Retrieve all MenuItem objects from the database
        serializer = MenuSerializer(items, many=True).data  # Serialize the retrieved menu items, many=True indicates multiple objects
        response = self.client.get(reverse('menu-items'))  # Fetch the data from the view using the URL
        self.assertEqual(response.status_code, status.HTTP_200_OK)  # Assert that the response status code is 200 OK
        self.assertEqual(response.data, serializer)  # Assert that the response data matches the serialized
