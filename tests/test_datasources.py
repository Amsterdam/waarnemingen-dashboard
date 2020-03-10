import pytest


class TestDatasources:
    @pytest.mark.parametrize(
        "datasource",
        [
            {"name": "mensen"},
            {"name": "voertuigen"},
            {"name": "boten"},
        ],
    )
    def test_datasource(self, session, api_url, datasource):
        response = session.get(api_url("datasources"), timeout=1)
        response.raise_for_status()
        assert response
        data = response.json()

        match = next((x for x in data if x["name"] == datasource["name"]))
        assert match["name"] == datasource["name"]
        assert match["type"] == 'postgres'
        assert match["database"] == datasource["name"]
        assert match["password"] == ""
        assert match["jsonData"] == ""
        assert match["access"] == 'proxy'
