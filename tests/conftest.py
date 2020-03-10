import requests
from requests.auth import HTTPBasicAuth

import pytest


@pytest.fixture
def api_url():
    return lambda x: f"http://app:3000/api/{x}"


@pytest.fixture
def session():
    s = requests.Session()
    s.auth = HTTPBasicAuth("dev", "dev")
    return s
