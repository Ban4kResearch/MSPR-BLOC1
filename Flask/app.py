from flask import Flask, request, jsonify, render_template
import os
import json
import requests

app = Flask(__name__)

UPLOAD_DIRECTORY = os.path.join(os.path.dirname(__file__), 'static')

if not os.path.exists(UPLOAD_DIRECTORY):
    os.makedirs(UPLOAD_DIRECTORY)

def check_server_status(url):
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise an HTTPError for bad responses
        return "Online" if response.status_code // 100 == 2 else f"échec (Code HTTP : {response.status_code})"
    except requests.RequestException as e:
        return f"Failed to connect to {url}: {str(e)}"

@app.route('/get-status', methods=['GET'])
def get_status():
    url1 = "http://192.168.1.133:9998"
    url2 = "http://192.168.1.133:5000"

    status1 = check_server_status(url1)
    status2 = check_server_status(url2)

    return jsonify({'server_status1': status1, 'server_status2': status2})

@app.route('/receive-file', methods=['POST'])
def receive_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    if file:
        filename = file.filename
        file.save(os.path.join(UPLOAD_DIRECTORY, filename))
        with open(os.path.join(UPLOAD_DIRECTORY, filename), 'r') as json_file:
            data = json.load(json_file)
            # Do something with the data, like storing it in a database
        return jsonify({'message': 'File successfully received'}), 200

@app.route('/')
def home():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=9999)
