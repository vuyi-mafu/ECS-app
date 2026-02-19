from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'}), 200

@app.route('/')
def index():
    return jsonify({'message': 'Hello from ECS!'})

if __name__ == '__main__':
    # CRITICAL: Must be 0.0.0.0 for ECS to work!
    app.run(host='0.0.0.0', port=80)