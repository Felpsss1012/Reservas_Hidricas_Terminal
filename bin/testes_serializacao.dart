import 'dart:convert';
import 'dart:io';

import 'package:reservas_hidricas/interfaces/serializavel.dart';
import 'package:reservas_hidricas/models/acionamento_bomba.dart';
import 'package:reservas_hidricas/models/anotacao_campo.dart';
import 'package:reservas_hidricas/models/dispositivo_broker.dart';
import 'package:reservas_hidricas/models/estacao_monitoramento.dart';
import 'package:reservas_hidricas/models/leitura_telemetria.dart';
import 'package:reservas_hidricas/models/registro_com_data.dart';
import 'package:reservas_hidricas/models/registro_gasto.dart';
import 'package:reservas_hidricas/models/usuario.dart';

int _aprovados = 0;
int _reprovados = 0;

void main() {
  print('=== Testes de serialização (sem banco de dados) ===');

  final carlos = Usuario(
    nome: 'Carlos Eduardo Silva',
    email: 'carlos.silva@sou.unifeob.edu.br',
    senha: 'senhaForte123',
    cargo: 'Agrônomo Chefe',
  );

  final alpha = EstacaoMonitoramento(
    nome: 'Estufa Alpha - Tomate Cereja',
    localizacao: 'Setor Norte - Bloco A',
  );

  alpha.adicionarBroker(
    DispositivoBroker(ipBroker: '192.168.6.33', statusConexao: 'Ativo'),
  );

  final leitura = LeituraTelemetria(
    dataHora: DateTime(2026, 8, 25, 8),
    nivelAguaPct: 74.3,
    umidadeSoloPct: 61.7,
    temperaturaCelsius: 24.9,
  );
  alpha.registrarLeitura(leitura);

  final gasto = RegistroGasto(
    descricao: 'Compra de Filtro de Disco para Linha Principal',
    valor: 210,
    dataGasto: DateTime(2026, 8, 20),
    categoria: 'Infraestrutura Hídrica',
  );
  alpha.registrarGasto(gasto);

  final bombaAberta = AcionamentoBomba(
    dataHoraInicio: DateTime(2026, 8, 25, 6),
    modoAcionamento: 'Automático',
  );
  final bombaFechada = AcionamentoBomba(
    dataHoraInicio: DateTime(2026, 8, 25, 12),
    dataHoraFim: DateTime(2026, 8, 25, 12, 25),
    modoAcionamento: 'Automático',
  );
  alpha.registrarAcionamento(bombaAberta);
  alpha.registrarAcionamento(bombaFechada);

  final anotacao = AnotacaoCampo(
    dataRegistro: DateTime(2026, 8, 25, 8, 30),
    titulo: 'Ajuste na Nutri-irrigação',
    texto: 'Aumentada a dosagem de potássio na fase de maturação.',
    autor: carlos,
  );
  alpha.registrarAnotacao(anotacao);

  _conferir('DispositivoBroker toMap tem os três campos', () {
    final broker = DispositivoBroker(
      ipBroker: '192.168.6.33',
      statusConexao: 'Instável',
    );
    final mapa = broker.toMap();
    _igual(3, mapa.length, 'quantidade de campos');
    _igual('192.168.6.33', mapa['ipBroker'], 'ipBroker');
    _igual(1883, mapa['portaMqtt'], 'portaMqtt');
    _igual('Instável', mapa['statusConexao'], 'statusConexao');
  });

  _conferir('Usuario toMap não mostra senha nem hash', () {
    final mapa = carlos.toMap();
    _igual(4, mapa.length, 'quantidade de campos');
    _igual(null, mapa['senha'], 'senha');
    _igual(null, mapa['senhaHash'], 'senhaHash');
    _igual(null, mapa['idUsuario'], 'idUsuario');
    _igual('Carlos Eduardo Silva', mapa['nome'], 'nome');
    _igual('carlos.silva@sou.unifeob.edu.br', mapa['email'], 'email');
    if (carlos.toJson().contains('senha')) {
      throw ArgumentError('O JSON contém a palavra senha.');
    }
  });

  _conferir('Usuario comId guarda o id no mapa e no JSON', () {
    final comId = Usuario.comId(
      idUsuario: 7,
      nome: 'Maria Oliveira',
      email: 'maria.oliveira@sou.unifeob.edu.br',
      cargo: 'Técnica em Irrigação',
    );
    _igual(7, comId.toMap()['idUsuario'], 'idUsuario');
    final decodificado = jsonDecode(comId.toJson()) as Map<String, dynamic>;
    _igual('Maria Oliveira', decodificado['nome'], 'nome no JSON');
    _igual(null, decodificado['senha'], 'senha no JSON');
  });

  _conferir('RegistroGasto grava a data em formato ISO', () {
    final mapa = gasto.toMap();
    _igual(4, mapa.length, 'quantidade de campos');
    _igual(
      DateTime(2026, 8, 20).toIso8601String(),
      mapa['dataGasto'],
      'dataGasto',
    );
    _igual(210.0, mapa['valor'], 'valor');
    _igual('Infraestrutura Hídrica', mapa['categoria'], 'categoria');
  });

  _conferir('LeituraTelemetria toMap tem data ISO e status', () {
    final mapa = leitura.toMap();
    _igual(5, mapa.length, 'quantidade de campos');
    _igual(
      DateTime(2026, 8, 25, 8).toIso8601String(),
      mapa['dataHora'],
      'dataHora',
    );
    _igual(74.3, mapa['nivelAguaPct'], 'nivelAguaPct');
    _igual(61.7, mapa['umidadeSoloPct'], 'umidadeSoloPct');
    _igual(24.9, mapa['temperaturaCelsius'], 'temperaturaCelsius');
    _igual('OK', mapa['statusMensagem'], 'statusMensagem');
  });

  _conferir('Acionamento em andamento fica com dataHoraFim nulo', () {
    final mapa = bombaAberta.toMap();
    _igual(3, mapa.length, 'quantidade de campos');
    _igual(null, mapa['dataHoraFim'], 'dataHoraFim');
    _igual(
      DateTime(2026, 8, 25, 6).toIso8601String(),
      mapa['dataHoraInicio'],
      'dataHoraInicio',
    );
    _igual('Automático', mapa['modoAcionamento'], 'modoAcionamento');
  });

  _conferir('Acionamento encerrado grava o fim em ISO', () {
    final mapa = bombaFechada.toMap();
    _igual(
      DateTime(2026, 8, 25, 12, 25).toIso8601String(),
      mapa['dataHoraFim'],
      'dataHoraFim',
    );
    _igual(false, mapa['dataHoraFim'] == null, 'dataHoraFim não nulo');
  });

  _conferir('AnotacaoCampo aninha o autor dentro do mapa', () {
    final mapa = anotacao.toMap();
    _igual(4, mapa.length, 'quantidade de campos');
    _igual(
      DateTime(2026, 8, 25, 8, 30).toIso8601String(),
      mapa['dataRegistro'],
      'dataRegistro',
    );
    final autor = mapa['autor'];
    if (autor is! Map) {
      throw ArgumentError('O autor não virou um mapa.');
    }
    _igual(4, autor.length, 'quantidade de campos do autor');
    _igual('Carlos Eduardo Silva', autor['nome'], 'autor.nome');
    _igual(null, autor['senha'], 'autor.senha');
    _igual(null, autor['senhaHash'], 'autor.senhaHash');
  });

  _conferir('EstacaoMonitoramento lista as coleções de objetos', () {
    final mapa = alpha.toMap();
    _igual(7, mapa.length, 'quantidade de campos');
    _igual('Estufa Alpha - Tomate Cereja', mapa['nome'], 'nome');
    _igual(1, (mapa['brokers'] as List).length, 'quantidade de brokers');
    _igual(1, (mapa['leituras'] as List).length, 'quantidade de leituras');
    _igual(
        2, (mapa['acionamentos'] as List).length, 'quantidade de acionamentos');
    _igual(1, (mapa['gastos'] as List).length, 'quantidade de gastos');
    _igual(1, (mapa['anotacoes'] as List).length, 'quantidade de anotações');
    final primeira = (mapa['leituras'] as List).first as Map;
    _igual('OK', primeira['statusMensagem'], 'statusMensagem da leitura');
    final acionamento = (mapa['acionamentos'] as List).first as Map;
    _igual(null, acionamento['dataHoraFim'], 'dataHoraFim da bomba aberta');
  });

  _conferir('EstacaoMonitoramento toMap vira JSON válido', () {
    final decodificado = jsonDecode(alpha.toJson()) as Map<String, dynamic>;
    final leituras = decodificado['leituras'] as List;
    _igual(1, leituras.length, 'leituras no JSON');
    final primeira = leituras.first as Map;
    _igual('OK', primeira['statusMensagem'], 'statusMensagem no JSON');
    final gastos = decodificado['gastos'] as List;
    _igual(
      DateTime(2026, 8, 20).toIso8601String(),
      (gastos.first as Map)['dataGasto'],
      'dataGasto no JSON',
    );
    final anotacoes = decodificado['anotacoes'] as List;
    final autor = ((anotacoes.first as Map)['autor']) as Map;
    _igual('Carlos Eduardo Silva', autor['nome'], 'autor no JSON');
  });

  _conferir('Os sete modelos implementam Serializavel', () {
    final List<Serializavel> objetos = [
      carlos,
      DispositivoBroker(ipBroker: '10.0.0.5'),
      leitura,
      gasto,
      bombaAberta,
      anotacao,
      alpha,
    ];
    _igual(7, objetos.length, 'quantidade de objetos');
    for (final objeto in objetos) {
      final decodificado = jsonDecode(objeto.toJson());
      if (decodificado is! Map) {
        throw ArgumentError('O JSON de ${objeto.runtimeType} não é um mapa.');
      }
      if (objeto.toMap().length != decodificado.length) {
        throw ArgumentError('O JSON de ${objeto.runtimeType} perdeu campos.');
      }
    }
  });

  _conferir('Valores nulos passam pelo JSON', () {
    final usuarioJson = jsonDecode(carlos.toJson()) as Map<String, dynamic>;
    _igual(null, usuarioJson['idUsuario'], 'idUsuario');
    final bombaJson = jsonDecode(bombaAberta.toJson()) as Map<String, dynamic>;
    _igual(null, bombaJson['dataHoraFim'], 'dataHoraFim');
    _igual(true, bombaAberta.emAndamento, 'bomba em andamento');
  });

  _conferir('RegistroComData devolve a data de cada modelo', () {
    _igual(DateTime(2026, 8, 25, 8), leitura.data, 'data da leitura');
    _igual(DateTime(2026, 8, 20), gasto.data, 'data do gasto');
    _igual(DateTime(2026, 8, 25, 6), bombaAberta.data, 'data do acionamento');
    _igual(DateTime(2026, 8, 25, 8, 30), anotacao.data, 'data da anotação');
  });

  _conferir('Polimorfismo: uma lista com quatro modelos diferentes', () {
    final List<RegistroComData> registros = [
      leitura,
      gasto,
      bombaAberta,
      anotacao,
    ];
    _igual(4, registros.length, 'quantidade de registros');
    // O laço não sabe qual é a classe, mas todos têm a data.
    for (final registro in registros) {
      print('  ${registro.runtimeType}: ${registro.data}');
      if (registro.data.isBefore(DateTime(2026, 1, 1))) {
        throw ArgumentError('Data inválida em ${registro.runtimeType}.');
      }
    }
    _igual(true, alpha is! RegistroComData, 'estação não é RegistroComData');
  });

  if (_reprovados > 0) {
    exitCode = 1;
  }

  print('\nResultado: $_aprovados aprovado(s), $_reprovados reprovado(s).');
  if (_reprovados == 0) {
    print('Todos os testes passaram.');
  } else {
    print('Há testes reprovados.');
    // Sai com código diferente de zero quando há falha.
    exit(1);
  }
}

void _conferir(String descricao, void Function() verificacao) {
  try {
    verificacao();
    _aprovados++;
    print('[OK] $descricao');
  } catch (e) {
    _reprovados++;
    print('[FALHOU] $descricao -> $e');
  }
}

void _igual(dynamic esperado, dynamic obtido, String campo) {
  if (esperado != obtido) {
    throw ArgumentError('$campo: esperado "$esperado", obtido "$obtido".');
  }
}
