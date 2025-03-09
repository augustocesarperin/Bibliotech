"""
Script para adicionar mais livros ao banco de dados.
"""
from app import create_app, db
from app.modules.inventory.models import Book, Transaction
from app.modules.user_management.models import User

app = create_app()

with app.app_context():
    # Obter o usuário admin
    user = User.query.filter_by(username='admin').first()
    if not user:
        print("Erro: Usuário admin não encontrado!")
        exit(1)
    
    # Lista de livros para adicionar
    books_to_add = [
        {
            'title': 'Harry Potter e a Pedra Filosofal',
            'author': 'J.K. Rowling',
            'genre': 'Fantasia',
            'description': 'O primeiro livro da série Harry Potter.',
            'storage_section': 'A2'
        },
        {
            'title': 'Cem Anos de Solidão',
            'author': 'Gabriel García Márquez',
            'genre': 'Realismo Mágico',
            'description': 'A história da família Buendía ao longo de várias gerações.',
            'storage_section': 'B1'
        },
        {
            'title': 'Dom Casmurro',
            'author': 'Machado de Assis',
            'genre': 'Literatura Brasileira',
            'description': 'A história de Bentinho e seu ciúme por Capitu.',
            'storage_section': 'B2'
        },
        {
            'title': '1984',
            'author': 'George Orwell',
            'genre': 'Ficção Distópica',
            'description': 'Um mundo totalitário onde o governo controla tudo.',
            'storage_section': 'C1'
        },
        {
            'title': 'O Pequeno Príncipe',
            'author': 'Antoine de Saint-Exupéry',
            'genre': 'Literatura Infantil',
            'description': 'A jornada de um pequeno príncipe que visita vários planetas.',
            'storage_section': 'C2'
        }
    ]
    
    # Adicionar cada livro
    for book_data in books_to_add:
        # Verificar se o livro já existe
        existing_book = Book.query.filter_by(
            title=book_data['title'], 
            author=book_data['author']
        ).first()
        
        if existing_book:
            print(f"Livro '{book_data['title']}' já existe. Pulando...")
            continue
        
        # Criar o livro
        book = Book(
            title=book_data['title'],
            author=book_data['author'],
            genre=book_data['genre'],
            description=book_data['description'],
            storage_section=book_data['storage_section']
        )
        db.session.add(book)
        db.session.commit()
        
        # Criar transação
        transaction = Transaction(
            book_id=book.id,
            user_id=user.id,
            transaction_type='addition',
            to_section=book_data['storage_section'],
            notes='Livro adicionado via script'
        )
        db.session.add(transaction)
        db.session.commit()
        
        print(f"Livro '{book.title}' adicionado com sucesso! ID: {book.id}")
    
    print("\nTodos os livros foram adicionados com sucesso!") 