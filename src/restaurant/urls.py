from django.urls import path
from . import views
from rest_framework.authtoken.views import obtain_auth_token

# Define URL routes for the restaurant app
urlpatterns = [
    path('', views.index, name='index'),         # Route for the homepage
    path('healthz', views.healthz, name='healthz'),  # Route for K8s / ALB probes
    path('menu-items/', views.MenuItemsView.as_view(), name='menu-items'),   # Route for the menu items page
    path('menu-items/<int:pk>', views.SingleMenuItemView.as_view(), name='single-menu-item'),  # Route for single menu item operations
    path('api-token-auth/', obtain_auth_token), # Route for obtaining auth token
]