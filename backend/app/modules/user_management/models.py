"""
User management models for the Book Logistics API.
"""
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
from app import db

class User(db.Model):
    """User model for authentication and authorization."""
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    role = db.Column(db.String(20), nullable=False, default='employee')  # 'admin' or 'employee'
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __init__(self, username, email, password, role='employee'):
        self.username = username
        self.email = email
        self.password_hash = generate_password_hash(password)
        self.role = role
    
    def check_password(self, password):
        """Verify the password against the stored hash."""
        return check_password_hash(self.password_hash, password)
    
    def is_admin(self):
        """Check if the user has admin privileges."""
        return self.role == 'admin'
    
    def to_dict(self):
        """Convert user object to dictionary for API responses."""
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'role': self.role,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
    
    def __repr__(self):
        return f'<User {self.username}>' 