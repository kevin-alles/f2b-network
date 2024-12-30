from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime, timedelta
import logging
import ipaddress
import os
from config import Config

app = Flask(__name__)
app.config.from_object(Config)
db = SQLAlchemy(app)

DEFAULT_TIMEZONE = Config.DEFAULT_TIMEZONE
DEFAULT_EXPIRY = Config.DEFAULT_EXPIRY
API_KEY = Config.API_KEY

# Ensure the log directory and file exist
log_dir = os.path.dirname(Config.LOG_FILE)
if not os.path.exists(log_dir):
    os.makedirs(log_dir)

# Configure logging
logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s %(levelname)s %(message)s',
                    handlers=[logging.FileHandler(Config.LOG_FILE), logging.StreamHandler()])

# Define the BlockedIP model to store blocked IP addresses with expiration time
class BlockedIP(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    ip = db.Column(db.String(45), nullable=False, unique=True)
    added_at = db.Column(db.DateTime, default=datetime.now(tz=DEFAULT_TIMEZONE))
    expires_at = db.Column(db.DateTime, nullable=True)

# Create the database tables within the application context
with app.app_context():
    db.create_all()

# Validate IP address
def is_valid_ip(ip):
    try:
        ipaddress.ip_address(ip)
        return True
    except ValueError:
        return False

# Authenticate requests using the API key
@app.before_request
def authenticate():
    logging.info(f"Request from IP: {request.remote_addr} with API Key: {request.headers.get('Authorization')}")
    if request.headers.get("Authorization") != f"Bearer {API_KEY}":
        return jsonify({"error": "Unauthorized"}), 401

# POST endpoint to add an IP to the blocklist
@app.route('/blocklist', methods=['POST'])
def add_ip():
    logging.info(f"Blocklist request from {request.remote_addr} with data: {request.json}")
    data = request.json
    ip = data.get('ip')
    if not ip or not is_valid_ip(ip):
        return jsonify({'error': 'Invalid or no IP provided'}), 400

    # Check if the IP is already in the blocklist
    existing_ip = BlockedIP.query.filter_by(ip=ip).first()
    if existing_ip:
        return jsonify({'message': 'IP is already in the blocklist'}), 200

    expires_in = data.get('expires_in', DEFAULT_EXPIRY)
    expires_at = datetime.now(tz=DEFAULT_TIMEZONE) + timedelta(seconds=expires_in)
    blocked_ip = BlockedIP(ip=ip, expires_at=expires_at)
    try:
        db.session.add(blocked_ip)
        db.session.commit()
        logging.info(f"Added IP {ip} to blocklist")
    except Exception as e:
        db.session.rollback()
        logging.error(f"Error adding IP {ip} to blocklist: {str(e)}")
        return jsonify({'error': str(e)}), 500
    return jsonify({'message': 'IP added to blocklist'}), 201

# GET endpoint to retrieve the active blocklist
@app.route('/blocklist', methods=['GET'])
def get_blocklist():
    logging.info(f"Blocklist requested by {request.remote_addr}")
    now = datetime.now(tz=DEFAULT_TIMEZONE)
    blocklist = BlockedIP.query.filter((BlockedIP.expires_at == None) | (BlockedIP.expires_at > now)).all()
    return jsonify([{'ip': ip.ip, 'added_at': ip.added_at, 'expires_at': ip.expires_at} for ip in blocklist]), 200

if __name__ == '__main__':
    app.run(host=Config.SERVER_IP, port=Config.SERVER_PORT, debug=True)