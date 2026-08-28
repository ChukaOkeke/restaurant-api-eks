from django.db import models

# Create your models here.
# The MenuItem model/table for the restaurant application
class MenuItem(models.Model):
    title = models.CharField(max_length=255)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    inventory = models.PositiveIntegerField()

    def __str__(self):
        return f"{self.title} : {str(self.price)}"

# The Booking model/table for the restaurant application
class Booking(models.Model):
    name = models.CharField(max_length=255)
    no_of_guests = models.PositiveIntegerField()
    booking_date = models.DateTimeField()

    def __str__(self):
        return f"{self.name} : {self.booking_date}"