"""
Rotas do módulo de logística para a API de Logística de Livros.
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from app import db
from app.modules.inventory.models import Book, Transaction
from app.modules.user_management.models import User

logistics_bp = Blueprint('logistics', __name__, url_prefix='/api/logistics')

@logistics_bp.route('/sections', methods=['GET'])
@jwt_required()
def listar_secoes():
    """Listar todas as seções de armazenamento disponíveis."""
    # Esta é uma implementação simulada - em um sistema real, isso viria de um banco de dados
    secoes_disponiveis = [
        {'id': 'FICT-A1', 'name': 'Ficção - Estante A1', 'capacity': 100},
        {'id': 'FICT-A2', 'name': 'Ficção - Estante A2', 'capacity': 100},
        {'id': 'FICT-B1', 'name': 'Ficção - Estante B1', 'capacity': 150},
        {'id': 'NFICT-C1', 'name': 'Não-Ficção - Estante C1', 'capacity': 120},
        {'id': 'NFICT-C2', 'name': 'Não-Ficção - Estante C2', 'capacity': 120},
        {'id': 'INFAN-D1', 'name': 'Infantil - Estante D1', 'capacity': 80},
        {'id': 'ACAD-E1', 'name': 'Acadêmico - Estante E1', 'capacity': 150},
        {'id': 'ACAD-E2', 'name': 'Acadêmico - Estante E2', 'capacity': 150},
    ]
    
    return jsonify(secoes_disponiveis), 200

@logistics_bp.route('/sections/<section_id>/books', methods=['GET'])
@jwt_required()
def buscar_livros_por_secao(section_id):
    """Buscar todos os livros em uma determinada seção."""
    livros_na_secao = Book.query.filter_by(storage_section=section_id, status='available').all()
    return jsonify([livro.to_dict() for livro in livros_na_secao]), 200

@logistics_bp.route('/sections/stats', methods=['GET'])
@jwt_required()
def estatisticas_secoes():
    """Obter estatísticas de ocupação de cada seção."""
    # Verificar se o usuário tem privilégios de administrador
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'erro': 'Privilégios de administrador necessários'}), 403
    
    # Lista de todas as seções (normalmente viria do banco de dados)
    secoes_cadastradas = [
        'FICT-A1', 'FICT-A2', 'FICT-B1', 
        'NFICT-C1', 'NFICT-C2', 
        'INFAN-D1', 
        'ACAD-E1', 'ACAD-E2'
    ]
    
    resultado = []
    
    for secao in secoes_cadastradas:
        # Contar livros disponíveis na seção
        qtd_disponiveis = Book.query.filter_by(storage_section=secao, status='available').count()
        
        # Contar livros vendidos que estavam nesta seção
        qtd_vendidos = db.session.query(Transaction).join(Book).\
            filter(Transaction.transaction_type == 'sale', 
                  Transaction.from_section == secao).count()
        
        # Adicionar estatísticas à lista de resultados
        resultado.append({
            'secao': secao,
            'livros_disponiveis': qtd_disponiveis,
            'livros_vendidos': qtd_vendidos,
            'total_movimentacoes': qtd_disponiveis + qtd_vendidos
        })
    
    return jsonify(resultado), 200

@logistics_bp.route('/recommendations', methods=['GET'])
@jwt_required()
def recomendar_estoque():
    """Recomendar seções para reabastecimento de estoque."""
    # Verificar se o usuário tem privilégios de administrador
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'erro': 'Privilégios de administrador necessários'}), 403
    
    # Este é um exemplo de lógica de recomendação - em um sistema real seria mais complexo
    # e baseado em análise de dados de vendas, tendências, etc.
    
    # Contar livros por seção
    contagem_secoes = {}
    secoes_conhecidas = [
        'FICT-A1', 'FICT-A2', 'FICT-B1', 
        'NFICT-C1', 'NFICT-C2', 
        'INFAN-D1', 
        'ACAD-E1', 'ACAD-E2'
    ]
    
    for secao in secoes_conhecidas:
        contagem_secoes[secao] = Book.query.filter_by(storage_section=secao, status='available').count()
    
    # Encontrar seções com poucos livros (menos de 10) para recomendar reabastecimento
    recomendacoes = []
    for secao, qtd in contagem_secoes.items():
        if qtd < 10:  # Limiar para considerar estoque baixo
            # Verificar quais gêneros são populares nesta seção
            livros_da_secao = Book.query.filter_by(storage_section=secao).all()
            generos = {}
            
            for livro in livros_da_secao:
                if livro.genre:
                    generos[livro.genre] = generos.get(livro.genre, 0) + 1
            
            # Ordenar gêneros por popularidade
            generos_ordenados = sorted(generos.items(), key=lambda x: x[1], reverse=True)
            generos_populares = [g[0] for g in generos_ordenados[:3]] if generos_ordenados else []
            
            recomendacoes.append({
                'secao': secao,
                'qtd_atual': qtd,
                'status': 'CRÍTICO' if qtd < 5 else 'BAIXO',
                'generos_recomendados': generos_populares
            })
    
    return jsonify(recomendacoes), 200

@logistics_bp.route('/move', methods=['POST'])
@jwt_required()
def mover_livro():
    """Mover um livro de uma seção para outra."""
    user_id = get_jwt_identity()
    dados = request.get_json()
    
    # Validar campos obrigatórios
    campos_obrigatorios = ['book_id', 'to_section']
    for campo in campos_obrigatorios:
        if campo not in dados:
            return jsonify({'erro': f'Campo obrigatório ausente: {campo}'}), 400
    
    # Buscar o livro
    livro = Book.query.get(dados['book_id'])
    if not livro:
        return jsonify({'erro': 'Livro não encontrado'}), 404
    
    if livro.status != 'available':
        return jsonify({'erro': f'Livro não está disponível para movimentação (status atual: {livro.status})'}), 400
    
    # Registrar a seção antiga
    secao_antiga = livro.storage_section
    
    # Atualizar a seção do livro
    livro.storage_section = dados['to_section']
    
    # Criar registro de transação
    transacao = Transaction(
        book_id=livro.id,
        user_id=user_id,
        transaction_type='movement',
        from_section=secao_antiga,
        to_section=dados['to_section'],
        notes=dados.get('notes')
    )
    
    db.session.add(transacao)
    db.session.commit()
    
    return jsonify({
        'mensagem': 'Livro movido com sucesso',
        'livro': livro.to_dict(),
        'de_secao': secao_antiga,
        'para_secao': dados['to_section']
    }), 200 