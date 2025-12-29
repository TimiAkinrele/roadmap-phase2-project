import os
import time
import psycopg2
from flask import Flask, jsonify, request, send_from_directory

app = Flask(__name__, static_folder = 'static')

def get_db_connection():
    retries = 10
    while retries > 0:
        try:
            conn = psycopg2.connect(
                host=os.environ.get('DB_HOST'),
                database=os.environ.get('DB_NAME'),
                user=os.environ.get('DB_USER'),
                password=os.environ.get('DB_PASSWORD'),
                sslmode='require'
            )
            print("Database connection successful!")
            return conn
        except psycopg2.OperationalError as e:
            print(f"Database connection failed: {e}")
            print("Retrying...")
            retries -=1
            time.sleep(3)
    print("Could not connect to database after retries.")
    return None

def setup_db():
    conn = get_db_connection()
    if conn:
        with conn.cursor() as cur:
            # Run this command once to ensure the table exists
            cur.execute("CREATE TABLE IF NOT EXISTS votes (id SERIAL PRIMARY KEY, choice TEXT NOT NULL);")
        conn.commit()
        conn.close()
        print("Database initialised, 'votes' table checked/created.")
    else:
        print("FATAL: Could not connect to database to initialise.")

@app.route('/')
def index():
    return send_from_directory('static', 'index.html')

@app.route('/api/vote', methods=['POST'])
def vote():
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500
        
        data = request.json
        choice = data.get('choice') # 'devops' or 'ai'
        
        with conn.cursor() as cur:
            cur.execute("INSERT INTO votes (choice) VALUES (%s);", (choice,))
        conn.commit()
        conn.close()
        
        return jsonify({"message": f"Vote for {choice} recorded!"})

@app.route('/api/results')
def results():
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "Database connection failed"}), 500
            
        with conn.cursor() as cur:
            cur.execute("SELECT choice, COUNT(id) FROM votes GROUP BY choice;")
            res = cur.fetchall()
            
        conn.close()
        # Convert list of tuples [('ai', 5), ('devops', 3)] to a dict
        results_dict = dict(res)
        return jsonify(results_dict)

if __name__ == "__main__":
        setup_db()
        app.run(host='0.0.0.0', port=5000)