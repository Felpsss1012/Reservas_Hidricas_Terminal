import 'dart:convert';

import 'package:reservas_hidricas/interfaces/serializavel.dart';
import 'package:reservas_hidricas/utils/validacao.dart';

class Usuario implements Serializavel {
  int? _idUsuario;
  late String _nome;
  late String _email;
  String _senhaHash;
  late String _cargo;

  Usuario({
    required String nome,
    required String email,
    required String senha,
    required String cargo,
  }) : _senhaHash = '' {
    this.nome = nome;
    this.email = email;
    this.cargo = cargo;
    alterarSenha(senha);
  }

  Usuario.comId({
    required int idUsuario,
    required String nome,
    required String email,
    required String cargo,
  })  : _idUsuario = idUsuario,
        _senhaHash = '' {
    this.nome = nome;
    this.email = email;
    this.cargo = cargo;
  }

  int? get idUsuario => _idUsuario;

  String get nome => _nome;
  set nome(String valor) => _nome = textoObrigatorio(valor, 'Nome', 100);

  String get email => _email;
  set email(String valor) {
    final e = textoObrigatorio(valor, 'E-mail', 120).toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(e)) {
      throw ArgumentError('E-mail em formato inválido.');
    }
    _email = e;
  }

  String get cargo => _cargo;
  set cargo(String valor) => _cargo = textoObrigatorio(valor, 'Cargo', 60);

  void alterarSenha(String novaSenha) {
    if (novaSenha.length < 8) {
      throw ArgumentError('A senha deve ter ao menos 8 caracteres.');
    }
    _senhaHash = _hash(novaSenha);
  }

  bool autenticar(String senha) => _hash(senha) == _senhaHash;

  String _hash(String s) =>
      s.codeUnits.fold<int>(7, (a, c) => a * 31 + c).toString();

  // Monta um mapa com os dados do usuário.
  // A senha e o hash ficam de fora.
  @override
  Map<String, dynamic> toMap() {
    return {
      'idUsuario': _idUsuario,
      'nome': _nome,
      'email': _email,
      'cargo': _cargo,
    };
  }

  // Gera o texto JSON a partir do mapa.
  @override
  String toJson() => jsonEncode(toMap());

  @override
  String toString() => '$_nome <$_email> ($_cargo)';
}
