"""
Main Flask application initialization for the Book Logistics API.
"""
import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS

# Initialize extensions
db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()

def create_app(test_config=None):
    """
    Application factory function that creates and configures the Flask app.
    
    Args:
        test_config: Configuration dictionary for testing environments
        
    Returns:
        Configured Flask application
    """
    app = Flask(__name__, instance_relative_config=True)
    
    # Default configuration
    app.config.from_mapping(
        SECRET_KEY=os.environ.get('SECRET_KEY', 'dev_key_not_for_production'),
        SQLALCHEMY_DATABASE_URI=os.environ.get('DATABASE_URL', 'sqlite:///book_logistics.db'),
        SQLALCHEMY_TRACK_MODIFICATIONS=False,
        JWT_SECRET_KEY=os.environ.get('JWT_SECRET_KEY', 'jwt_dev_key_not_for_production'),
    )
    
    # Override config with test config if provided
    if test_config:
        app.config.update(test_config)
    
    # Initialize extensions with app
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    CORS(app)
    
    # Create instance folder
    try:
        os.makedirs(app.instance_path)
    except OSError:
        pass
    
    # Importar e registrar blueprints
    from app.modules.inventory.routes import inventory_bp
    app.register_blueprint(inventory_bp)
    
    # Mantendo as rotas temporárias até que todos os blueprints estejam prontos
    @app.route('/health')
    def health_check():
        """Health check endpoint"""
        return {'status': 'healthy'}
    
    @app.route('/api/users/register', methods=['POST'])
    def register_user():
        """Endpoint temporário para testar o registro"""
        return {
            'message': 'User registered successfully (test endpoint)',
            'user': {
                'id': 1,
                'username': 'test_user',
                'email': 'test@example.com',
                'role': 'admin'
            }
        }, 201
    
    @app.route('/api/users/login', methods=['POST'])
    def login_user():
        """Endpoint temporário para testar o login"""
        return {
            'message': 'Login successful (test endpoint)',
            'access_token': 'fake_jwt_token_for_testing',
            'user': {
                'id': 1,
                'username': 'test_user',
                'email': 'test@example.com',
                'role': 'admin'
            }
        }, 200
        
    return app
