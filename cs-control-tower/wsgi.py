"""
wsgi.py — Gunicorn entry point for cs-control-tower
Usage:
    gunicorn wsgi:application --bind 0.0.0.0:5000 --workers 2
"""
from app import create_app

application = create_app()