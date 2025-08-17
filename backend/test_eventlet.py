#!/usr/bin/env python3
# Test script to verify eventlet import
try:
    import eventlet
    print(f"✅ eventlet imported successfully! Version: {eventlet.__version__}")
    
    # Test basic eventlet functionality
    import time
    def test_function():
        time.sleep(0.1)
        return "eventlet working!"
    
    # Use eventlet to run the function
    eventlet.monkey_patch()
    result = eventlet.spawn(test_function).wait()
    print(f"✅ eventlet functionality test: {result}")
    
except ImportError as e:
    print(f"❌ Failed to import eventlet: {e}")
except Exception as e:
    print(f"❌ eventlet test failed: {e}")
