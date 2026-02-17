import os
import psycopg2
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse

app = FastAPI()

def get_write_conn():
    return psycopg2.connect(
        host=os.getenv("POSTGRES_WRITE_HOST"),
        port=os.getenv("POSTGRES_PORT", 5432),
        dbname=os.getenv("POSTGRES_DB"),
        user=os.getenv("POSTGRES_USER"),
        password=os.getenv("POSTGRES_PASSWORD"),
    )

def get_read_conn():
    return psycopg2.connect(
        host=os.getenv("POSTGRES_READ_HOST"),
        port=os.getenv("POSTGRES_PORT", 5432),
        dbname=os.getenv("POSTGRES_DB"),
        user=os.getenv("POSTGRES_USER"),
        password=os.getenv("POSTGRES_PASSWORD"),
    )


def init_table():
    conn = get_write_conn()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS items (
            id SERIAL PRIMARY KEY,
            item TEXT NOT NULL
        );
    """)
    conn.commit()
    cur.close()
    conn.close()

@app.get("/", response_class=HTMLResponse)
def ui():
    with open("index.html") as f:
        return f.read()

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/items")
async def create_item(request: Request):
    init_table()
    body = await request.json()
    conn = get_write_conn()
    cur = conn.cursor()
    cur.execute("INSERT INTO items (item) VALUES (%s);", (body["item"],))
    conn.commit()
    cur.close()
    conn.close()
    return {"message": "created"}

@app.get("/items")
def list_items():
    init_table()
    conn = get_read_conn()
    cur = conn.cursor()
    cur.execute("SELECT id, item FROM items;")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [{"id": r[0], "item": r[1]} for r in rows]

@app.delete("/items/{item_id}")
def delete_item(item_id: int):
    conn = get_write_conn()
    cur = conn.cursor()
    cur.execute("DELETE FROM items WHERE id=%s;", (item_id,))
    conn.commit()
    cur.close()
    conn.close()
    return {"message": "deleted"}
