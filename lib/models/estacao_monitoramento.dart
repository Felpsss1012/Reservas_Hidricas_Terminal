import 'dart:convert';

import 'package:reservas_hidricas/excecoes/regra_de_negocio_exception.dart';
import 'package:reservas_hidricas/interfaces/serializavel.dart';
import 'package:reservas_hidricas/models/acionamento_bomba.dart';
import 'package:reservas_hidricas/models/anotacao_campo.dart';
import 'package:reservas_hidricas/models/dispositivo_broker.dart';
import 'package:reservas_hidricas/models/leitura_telemetria.dart';
import 'package:reservas_hidricas/models/registro_gasto.dart';
import 'package:reservas_hidricas/utils/validacao.dart';

class EstacaoMonitoramento implements Serializavel {
  late String _nome;
  late String _localizacao;

  final List<DispositivoBroker> _brokers = [];
  final List<LeituraTelemetria> _leituras = [];
  final List<AcionamentoBomba> _acionamentos = [];
  final List<RegistroGasto> _gastos = [];
  final List<AnotacaoCampo> _anotacoes = [];

  EstacaoMonitoramento({required String nome, required String localizacao}) {
    this.nome = nome;
    this.localizacao = localizacao;
  }

  String get nome => _nome;
  set nome(String v) => _nome = textoObrigatorio(v, 'Nome da estação', 100);

  String get localizacao => _localizacao;
  set localizacao(String v) =>
      _localizacao = textoObrigatorio(v, 'Localização', 100);

  List<DispositivoBroker> get brokers => List.unmodifiable(_brokers);
  List<LeituraTelemetria> get leituras => List.unmodifiable(_leituras);
  List<AcionamentoBomba> get acionamentos => List.unmodifiable(_acionamentos);
  List<RegistroGasto> get gastos => List.unmodifiable(_gastos);
  List<AnotacaoCampo> get anotacoes => List.unmodifiable(_anotacoes);

  void adicionarBroker(DispositivoBroker b) => _brokers.add(b);
  void registrarLeitura(LeituraTelemetria l) => _leituras.add(l);
  void registrarGasto(RegistroGasto g) => _gastos.add(g);
  void registrarAnotacao(AnotacaoCampo a) => _anotacoes.add(a);

  void registrarAcionamento(AcionamentoBomba a) {
    if (a.emAndamento && _acionamentos.any((x) => x.emAndamento)) {
      throw RegraDeNegocioException(
          'Já existe um acionamento da bomba em andamento nesta estação.');
    }
    _acionamentos.add(a);
  }

  bool get podeSerRemovida =>
      _brokers.isEmpty &&
      _leituras.isEmpty &&
      _acionamentos.isEmpty &&
      _gastos.isEmpty &&
      _anotacoes.isEmpty;

  double get mediaNivelAgua => _media((l) => l.nivelAguaPct);
  double get mediaUmidadeSolo => _media((l) => l.umidadeSoloPct);
  double get mediaTemperatura => _media((l) => l.temperaturaCelsius);

  double get totalGasto => _gastos.fold(0.0, (soma, g) => soma + g.valor);

  Map<String, double> gastoPorCategoria() {
    final mapa = <String, double>{};
    for (final g in _gastos) {
      mapa[g.categoria] = (mapa[g.categoria] ?? 0) + g.valor;
    }
    return mapa;
  }

  List<LeituraTelemetria> get leiturasComAlerta =>
      _leituras.where((l) => l.temAlerta).toList();

  int get minutosBombaLigada => _acionamentos
      .map((a) => a.duracao?.inMinutes ?? 0)
      .fold(0, (soma, m) => soma + m);

  String get recomendacaoIrrigacao {
    if (_leituras.isEmpty) return 'Sem leituras para avaliar.';
    final ultima =
        _leituras.reduce((a, b) => a.dataHora.isAfter(b.dataHora) ? a : b);
    if (ultima.nivelAguaPct < LeituraTelemetria.nivelAguaCritico) {
      return 'Reservatório crítico: reabastecer antes de irrigar.';
    }
    return ultima.precisaIrrigar
        ? 'Solo seco (${ultima.umidadeSoloPct}%): acionar irrigação.'
        : 'Umidade adequada (${ultima.umidadeSoloPct}%): irrigação desnecessária.';
  }

  double _media(double Function(LeituraTelemetria) campo) {
    if (_leituras.isEmpty) return 0.0;
    final soma = _leituras.fold(0.0, (s, l) => s + campo(l));
    return soma / _leituras.length;
  }

  // Monta um mapa com a estação e as coleções de objetos.
  @override
  Map<String, dynamic> toMap() {
    return {
      'nome': _nome,
      'localizacao': _localizacao,
      'brokers': _brokers.map((b) => b.toMap()).toList(),
      'leituras': _leituras.map((l) => l.toMap()).toList(),
      'acionamentos': _acionamentos.map((a) => a.toMap()).toList(),
      'gastos': _gastos.map((g) => g.toMap()).toList(),
      'anotacoes': _anotacoes.map((an) => an.toMap()).toList(),
    };
  }

  // Gera o texto JSON a partir do mapa.
  @override
  String toJson() => jsonEncode(toMap());

  @override
  String toString() => '$_nome ($_localizacao)';
}
