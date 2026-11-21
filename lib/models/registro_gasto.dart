import 'dart:convert';

import 'package:reservas_hidricas/interfaces/serializavel.dart';
import 'package:reservas_hidricas/models/registro_com_data.dart';
import 'package:reservas_hidricas/utils/validacao.dart';

class RegistroGasto extends RegistroComData implements Serializavel {
  late String _descricao;
  late double _valor;
  final DateTime _dataGasto;
  late String _categoria;

  RegistroGasto({
    required String descricao,
    required double valor,
    required DateTime dataGasto,
    required String categoria,
  }) : _dataGasto = dataGasto {
    this.descricao = descricao;
    this.valor = valor;
    this.categoria = categoria;
  }

  String get descricao => _descricao;
  set descricao(String v) => _descricao = textoObrigatorio(v, 'Descrição', 150);

  double get valor => _valor;
  set valor(double v) {
    if (v.isNaN || v.isInfinite || v <= 0) {
      throw ArgumentError('O valor do gasto deve ser maior que zero.');
    }
    _valor = v;
  }

  DateTime get dataGasto => _dataGasto;

  // A data exigida pela classe base RegistroComData.
  @override
  DateTime get data => _dataGasto;

  String get categoria => _categoria;
  set categoria(String v) => _categoria = textoObrigatorio(v, 'Categoria', 60);

  // Monta um mapa com os dados do gasto.
  @override
  Map<String, dynamic> toMap() {
    return {
      'descricao': _descricao,
      'valor': _valor,
      'dataGasto': _dataGasto.toIso8601String(),
      'categoria': _categoria,
    };
  }

  // Gera o texto JSON a partir do mapa.
  @override
  String toJson() => jsonEncode(toMap());

  @override
  String toString() =>
      '$_categoria: R\$ ${_valor.toStringAsFixed(2)} - $_descricao';
}
