"""
Inventory routes for the Book Logistics API.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from app import db
from app.modules.inventory.models import Book, Transaction
from app.modules.user_management.models import User

inventory_bp = Blueprint('inventory', __name__, url_prefix='/api/inventory')

@inventory_bp.route('/books', methods=['GET'])
# Temporariamente removido para testes: @jwt_required()
def get_books():
    """Get all books with optional filtering."""
    # Get query parameters for filtering
    status = request.args.get('status')
    genre = request.args.get('genre')
    section = request.args.get('section')
    
    # Start with base query
    query = Book.query
    
    # Apply filters if provided
    if status:
        query = query.filter(Book.status == status)
    if genre:
        query = query.filter(Book.genre == genre)
    if section:
        query = query.filter(Book.storage_section == section)
    
    # Execute query and return results
    books = query.all()
    return jsonify([book.to_dict() for book in books]), 200

@inventory_bp.route('/books/<int:book_id>', methods=['GET'])
# Temporariamente removido para testes: @jwt_required()
def get_book(book_id):
    """Get a specific book by ID."""
    book = Book.query.get(book_id)
    if not book:
        return jsonify({'error': 'Book not found'}), 404
    
    return jsonify(book.to_dict()), 200

@inventory_bp.route('/books', methods=['POST'])
# Temporariamente removido para testes: @jwt_required()
def add_book():
    """Add a new book to inventory."""
    data = request.get_json()
    
    # Validate required fields
    required_fields = ['title', 'author']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'Missing required field: {field}'}), 400
    
    # Create new book
    book = Book(
        title=data['title'],
        author=data['author'],
        genre=data.get('genre'),
        description=data.get('description'),
        storage_section=data.get('storage_section'),
        image_path=data.get('image_path')
    )
    
    db.session.add(book)
    
    # Create transaction record
    # Temporariamente definido para teste: user_id = 1
    user_id = 1  # Valor fixo para testes (sem JWT)
    transaction = Transaction(
        book_id=book.id,
        user_id=user_id,
        transaction_type='addition',
        to_section=data.get('storage_section'),
        notes=data.get('notes')
    )
    
    db.session.add(transaction)
    db.session.commit()
    
    return jsonify({'message': 'Book added successfully', 'book': book.to_dict()}), 201

@inventory_bp.route('/books/<int:book_id>', methods=['PUT'])
# Temporariamente removido para testes: @jwt_required()
def update_book(book_id):
    """Update a book's information."""
    book = Book.query.get(book_id)
    if not book:
        return jsonify({'error': 'Book not found'}), 404
    
    data = request.get_json()
    # Temporariamente definido para teste: user_id = 1
    user_id = 1  # Valor fixo para testes (sem JWT)
    
    # Track if storage section is changing for transaction record
    old_section = book.storage_section
    new_section = data.get('storage_section')
    section_changed = new_section and old_section != new_section
    
    # Update fields if provided
    if 'title' in data:
        book.title = data['title']
    if 'author' in data:
        book.author = data['author']
    if 'genre' in data:
        book.genre = data['genre']
    if 'description' in data:
        book.description = data['description']
    if 'storage_section' in data:
        book.storage_section = data['storage_section']
    if 'image_path' in data:
        book.image_path = data['image_path']
    if 'status' in data:
        book.status = data['status']
    
    # Create transaction record if section changed
    if section_changed:
        transaction = Transaction(
            book_id=book.id,
            user_id=user_id,
            transaction_type='movement',
            from_section=old_section,
            to_section=new_section,
            notes=data.get('notes')
        )
        db.session.add(transaction)
    
    db.session.commit()
    
    return jsonify({'message': 'Book updated successfully', 'book': book.to_dict()}), 200

@inventory_bp.route('/books/<int:book_id>/sell', methods=['POST'])
# Temporariamente removido para testes: @jwt_required()
def sell_book(book_id):
    """Mark a book as sold and record the transaction."""
    book = Book.query.get(book_id)
    if not book:
        return jsonify({'error': 'Book not found'}), 404
    
    if book.status != 'available':
        return jsonify({'error': f'Book is not available for sale (current status: {book.status})'}), 400
    
    data = request.get_json() or {}
    # Temporariamente definido para teste: user_id = 1
    user_id = 1  # Valor fixo para testes (sem JWT)
    
    # Update book status
    book.status = 'sold'
    
    # Create transaction record
    transaction = Transaction(
        book_id=book.id,
        user_id=user_id,
        transaction_type='sale',
        from_section=book.storage_section,
        notes=data.get('notes')
    )
    
    db.session.add(transaction)
    db.session.commit()
    
    return jsonify({'message': 'Book marked as sold', 'book': book.to_dict()}), 200

@inventory_bp.route('/transactions', methods=['GET'])
# Temporariamente removido para testes: @jwt_required()
def get_transactions():
    """Get transaction history with optional filtering."""
    # Check if admin for full access
    claims = get_jwt()
    user_id = get_jwt_identity()
    is_admin = claims.get('role') == 'admin'
    
    # Get query parameters for filtering
    book_id = request.args.get('book_id', type=int)
    transaction_type = request.args.get('type')
    
    # Start with base query
    query = Transaction.query
    
    # Apply filters if provided
    if book_id:
        query = query.filter(Transaction.book_id == book_id)
    if transaction_type:
        query = query.filter(Transaction.transaction_type == transaction_type)
    
    # Limit to user's own transactions if not admin
    if not is_admin:
        query = query.filter(Transaction.user_id == user_id)
    
    # Order by most recent first
    query = query.order_by(Transaction.created_at.desc())
    
    # Execute query and return results
    transactions = query.all()
    
    # Enhance transaction data with book and user info
    result = []
    for transaction in transactions:
        transaction_dict = transaction.to_dict()
        transaction_dict['book'] = transaction.book.to_dict() if transaction.book else None
        transaction_dict['user'] = {
            'id': transaction.user.id,
            'username': transaction.user.username
        } if transaction.user else None
        result.append(transaction_dict)
    
    return jsonify(result), 200 