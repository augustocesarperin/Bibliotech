"""
Rotas do módulo de relatórios para a API de Logística de Livros.
"""
from datetime import datetime, timedelta
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from sqlalchemy import func, desc
from app import db
from app.modules.inventory.models import Book, Transaction
from app.modules.user_management.models import User

reporting_bp = Blueprint('reporting', __name__, url_prefix='/api/reports')

@reporting_bp.route('/inventario', methods=['GET'])
@jwt_required()
def relatorio_inventario():
    """Gerar relatório de inventário com filtros opcionais."""
    # Verificar se o usuário tem privilégios de administrador
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'erro': 'Privilégios de administrador necessários'}), 403
    
    # Obter parâmetros de filtro
    status = request.args.get('status')
    genero = request.args.get('genre')
    secao = request.args.get('section')
    
    # Iniciar com consulta base
    consulta = Book.query
    
    # Aplicar filtros se fornecidos
    if status:
        consulta = consulta.filter(Book.status == status)
    if genero:
        consulta = consulta.filter(Book.genre == genero)
    if secao:
        consulta = consulta.filter(Book.storage_section == secao)
    
    # Executar consulta
    livros = consulta.all()
    
    # Preparar dados do relatório
    dados_relatorio = {
        'total_livros': len(livros),
        'data_geracao': datetime.utcnow().isoformat(),
        'filtros_aplicados': {
            'status': status,
            'genero': genero,
            'secao': secao
        },
        'livros': [livro.to_dict() for livro in livros]
    }
    
    # Adicionar estatísticas adicionais
    if livros:
        # Contagem por status
        contagem_status = {}
        for livro in livros:
            contagem_status[livro.status] = contagem_status.get(livro.status, 0) + 1
        
        # Contagem por gênero
        contagem_genero = {}
        for livro in livros:
            if livro.genre:
                contagem_genero[livro.genre] = contagem_genero.get(livro.genre, 0) + 1
        
        # Contagem por seção
        contagem_secao = {}
        for livro in livros:
            if livro.storage_section:
                contagem_secao[livro.storage_section] = contagem_secao.get(livro.storage_section, 0) + 1
        
        # Adicionar contagens ao relatório
        dados_relatorio['estatisticas'] = {
            'por_status': contagem_status,
            'por_genero': contagem_genero,
            'por_secao': contagem_secao
        }
    
    return jsonify(dados_relatorio), 200

@reporting_bp.route('/vendas', methods=['GET'])
@jwt_required()
def relatorio_vendas():
    """Gerar relatório de vendas com filtros de data opcionais."""
    # Verificar se o usuário tem privilégios de administrador
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'erro': 'Privilégios de administrador necessários'}), 403
    
    # Obter parâmetros de data
    data_inicio_str = request.args.get('data_inicio')
    data_fim_str = request.args.get('data_fim')
    
    # Converter strings para objetos datetime
    try:
        if data_inicio_str:
            data_inicio = datetime.fromisoformat(data_inicio_str.replace('Z', '+00:00'))
        else:
            # Padrão: último mês
            data_inicio = datetime.utcnow() - timedelta(days=30)
        
        if data_fim_str:
            data_fim = datetime.fromisoformat(data_fim_str.replace('Z', '+00:00'))
        else:
            data_fim = datetime.utcnow()
    except ValueError:
        return jsonify({'erro': 'Formato de data inválido. Use ISO 8601 (ex: 2023-01-31T12:00:00Z)'}), 400
    
    # Buscar transações de venda no período
    vendas = Transaction.query.filter(
        Transaction.transaction_type == 'sale',
        Transaction.created_at >= data_inicio,
        Transaction.created_at <= data_fim
    ).order_by(Transaction.created_at.desc()).all()
    
    # Preparar dados do relatório
    dados_relatorio = {
        'periodo': {
            'inicio': data_inicio.isoformat(),
            'fim': data_fim.isoformat()
        },
        'total_vendas': len(vendas),
        'data_geracao': datetime.utcnow().isoformat(),
        'vendas': []
    }
    
    # Adicionar detalhes de cada venda
    for venda in vendas:
        livro = Book.query.get(venda.book_id)
        usuario = User.query.get(venda.user_id)
        
        item_venda = {
            'id_transacao': venda.id,
            'data_venda': venda.created_at.isoformat(),
            'livro': livro.to_dict() if livro else {'id': venda.book_id, 'info': 'Livro não encontrado'},
            'vendedor': {
                'id': usuario.id,
                'nome': usuario.username
            } if usuario else {'id': venda.user_id, 'info': 'Usuário não encontrado'},
            'secao_origem': venda.from_section,
            'observacoes': venda.notes
        }
        
        dados_relatorio['vendas'].append(item_venda)
    
    # Adicionar estatísticas de vendas por dia
    vendas_por_dia = {}
    for venda in vendas:
        data_str = venda.created_at.date().isoformat()
        vendas_por_dia[data_str] = vendas_por_dia.get(data_str, 0) + 1
    
    dados_relatorio['estatisticas'] = {
        'vendas_por_dia': vendas_por_dia
    }
    
    return jsonify(dados_relatorio), 200

@reporting_bp.route('/desempenho', methods=['GET'])
@jwt_required()
def relatorio_desempenho():
    """Gerar relatório de desempenho de vendas por funcionário."""
    # Verificar se o usuário tem privilégios de administrador
    claims = get_jwt()
    if claims.get('role') != 'admin':
        return jsonify({'erro': 'Privilégios de administrador necessários'}), 403
    
    # Obter parâmetros de data
    data_inicio_str = request.args.get('data_inicio')
    data_fim_str = request.args.get('data_fim')
    
    # Converter strings para objetos datetime
    try:
        if data_inicio_str:
            data_inicio = datetime.fromisoformat(data_inicio_str.replace('Z', '+00:00'))
        else:
            # Padrão: último mês
            data_inicio = datetime.utcnow() - timedelta(days=30)
        
        if data_fim_str:
            data_fim = datetime.fromisoformat(data_fim_str.replace('Z', '+00:00'))
        else:
            data_fim = datetime.utcnow()
    except ValueError:
        return jsonify({'erro': 'Formato de data inválido. Use ISO 8601 (ex: 2023-01-31T12:00:00Z)'}), 400
    
    # Buscar usuários funcionários
    funcionarios = User.query.filter_by(role='employee').all()
    
    dados_relatorio = {
        'periodo': {
            'inicio': data_inicio.isoformat(),
            'fim': data_fim.isoformat()
        },
        'data_geracao': datetime.utcnow().isoformat(),
        'desempenho_funcionarios': []
    }
    
    total_geral = 0
    
    for funcionario in funcionarios:
        # Contar vendas do funcionário no período
        qtd_vendas = Transaction.query.filter(
            Transaction.transaction_type == 'sale',
            Transaction.user_id == funcionario.id,
            Transaction.created_at >= data_inicio,
            Transaction.created_at <= data_fim
        ).count()
        
        # Contar livros catalogados (adicionados) pelo funcionário
        qtd_catalogados = Transaction.query.filter(
            Transaction.transaction_type == 'addition',
            Transaction.user_id == funcionario.id,
            Transaction.created_at >= data_inicio,
            Transaction.created_at <= data_fim
        ).count()
        
        # Contar movimentações feitas pelo funcionário
        qtd_movimentacoes = Transaction.query.filter(
            Transaction.transaction_type == 'movement',
            Transaction.user_id == funcionario.id,
            Transaction.created_at >= data_inicio,
            Transaction.created_at <= data_fim
        ).count()
        
        total_geral += qtd_vendas
        
        dados_relatorio['desempenho_funcionarios'].append({
            'funcionario': {
                'id': funcionario.id,
                'nome': funcionario.username,
                'email': funcionario.email
            },
            'vendas': qtd_vendas,
            'livros_catalogados': qtd_catalogados,
            'movimentacoes': qtd_movimentacoes,
            'total_operacoes': qtd_vendas + qtd_catalogados + qtd_movimentacoes
        })
    
    # Ordenar por número de vendas (decrescente)
    dados_relatorio['desempenho_funcionarios'].sort(key=lambda x: x['vendas'], reverse=True)
    
    # Adicionar total geral
    dados_relatorio['total_vendas'] = total_geral
    
    return jsonify(dados_relatorio), 200

@reporting_bp.route('/generos-populares', methods=['GET'])
@jwt_required()
def relatorio_generos_populares():
    """Gerar relatório de gêneros populares baseado em vendas."""
    # Obter parâmetros de data
    data_inicio_str = request.args.get('data_inicio')
    data_fim_str = request.args.get('data_fim')
    limite = request.args.get('limite', default=10, type=int)
    
    # Converter strings para objetos datetime
    try:
        if data_inicio_str:
            data_inicio = datetime.fromisoformat(data_inicio_str.replace('Z', '+00:00'))
        else:
            # Padrão: último mês
            data_inicio = datetime.utcnow() - timedelta(days=30)
        
        if data_fim_str:
            data_fim = datetime.fromisoformat(data_fim_str.replace('Z', '+00:00'))
        else:
            data_fim = datetime.utcnow()
    except ValueError:
        return jsonify({'erro': 'Formato de data inválido. Use ISO 8601 (ex: 2023-01-31T12:00:00Z)'}), 400
    
    # Buscar vendas no período
    vendas = Transaction.query.filter(
        Transaction.transaction_type == 'sale',
        Transaction.created_at >= data_inicio,
        Transaction.created_at <= data_fim
    ).all()
    
    # Contagem por gênero
    generos_populares = {}
    
    for venda in vendas:
        livro = Book.query.get(venda.book_id)
        if livro and livro.genre:
            generos_populares[livro.genre] = generos_populares.get(livro.genre, 0) + 1
    
    # Converter para lista e ordenar
    lista_generos = [{'genero': genero, 'vendas': qtd} for genero, qtd in generos_populares.items()]
    lista_generos.sort(key=lambda x: x['vendas'], reverse=True)
    
    # Limitar a quantidade de resultados
    lista_generos = lista_generos[:limite]
    
    dados_relatorio = {
        'periodo': {
            'inicio': data_inicio.isoformat(),
            'fim': data_fim.isoformat()
        },
        'data_geracao': datetime.utcnow().isoformat(),
        'generos_populares': lista_generos
    }
    
    return jsonify(dados_relatorio), 200 