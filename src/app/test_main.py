# test_main.py

import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock

from main import app

client = TestClient(app)


# ---- Fixtures ---- #

@pytest.fixture
def mock_db():
    with patch("main.psycopg2.connect") as mock_connect:
        mock_conn = MagicMock()
        mock_cursor = MagicMock()

        mock_connect.return_value = mock_conn
        mock_conn.cursor.return_value = mock_cursor

        # default fetch result
        mock_cursor.fetchall.return_value = [(1, "test item")]

        yield mock_cursor


# ---- Tests ---- #

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_create_item(mock_db):
    response = client.post("/items", json={"item": "apple"})
    assert response.status_code == 200
    assert response.json() == {"message": "created"}

    mock_db.execute.assert_any_call(
        "INSERT INTO items (item) VALUES (%s);",
        ("apple",)
    )


def test_list_items(mock_db):
    response = client.get("/items")
    assert response.status_code == 200
    assert response.json() == [{"id": 1, "item": "test item"}]


def test_delete_item(mock_db):
    response = client.delete("/items/1")
    assert response.status_code == 200
    assert response.json() == {"message": "deleted"}

    mock_db.execute.assert_any_call(
        "DELETE FROM items WHERE id=%s;",
        (1,)
    )
