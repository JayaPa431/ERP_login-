from flask import Flask, request, jsonify, session
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime, timedelta
from werkzeug.security import generate_password_hash, check_password_hash
import hashlib
from jauth import  Jauth
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_wtf.csrf import CSRFProtect
import time

# Initialize the Flask app and configuration
app = Flask(__name__)
app.secret_key = "YourSecretKey"
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///admin_dashboard.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(minutes=15)  # Session timeout after 15 minutes
session.permanent = True  # Ensure session timeout is enabled
db = SQLAlchemy(app)

# Initialize JAuth for user authentication
jauth = JAuth(app)

# Initialize Flask-Limiter for limiting login attempts
limiter = Limiter(get_remote_address, app=app)

# Initialize CSRF protection
csrf = CSRFProtect(app)

# Database models
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    login_attempts = db.Column(db.Integer, default=0)
    last_attempt_time = db.Column(db.DateTime, nullable=True)

class Request(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(120), nullable=False)
    client_submitted_date = db.Column(db.Date, nullable=False)
    submitted_date = db.Column(db.Date, nullable=True)
    status = db.Column(db.String(20), default="Pending")

class Note(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    request_id = db.Column(db.Integer, db.ForeignKey('request.id'), nullable=False)
    reason = db.Column(db.Text, nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
    admin_name = db.Column(db.String(80), nullable=False)
    admin_id = db.Column(db.String(80), nullable=False)


# Helper functions
def hash_data(data):
    return hashlib.sha256(data.encode()).hexdigest()


@app.route('/register', methods=['POST'])
def register():
    data = request.json
    username = data['username']
    password = data['password']
    
    hashed_password = generate_password_hash(password)
    new_user = User(username=username, password_hash=hashed_password)
    db.session.add(new_user)
    db.session.commit()
    
    return jsonify({"message": "User registered successfully"}), 201


@app.route('/login', methods=['POST'])
@limiter.limit("5 per minute")  # Limit to 5 login attempts per minute per IP
def login():
    data = request.json
    username = hash_data(data['username'])  # Hash the username
    password = data['password']
    user = User.query.filter_by(username=username).first()
    
    if user:
        # Check for max attempts and cooldown period
        if user.login_attempts >= 3 and datetime.now() - user.last_attempt_time < timedelta(minutes=5):
            return jsonify({"error": "Account locked. Try again later."}), 403

        # JAuth handles the password verification and session creation
        if jauth.authenticate(username=username, password=password):
            user.login_attempts = 0
            db.session.commit()
            session['user_id'] = user.id
            return jsonify({"message": "Login successful"}), 200
        else:
            user.login_attempts += 1
            user.last_attempt_time = datetime.now()
            db.session.commit()
            
            time.sleep(2)  # Brute-force delay (2 seconds) after each failed attempt
            return jsonify({"error": "Invalid credentials"}), 401

    return jsonify({"error": "User not found"}), 404


@app.route('/requests', methods=['GET'])
@jauth.requires_auth
def get_requests():
    requests = Request.query.all()
    request_list = [
        {
            "id": req.id,
            "title": req.title,
            "client_submitted_date": req.client_submitted_date,
            "submitted_date": req.submitted_date,
            "status": req.status
        }
        for req in requests
    ]
    return jsonify(request_list), 200


@app.route('/requests/<int:request_id>/accept', methods=['POST'])
@jauth.requires_auth
def accept_request(request_id):
    request_entry = Request.query.get(request_id)
    if not request_entry:
        return jsonify({"error": "Request not found"}), 404
    
    request_entry.status = "Accepted"
    db.session.commit()
    return jsonify({"message": "Request accepted"}), 200


@app.route('/requests/<int:request_id>/reject', methods=['POST'])
@jauth.requires_auth
def reject_request(request_id):
    request_entry = Request.query.get(request_id)
    if not request_entry:
        return jsonify({"error": "Request not found"}), 404
    
    request_entry.status = "Rejected"
    db.session.commit()
    return jsonify({"message": "Request rejected"}), 200


@app.route('/notes', methods=['POST'])
@jauth.requires_auth
def add_note():
    data = request.json
    request_id = data['request_id']
    reason = data['reason']
    admin_name = data['admin_name']
    admin_id = data['admin_id']
    
    new_note = Note(
        request_id=request_id,
        reason=reason,
        admin_name=admin_name,
        admin_id=admin_id
    )
    db.session.add(new_note)
    db.session.commit()
    
    return jsonify({"message": "Note added successfully"}), 201


@app.route('/notes/<int:request_id>', methods=['GET'])
@jauth.requires_auth
def get_notes(request_id):
    notes = Note.query.filter_by(request_id=request_id).all()
    notes_list = [
        {
            "id": note.id,
            "request_id": note.request_id,
            "reason": note.reason,
            "timestamp": note.timestamp,
            "admin_name": note.admin_name,
            "admin_id": note.admin_id
        }
        for note in notes
    ]
    return jsonify(notes_list), 200


if __name__ == '__main__':
    db.create_all()  # Creates tables if they don't exist
    app.run(debug=True)
