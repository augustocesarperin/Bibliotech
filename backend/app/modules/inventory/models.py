"""
Inventory models for the Book Logistics API.
"""
from datetime import datetime
from app import db

class Book(db.Model):
    """Book model for inventory management."""
    __tablename__ = 'books'
    
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    author = db.Column(db.String(255), nullable=False)
    genre = db.Column(db.String(100), nullable=True)
    description = db.Column(db.Text, nullable=True)
    storage_section = db.Column(db.String(50), nullable=True)
    image_path = db.Column(db.String(255), nullable=True)
    status = db.Column(db.String(20), default='available')  # available, sold, reserved
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __init__(self, title, author, genre=None, description=None, storage_section=None, image_path=None):
        self.title = title
        self.author = author
        self.genre = genre
        self.description = description
        self.storage_section = storage_section
        self.image_path = image_path
        self.status = 'available'
    
    def to_dict(self):
        """Convert book object to dictionary for API responses."""
        return {
            'id': self.id,
            'title': self.title,
            'author': self.author,
            'genre': self.genre,
            'description': self.description,
            'storage_section': self.storage_section,
            'image_path': self.image_path,
            'status': self.status,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
    
    def __repr__(self):
        return f'<Book {self.title} by {self.author}>'

class Transaction(db.Model):
    """Transaction model for tracking book sales and movements."""
    __tablename__ = 'transactions'
    
    id = db.Column(db.Integer, primary_key=True)
    book_id = db.Column(db.Integer, db.ForeignKey('books.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    transaction_type = db.Column(db.String(20), nullable=False)  # sale, addition, movement
    from_section = db.Column(db.String(50), nullable=True)
    to_section = db.Column(db.String(50), nullable=True)
    notes = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    book = db.relationship('Book', backref=db.backref('transactions', lazy=True))
    user = db.relationship('User', backref=db.backref('transactions', lazy=True))
    
    def __init__(self, book_id, user_id, transaction_type, from_section=None, to_section=None, notes=None):
        self.book_id = book_id
        self.user_id = user_id
        self.transaction_type = transaction_type
        self.from_section = from_section
        self.to_section = to_section
        self.notes = notes
    
    def to_dict(self):
        """Convert transaction object to dictionary for API responses."""
        return {
            'id': self.id,
            'book_id': self.book_id,
            'user_id': self.user_id,
            'transaction_type': self.transaction_type,
            'from_section': self.from_section,
            'to_section': self.to_section,
            'notes': self.notes,
            'created_at': self.created_at.isoformat()
        }
    
    def __repr__(self):
        return f'<Transaction {self.id} - {self.transaction_type}>' 