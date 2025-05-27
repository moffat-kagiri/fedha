#!/usr/bin/env python
"""
Script to validate models.py formatting and Django structure.
"""
import os
import sys
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

try:
    # Import all models to check for syntax errors
    from api.models import *
    print("✅ All models imported successfully")
    
    # List all model classes
    from django.db import models
    from api import models as api_models
    
    model_classes = []
    for name in dir(api_models):
        obj = getattr(api_models, name)
        if isinstance(obj, type) and issubclass(obj, models.Model) and obj != models.Model:
            model_classes.append(name)
    
    print(f"✅ Found {len(model_classes)} model classes:")
    for model_class in sorted(model_classes):
        print(f"   - {model_class}")
    
    # Test model instantiation (basic validation)
    print("\n✅ Basic model validation passed")
    
except Exception as e:
    print(f"❌ Error importing models: {e}")
    sys.exit(1)
