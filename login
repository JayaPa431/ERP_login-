from flask import Flask, render_template, redirect, url_for, flash, request, session
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired, Length, Email
from flask_bcrypt import Bcrypt
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from flask_limiter import Limiter
from datetime import timedelta
import time

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your_secret_key'
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(minutes=15)  # Session timeout

# Initialize Extensions
bcrypt = Bcrypt(app)
login_manager = LoginManager(app)
login_manager.login_view = 'login'
limiter = Limiter(app, key_func=lambda: request.remote_addr)

# Dummy User Database
users = {
    "admin@erp.com": bcrypt.generate_password_hash("password123").decode('utf-8')
}

# User class
class User(UserMixin):
    def __init__(self, id, email):
        self.id = id
        self.email = email

# Load user function
@login_manager.user_loader
def load_user(user_id):
    for idx, email in enumerate(users.keys()):
        if str(idx) == user_id:
            return User(id=user_id, email=email)
    return None

# LoginForm class
class LoginForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired(), Length(min=6)])
    submit = SubmitField('Login')

# Routes
@app.route('/login', methods=['GET', 'POST'])
@limiter.limit("5 per minute")  # Limit login attempts to prevent brute-force attacks
def login():
    form = LoginForm()
    if form.validate_on_submit():
        email = form.email.data
        password = form.password.data

        if email in users and bcrypt.check_password_hash(users[email], password):
            user = User(id=str(list(users.keys()).index(email)), email=email)
            login_user(user)
            session.permanent = True  # Enable session timeout
            flash('Login successful', 'success')
            return redirect(url_for('dashboard'))
        else:
            time.sleep(2)  # Delay to mitigate brute-force attempts
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

if __name__ == '__main__':
    app.run(debug=True)
