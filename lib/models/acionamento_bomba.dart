import 'dart:convert';

import 'package:reservas_hidricas/excecoes/regra_de_negocio_exception.dart';
import 'package:reservas_hidricas/interfaces/serializavel.dart';
import 'package:reservas_hidricas/models/registro_com_data.dart';
import 'package:reservas_hidricas/utils/validacao.dart';

class AcionamentoBomba extends RegistroComData implements Serializavel {
  final DateTime _dataHoraInicio;
  DateTime? _dataHoraFim;
  late String _modoAcionamento;

  AcionamentoBomba({
    required DateTime dataHoraInicio,
    required String modoAcionamento,
    DateTime? dataHoraFim,
  }) : _dataHoraInicio = dataHoraInicio {
    this.modoAcionamento = modoAcionamento;
    if (dataHoraFim != null) encerrar(dataHoraFim);
  }

  DateTime get dataHoraInicio => _dataHoraInicio;
  DateTime? get dataHoraFim => _dataHoraFim;

  // A data exigida pela classe base RegistroComData.
  @override
  DateTime get data => _dataHoraInicio;

  String get modoAcionamento => _modoAcionamento;
  set modoAcionamento(String v) =>
      _modoAcionamento = textoObrigatorio(v, 'Modo de acionamento', 50);

  bool get emAndamento => _dataHoraFim == null;

  void encerrar(DateTime fim) {
    if (!emAndamento) {
      throw RegraDeNegocioException('Este acionamento já foi encerrado.');
    }
    if (!fim.isAfter(_dataHoraInicio)) {
      throw ArgumentError('O fim deve ser posterior ao início.');
    }
    _dataHoraFim = fim;
  }

  Duration? get duracao => _dataHoraFim?.difference(_dataHoraInicio);

  // Monta um mapa com os dados do acionamento.
  // dataHoraFim fica nulo enquanto a bomba estiver em andamento.
  @override
  Map<String, dynamic> toMap() {
    return {
      'dataHoraInicio': _dataHoraInicio.toIso8601String(),
      'dataHoraFim': _dataHoraFim?.toIso8601String(),
      'modoAcionamento': _modoAcionamento,
    };
  }

  // Gera o texto JSON a partir do mapa.
  @override
  String toJson() => jsonEncode(toMap());

  @override
  String toString() =>
      '$_modoAcionamento | ${_dataHoraInicio.toIso8601String()} | '
      '${duracao?.inMinutes ?? "em andamento"} min';
}
