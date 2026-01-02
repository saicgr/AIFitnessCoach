"""
Lambda handler for FitWiz API.
Uses Mangum to wrap FastAPI for AWS Lambda compatibility.
"""
from mangum import Mangum
from main import app

# Create Lambda handler using Mangum
# This wraps the FastAPI application to make it compatible with Lambda's event format
handler = Mangum(app, lifespan="off")
