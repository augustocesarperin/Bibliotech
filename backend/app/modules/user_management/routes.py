"""
User management routes for the Book Logistics API.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token, 
    jwt_required, 
    get_jwt_identity,
    get_jwt
)
from app import db
from app.modules.user_management.models import User

user_bp = Blueprint('user', __name__, url_prefix='/api/users')

@user_bp.route('/register', methods=['POST'])
def register():
    """Register a new user."""
    data = request.get_json()
    
    # Validate required fields
    required_fields = ['username', 'email', 'password']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'Missing required field: {field}'}), 400
    
    # Check if user already exists
    if User.query.filter_by(username=data['username']).first():
        return jsonify({'error': 'Username already exists'}), 409
    
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': 'Email already exists'}), 409
    
    # Create new user
    role = data.get('role', 'employee')
    # Only allow admin creation if no users exist yet (first user)
    if role == 'admin' and User.query.count() > 0:
        # Check if request is from an admin
        auth_header = request.headers.get('Authorization')
        if not auth_header or 'Bearer' not in auth_header:
            return jsonify({'error': 'Admin privileges required'}), 403
        
        # Further admin validation would happen here
    
    user = User(
        username=data['username'],
        email=data['email'],
        password=data['password'],
        role=role
    )
    
    db.session.add(user)
    db.session.commit()
    
    return jsonify({'message': 'User registered successfully', 'user': user.to_dict()}), 201

@user_bp.route('/login', methods=['POST'])
def login():
    """Authenticate a user and return a JWT token."""
    data = request.get_json()
    
    # Validate required fields
    if not data.get('username') or not data.get('password'):
        return jsonify({'error': 'Username and password are required'}), 400
    
    # Find user by username
    user = User.query.filter_by(username=data['username']).first()
    
    # Verify user and password
    if not user or not user.check_password(data['password']):
        return jsonify({'error': 'Invalid username or password'}), 401
    
    # Create access token
    access_token = create_access_token(
        identity=user.id,
        additional_claims={'role': user.role}
    )
    
    return jsonify({
        'access_token': access_token,
        'user': user.to_dict()
    }), 200

@user_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    """Get the current user's profile."""
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    return jsonify(user.to_dict()), 200

@user_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    """Update the current user's profile."""
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    data = request.get_json()
    
    # Update fields if provided
    if 'email' in data:
        # Check if email is already taken by another user
        existing_user = User.query.filter_by(email=data['email']).first()
        if existing_user and existing_user.id != user.id:
            return jsonify({'error': 'Email already exists'}), 409
        user.email = data['email']
    
    if 'password' in data:
        user.password_hash = generate_password_hash(data['password'])
    
    db.session.commit()
    
    return jsonify({'message': 'Profile updated successfully', 'user': user.to_dict()}), 200

@user_bp.route('/', methods=['GET'])
@jwt_required()
def get_users():
    """Get all users (admin only)."""
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin privileges required'}), 403
    
    users = User.query.all()
    return jsonify([user.to_dict() for user in users]), 200

@user_bp.route('/<int:user_id>', methods=['GET'])
@jwt_required()
def get_user(user_id):
    """Get a specific user (admin only or self)."""
    current_user_id = get_jwt_identity()
    claims = get_jwt()
    
    # Allow access if admin or if user is requesting their own info
    if claims.get('role') != 'admin' and current_user_id != user_id:
        return jsonify({'error': 'Unauthorized access'}), 403
    
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    return jsonify(user.to_dict()), 200

@user_bp.route('/<int:user_id>', methods=['DELETE'])
@jwt_required()
def delete_user(user_id):
    """Delete a user (admin only)."""
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'error': 'Admin privileges required'}), 403
    
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    db.session.delete(user)
    db.session.commit()
    
    return jsonify({'message': 'User deleted successfully'}), 200 