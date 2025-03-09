import 'livro_model.dart';
import 'user_model.dart';

class Transacao {
  final int id;
  final int livroId;
  final int usuarioId;
  final String tipoTransacao; // 'venda', 'adicao', 'movimentacao'
  final String? secaoOrigem;
  final String? secaoDestino;
  final String? observacoes;
  final String dataCriacao;
  
  // Relações opcionais para exibição completa
  final Livro? livro;
  final User? usuario;

  Transacao({
    required this.id,
    required this.livroId,
    required this.usuarioId,
    required this.tipoTransacao,
    this.secaoOrigem,
    this.secaoDestino,
    this.observacoes,
    required this.dataCriacao,
    this.livro,
    this.usuario,
  });

  factory Transacao.fromJson(Map<String, dynamic> json) {
    return Transacao(
      id: json['id'],
      livroId: json['book_id'],
      usuarioId: json['user_id'],
      tipoTransacao: _traduzirTipoTransacao(json['transaction_type']),
      secaoOrigem: json['from_section'],
      secaoDestino: json['to_section'],
      observacoes: json['notes'],
      dataCriacao: json['created_at'],
      livro: json['book'] != null ? Livro.fromJson(json['book']) : null,
      usuario: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  // Tradutor para tipos de transação do backend para português
  static String _traduzirTipoTransacao(String tipo) {
    switch (tipo) {
      case 'sale':
        return 'venda';
      case 'addition':
        return 'adicao';
      case 'movement':
        return 'movimentacao';
      default:
        return tipo;
    }
  }

  // Tradutor inverso para enviar ao backend
  static String traduzirParaIngles(String tipoEmPortugues) {
    switch (tipoEmPortugues) {
      case 'venda':
        return 'sale';
      case 'adicao':
        return 'addition';
      case 'movimentacao':
        return 'movement';
      default:
        return tipoEmPortugues;
    }
  }

  bool isVenda() {
    return tipoTransacao == 'venda';
  }

  bool isAdicao() {
    return tipoTransacao == 'adicao';
  }

  bool isMovimentacao() {
    return tipoTransacao == 'movimentacao';
  }
} 