import 'dart:convert';

import 'package:reservas_hidricas/interfaces/serializavel.dart';

class DispositivoBroker implements Serializavel {
  static const int portaMqttPadrao = 1883;
  static const _statusValidos = {'Ativo', 'Inativo', 'Instável'};

  late String _ipBroker;
  late int _portaMqtt;
  late String _statusConexao;

  DispositivoBroker({
    required String ipBroker,
    int portaMqtt = portaMqttPadrao,
    String statusConexao = 'Ativo',
  }) {
    this.ipBroker = ipBroker;
    this.portaMqtt = portaMqtt;
    this.statusConexao = statusConexao;
  }

  String get ipBroker => _ipBroker;
  set ipBroker(String valor) {
    final partes = valor.trim().split('.');
    final valido = partes.length == 4 &&
        partes.every((p) {
          final n = int.tryParse(p);
          return n != null && n >= 0 && n <= 255;
        });
    if (!valido) throw ArgumentError('IP "$valor" inválido (esperado IPv4).');
    _ipBroker = valor.trim();
  }

  int get portaMqtt => _portaMqtt;
  set portaMqtt(int valor) {
    if (valor < 1 || valor > 65535) {
      throw ArgumentError('Porta MQTT deve estar entre 1 e 65535.');
    }
    _portaMqtt = valor;
  }

  String get statusConexao => _statusConexao;
  set statusConexao(String valor) {
    if (!_statusValidos.contains(valor)) {
      throw ArgumentError('Status inválido. Use: ${_statusValidos.join(', ')}.');
    }
    _statusConexao = valor;
  }

  bool get aptoParaReceberDados => _statusConexao != 'Inativo';

  // Monta um mapa com os dados do broker.
  @override
  Map<String, dynamic> toMap() {
    return {
      'ipBroker': _ipBroker,
      'portaMqtt': _portaMqtt,
      'statusConexao': _statusConexao,
    };
  }

  // Gera o texto JSON a partir do mapa.
  @override
  String toJson() => jsonEncode(toMap());

  @override
  String toString() => 'Broker $_ipBroker:$_portaMqtt [$_statusConexao]';
}
