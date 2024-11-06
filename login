from flask import Flask, render_template, redirect, url_for, flash, request, jsonify, session
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired, Length, Email
from flask_bcrypt import Bcrypt
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from datetime import datetime, timedelta
from werkzeug.security import generate_password_hash, check_password_hash
import hashlib
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_sqlalchemy import SQLAlchemy
from flask_wtf.csrf import CSRFProtect
import time

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your_secret_key'
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///admin_dashboard.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(minutes=15)  # Session timeout after 15 minutes
app.session.permanent = True  # Ensure session timeout is enabled
db = SQLAlchemy(app)

bcrypt = Bcrypt(app)
login_manager = LoginManager(app)
login_manager.login_view = 'login'

# Initialize Flask-Limiter for limiting login attempts
limiter = Limiter(get_remote_address, app=app)

# Initialize CSRF protection
csrf = CSRFProtect(app)

# Dummy User Database with additional login attempt tracking
users = {
    "admin@erp.com": {"password": bcrypt.generate_password_hash("password123").decode('utf-8'), "login_attempts": 0, "last_attempt_time": None}
}

# User model for login
class User(UserMixin):
    def __init__(self, id, email):
        self.id = id
        self.email = email

@login_manager.user_loader
def load_user(user_id):
    for idx, email in enumerate(users.keys()):
        if str(idx) == user_id:
            return User(id=user_id, email=email)
    return None

# Helper functions
def hash_data(data):
    return hashlib.sha256(data.encode()).hexdigest()

# Forms
class LoginForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired(), Length(min=6)])
    submit = SubmitField('Login')

# Routes
@app.route('/login', methods=['GET', 'POST'])
@limiter.limit("5 per minute")  # Limit to 5 login attempts per minute per IP
def login():
    form = LoginForm()
    if form.validate_on_submit():
        email = form.email.data
        password = form.password.data
        
        # Handle login attempt tracking and lockout
        user = users.get(email)
        if user:
            # Check if account is locked due to too many failed attempts
            if user['login_attempts'] >= 3 and datetime.now() - user['last_attempt_time'] < timedelta(minutes=5):
                flash("Account locked. Try again later.", 'danger')
                return redirect(url_for('login'))
            
            # Check password
            if bcrypt.check_password_hash(user['password'], password):
                # Successful login, reset attempts and create session
                user['login_attempts'] = 0
                user['last_attempt_time'] = None
                user_obj = User(id=str(list(users.keys()).index(email)), email=email)
                login_user(user_obj)
                flash('Login successful', 'success')
                return redirect(url_for('dashboard'))
            else:
                # Failed login attempt
                user['login_attempts'] += 1
                user['last_attempt_time'] = datetime.now()
                db.session.commit()
                flash('Login failed. Check your credentials.', 'danger')
                time.sleep(2)  # Delay after failed attempt (Brute force protection)
        else:
            flash('Login failed. Check your credentials.', 'danger')

    return render_template('login.html', form=form)

@app.route('/logout')
@login_required
def logout():
    logout_user()
    flash('You have been logged out.', 'info')
    return redirect(url_for('login'))

@app.route('/dashboard')
@login_required
def dashboard():
    return render_template('dashboard.html', email=current_user.email)

# Define database models for requests and notes (same as in the first code)
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

# Add request and note routes (as in the first code)...
# Add additional routes and logic for your app...

if __name__ == '__main__':
    db.create_all()  # Creates tables if they don't exist
    app.run(debug=True)
