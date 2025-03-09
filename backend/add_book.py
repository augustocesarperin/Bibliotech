"""
Script para adicionar um livro ao banco de dados diretamente.
"""
from app import create_app, db
from app.modules.inventory.models import Book, Transaction
from app.modules.user_management.models import User

app = create_app()

with app.app_context():
    # Verificar se já existe um usuário de teste
    user = User.query.filter_by(username='admin').first()
    if not user:
        # Criar um usuário de teste
        user = User(
            username='admin',
            email='admin@example.com',
            password='admin123',
            role='admin'
        )
        db.session.add(user)
        db.session.commit()
        print("Usuário de teste criado com sucesso!")
    
    # Adicionar um livro
    book = Book(
        title='O Senhor dos Anéis',
        author='J.R.R. Tolkien',
        genre='Fantasia',
        description='Uma história épica sobre a jornada de Frodo para destruir o Um Anel.',
        storage_section='A1'
    )
    db.session.add(book)
    db.session.commit()
    
    # Adicionar um registro de transação
    transaction = Transaction(
        book_id=book.id,
        user_id=user.id,
        transaction_type='addition',
        to_section='A1',
        notes='Livro adicionado via script'
    )
    db.session.add(transaction)
    db.session.commit()
    
    print(f"Livro '{book.title}' adicionado com sucesso!")
    print(f"ID do livro: {book.id}") 