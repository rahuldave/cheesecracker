"""
System tests of the API server
Send real HTTP requests to the server at localhost:9000, the deployment
"""

import pytest
import requests


# Base URL for the API (assumes API is running)
API_BASE_URL = "http://localhost:9000"


@pytest.fixture(scope="module")
def server():
    """Fail the tests that use it when no server answers at localhost:9000"""
    try:
        requests.get(f"{API_BASE_URL}/health", timeout=2)
    except requests.RequestException:
        pytest.fail(f"no server at {API_BASE_URL}: start one with just docker-serve", pytrace=False)


@pytest.mark.usefixtures("server")
class TestAPIEndpoints:
    """System tests of the endpoints, through the running server"""

    def test_root_endpoint(self):
        """Test the root endpoint returns welcome message"""
        response = requests.get(f"{API_BASE_URL}/")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "Cheese App" in data["message"]

    def test_health_check(self):
        """Test health check endpoint"""
        response = requests.get(f"{API_BASE_URL}/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    def test_euclidean_distance_endpoint_default(self):
        """Test euclidean_distance endpoint with default values"""
        response = requests.get(f"{API_BASE_URL}/euclidean_distance/")
        assert response.status_code == 200
        data = response.json()
        assert "distance" in data
        assert data["x"] == 1.0
        assert data["y"] == 2.0
        assert data["distance"] == pytest.approx(2.236, rel=0.01)

    def test_euclidean_distance_endpoint_custom_values(self):
        """Test euclidean_distance endpoint with custom values (3, 4)"""
        response = requests.get(f"{API_BASE_URL}/euclidean_distance/?x=3&y=4")
        assert response.status_code == 200
        data = response.json()
        assert data["distance"] == pytest.approx(5.0)


# Standalone tests that don't require running API
class TestAPIWithoutServer:
    """Tests that can run without a live server"""

    def test_api_structure(self):
        """Test that we can import the API module"""
        from api.service import app

        assert app.title == "Cheese API Server"
        assert app.version == "v1"
