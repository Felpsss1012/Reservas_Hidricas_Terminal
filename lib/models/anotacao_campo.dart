import 'dart:convert';

import 'package:reservas_hidricas/interfaces/serializavel.dart';
import 'package:reservas_hidricas/models/registro_com_data.dart';
import 'package:reservas_hidricas/models/usuario.dart';
import 'package:reservas_hidricas/utils/validacao.dart';

class AnotacaoCampo extends RegistroComData implements Serializavel {
  final DateTime _dataRegistro;
  late String _titulo;
  late String _texto;
  final Usuario _autor;

  AnotacaoCampo({
    required DateTime dataRegistro,
    required String titulo,
    required String texto,
    required Usuario autor,
  })  : _dataRegistro = dataRegistro,
        _autor = autor {
    this.titulo = titulo;
    this.texto = texto;
  }

  DateTime get dataRegistro => _dataRegistro;

  // A data exigida pela classe base RegistroComData.
  @override
  DateTime get data => _dataRegistro;
  Usuario get autor => _autor;

  String get titulo => _titulo;
  set titulo(String v) => _titulo = textoObrigatorio(v, 'Título', 100);

  String get texto => _texto;
  set texto(String v) {
    if (v.trim().isEmpty) throw ArgumentError('O texto é obrigatório.');
    _texto = v.trim();
  }

  // Monta um mapa com os dados da anotação.
  // O autor vira um mapa dentro do mapa.
  @override
  Map<String, dynamic> toMap() {
    return {
      'dataRegistro': _dataRegistro.toIso8601String(),
      'titulo': _titulo,
      'texto': _texto,
      'autor': _autor.toMap(),
    };
  }

  // Gera o texto JSON a partir do mapa.
  @override
  String toJson() => jsonEncode(toMap());

  @override
  String toString() => '[$_titulo] por ${_autor.nome}';
}
