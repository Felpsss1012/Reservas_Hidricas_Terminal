import 'dart:convert';

import 'package:reservas_hidricas/interfaces/serializavel.dart';
import 'package:reservas_hidricas/models/registro_com_data.dart';
import 'package:reservas_hidricas/utils/validacao.dart';

class LeituraTelemetria extends RegistroComData implements Serializavel {
  static const double umidadeMinimaIdeal = 60.0;
  static const double nivelAguaCritico = 20.0;
  static const double temperaturaAlta = 35.0;

  final DateTime _dataHora;
  late double _nivelAguaPct;
  late double _umidadeSoloPct;
  late double _temperaturaCelsius;

  LeituraTelemetria({
    required DateTime dataHora,
    required double nivelAguaPct,
    required double umidadeSoloPct,
    required double temperaturaCelsius,
  }) : _dataHora = dataHora {
    this.nivelAguaPct = nivelAguaPct;
    this.umidadeSoloPct = umidadeSoloPct;
    this.temperaturaCelsius = temperaturaCelsius;
  }

  DateTime get dataHora => _dataHora;

  // A data exigida pela classe base RegistroComData.
  @override
  DateTime get data => _dataHora;

  double get nivelAguaPct => _nivelAguaPct;
  set nivelAguaPct(double v) => _nivelAguaPct = percentual(v, 'Nível de água');

  double get umidadeSoloPct => _umidadeSoloPct;
  set umidadeSoloPct(double v) =>
      _umidadeSoloPct = percentual(v, 'Umidade do solo');

  double get temperaturaCelsius => _temperaturaCelsius;
  set temperaturaCelsius(double v) {
    if (v.isNaN || v < -20 || v > 80) {
      throw ArgumentError('Temperatura fora da faixa plausível (-20 a 80 °C).');
    }
    _temperaturaCelsius = v;
  }

  String get statusMensagem {
    if (_nivelAguaPct < nivelAguaCritico) return 'ALERTA_NIVEL_BAIXO';
    if (_temperaturaCelsius > temperaturaAlta) return 'ALERTA_TEMP_ALTA';
    return 'OK';
  }

  bool get temAlerta => statusMensagem != 'OK';

  bool get precisaIrrigar => _umidadeSoloPct < umidadeMinimaIdeal;

  // Monta um mapa com os dados da leitura.
  @override
  Map<String, dynamic> toMap() {
    return {
      'dataHora': _dataHora.toIso8601String(),
      'nivelAguaPct': _nivelAguaPct,
      'umidadeSoloPct': _umidadeSoloPct,
      'temperaturaCelsius': _temperaturaCelsius,
      'statusMensagem': statusMensagem,
    };
  }

  // Gera o texto JSON a partir do mapa.
  @override
  String toJson() => jsonEncode(toMap());

  @override
  String toString() =>
      '${_dataHora.toIso8601String()} | água $_nivelAguaPct% | '
      'solo $_umidadeSoloPct% | $_temperaturaCelsius °C | $statusMensagem';
}
