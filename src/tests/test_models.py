from django.test import TestCase
from restaurant.models import MenuItem

# TestCase class to test MenuItem model
class MenuItemTest(TestCase):
    # Method to test string representation of MenuItem
    def test_get_item(self):
        item = MenuItem.objects.create(title="IceCream", price=80, inventory=100)   # Create a MenuItem instance
        self.assertEqual(str(item), "IceCream : 80")    # Assert that the string representation is as expected