import 'dart:io';
import 'dart:math';

import 'package:mysql_client/exception.dart';

import 'package:reservas_hidricas/excecoes/regra_de_negocio_exception.dart';
import 'package:reservas_hidricas/models/anotacao_campo.dart';
import 'package:reservas_hidricas/models/leitura_telemetria.dart';
import 'package:reservas_hidricas/models/registro_gasto.dart';
import 'package:reservas_hidricas/models/usuario.dart';
import 'package:reservas_hidricas/src/repositorio.dart';

class MenuInterativo {
  final Repositorio _repositorio;
  final Random _random = Random();
  int? _idEstacaoAtual;
  String? _nomeEstacaoAtual;
  List<Map<String, dynamic>> _usuarios = [];

  MenuInterativo({required Repositorio repositorio}) : _repositorio = repositorio;

  Future<void> executar() async {
    _usuarios = await _executarSeguro(() => _repositorio.listarUsuarios(), 'Erro ao carregar autores');
    var sair = false;
    while (!sair) {
      _exibirMenuPrincipal();
      final opcao = _lerInteiro('Escolha uma opção');
      if (opcao == null) continue;
      switch (opcao) {
        case 1:
          await _executarSeguro(_selecionarEstacao, 'Erro ao selecionar estação');
          _pausar();
          break;
        case 2:
          if (await _garantirEstacao()) await _executarSeguro(_menuLeituras, 'Erro nas leituras');
          break;
        case 3:
          if (await _garantirEstacao()) {
            await _executarSeguro(_mostrarMedias, 'Erro ao mostrar médias');
            _pausar();
          }
          break;
        case 4:
          if (await _garantirEstacao()) {
            await _executarSeguro(_mostrarGastos, 'Erro ao mostrar gastos');
            _pausar();
          }
          break;
        case 5:
          if (await _garantirEstacao()) {
            await _executarSeguro(_mostrarAcionamentos, 'Erro ao mostrar acionamentos');
            _pausar();
          }
          break;
        case 6:
          if (await _garantirEstacao()) {
            await _executarSeguro(_mostrarAnotacoes, 'Erro ao mostrar anotações');
            _pausar();
          }
          break;
        case 7:
          if (await _garantirEstacao()) {
            await _executarSeguro(_mostrarRecomendacao, 'Erro ao mostrar recomendação');
            _pausar();
          }
          break;
        case 8:
          if (await _garantirEstacao()) await _executarSeguro(_menuCadastro, 'Erro no cadastro');
          break;
        case 9:
          if (await _garantirEstacao()) {
            await _executarSeguro(_simularLeitura, 'Erro ao simular leitura');
            _pausar();
          }
          break;
        case 10:
          if (await _garantirEstacao()) {
            await _executarSeguro(_verificarRemocao, 'Erro ao verificar remoção');
            _pausar();
          }
          break;
        case 11:
          await _executarSeguro(_mostrarEstatisticas, 'Erro ao mostrar estatísticas');
          _pausar();
          break;
        case 0:
          sair = true;
          print('Encerrando o sistema. Até logo!');
          break;
        default:
          print('Opção inválida. Digite um número entre 0 e 11.');
      }
    }
  }

  void _exibirMenuPrincipal() {
    final estacao = _nomeEstacaoAtual ?? '(nenhuma)';
    print('\n============================');
    print(' Reservas Hídricas - Estufas');
    print(' Estação atual: $estacao');
    print('============================');
    print(' 1) Selecionar estação');
    print(' 2) Leituras de telemetria');
    print(' 3) Médias da estação');
    print(' 4) Gastos e custos');
    print(' 5) Acionamentos da bomba');
    print(' 6) Anotações de campo');
    print(' 7) Recomendação de irrigação');
    print(' 8) Cadastrar novo registro');
    print(' 9) Simular leitura automática');
    print('10) Verificar remoção da estação');
    print('11) Estatísticas do banco de dados');
    print(' 0) Sair');
  }

  Future<bool> _garantirEstacao() async {
    if (_idEstacaoAtual != null) return true;
    print('Nenhuma estação selecionada. Use a opção 1 para escolher uma estação.');
    return false;
  }

  Future<void> _selecionarEstacao() async {
    final estacoes = await _repositorio.listarEstacoes();
    if (estacoes.isEmpty) {
      print('Nenhuma estação cadastrada.');
      return;
    }
    print('\nEstações disponíveis:');
    for (var i = 0; i < estacoes.length; i++) {
      final e = estacoes[i];
      print(' ${i + 1}) ${e['nome']} (${e['localizacao']})');
    }
    print(' 0) Voltar');
    final opcao = _lerInteiro('Escolha a estação');
    if (opcao == null || opcao == 0) return;
    if (opcao < 1 || opcao > estacoes.length) {
      print('Opção de estação inválida.');
      return;
    }
    final escolhida = estacoes[opcao - 1];
    _idEstacaoAtual = int.tryParse(escolhida['idEstacao'].toString());
    _nomeEstacaoAtual = escolhida['nome'] as String;
    print('Estação selecionada: $_nomeEstacaoAtual');
  }

  Future<void> _menuLeituras() async {
    var voltar = false;
    while (!voltar) {
      print('\n--- Leituras de telemetria ---');
      print(' 1) Todas as leituras');
      print(' 2) Somente leituras com alerta');
      print(' 0) Voltar');
      final opcao = _lerInteiro('Opção');
      if (opcao == null) continue;
      switch (opcao) {
        case 1:
          await _listarLeituras(false, 'Todas as leituras');
          _pausar();
          break;
        case 2:
          await _listarLeituras(true, 'Leituras com alerta');
          _pausar();
          break;
        case 0:
          voltar = true;
          break;
        default:
          print('Opção inválida.');
      }
    }
  }

  Future<void> _listarLeituras(bool somenteAlertas, String titulo) async {
    final leituras = await _repositorio.listarLeituras(_idEstacaoAtual!, somenteAlertas: somenteAlertas);
    print('\n$titulo (${leituras.length}):');
    if (leituras.isEmpty) {
      print(' Nenhuma leitura registrada.');
      return;
    }
    for (var i = 0; i < leituras.length; i++) {
      final l = leituras[i];
      print(' ${i + 1}) ${_formatarData(l['dataHora'])} | '
          'água ${_num(l['nivelAguaPct']).toStringAsFixed(1)}% | '
          'solo ${_num(l['umidadeSoloPct']).toStringAsFixed(1)}% | '
          '${_num(l['temperaturaCelsius']).toStringAsFixed(1)} °C | '
          '${l['statusMensagem']}');
    }
  }

  Future<void> _mostrarMedias() async {
    final medias = await _repositorio.mediasEstacao(_idEstacaoAtual!);
    if (medias == null) {
      print(' Sem leituras para calcular médias.');
      return;
    }
    print('\n--- Médias da estação: $_nomeEstacaoAtual ---');
    print(' Leituras consideradas: ${medias['total']}');
    print(' Nível de água: ${_num(medias['mediaNivel']).toStringAsFixed(2)}%');
    print(' Umidade do solo: ${_num(medias['mediaUmidade']).toStringAsFixed(2)}%');
    print(' Temperatura: ${_num(medias['mediaTemperatura']).toStringAsFixed(2)} °C');
  }

  Future<void> _mostrarGastos() async {
    final gastos = await _repositorio.listarGastos(_idEstacaoAtual!);
    print('\n--- Gastos e custos: $_nomeEstacaoAtual ---');
    if (gastos.isEmpty) {
      print(' Nenhum gasto registrado.');
      return;
    }
    for (var i = 0; i < gastos.length; i++) {
      final g = gastos[i];
      print(' ${i + 1}) ${_formatarData(g['dataGasto'])} | ${g['categoria']} | '
          'R\$ ${_num(g['valor']).toStringAsFixed(2)} | ${g['descricao']}');
    }
    final total = await _repositorio.totalGastos(_idEstacaoAtual!);
    print(' Total gasto: R\$ ${_num(total).toStringAsFixed(2)}');
    print(' Gasto por categoria:');
    final porCategoria = await _repositorio.gastosPorCategoria(_idEstacaoAtual!);
    for (final c in porCategoria) {
      print('   - ${c['categoria']}: R\$ ${_num(c['total']).toStringAsFixed(2)}');
    }
  }

  Future<void> _mostrarAcionamentos() async {
    final acionamentos = await _repositorio.listarAcionamentos(_idEstacaoAtual!);
    print('\n--- Acionamentos da bomba: $_nomeEstacaoAtual ---');
    if (acionamentos.isEmpty) {
      print(' Nenhum acionamento registrado.');
      return;
    }
    for (var i = 0; i < acionamentos.length; i++) {
      final a = acionamentos[i];
      final fim = a['dataHoraFim'] == null ? 'em andamento' : _formatarData(a['dataHoraFim']);
      print(' ${i + 1}) ${a['modoAcionamento']} | '
          'início ${_formatarData(a['dataHoraInicio'])} | fim $fim | '
          '${a['minutos']} min');
    }
    final total = await _repositorio.totalMinutosBomba(_idEstacaoAtual!);
    print(' Total de minutos com a bomba ligada: ${total ?? 0} min');
  }

  Future<void> _mostrarAnotacoes() async {
    final anotacoes = await _repositorio.listarAnotacoes(_idEstacaoAtual!);
    print('\n--- Anotações de campo: $_nomeEstacaoAtual ---');
    if (anotacoes.isEmpty) {
      print(' Nenhuma anotação registrada.');
      return;
    }
    for (var i = 0; i < anotacoes.length; i++) {
      final a = anotacoes[i];
      print(' ${i + 1}) ${_formatarData(a['dataRegistro'])} | ${a['titulo']}');
      print('     ${a['texto']}');
      print('     Autor: ${a['autorNome']} (${a['autorCargo']})');
    }
  }

  Future<void> _mostrarRecomendacao() async {
    final ultima = await _repositorio.ultimaLeitura(_idEstacaoAtual!);
    if (ultima == null) {
      print(' Sem leituras para avaliar.');
      return;
    }
    print('\n--- Recomendação de irrigação: $_nomeEstacaoAtual ---');
    final nivel = _num(ultima['nivelAguaPct']);
    final umidade = _num(ultima['umidadeSoloPct']);
    if (nivel < 20) {
      print(' Reservatório crítico: reabastecer antes de irrigar.');
    } else if (umidade < 60) {
      print(' Solo seco (${umidade.toStringAsFixed(1)}%): acionar irrigação.');
    } else {
      print(' Umidade adequada (${umidade.toStringAsFixed(1)}%): irrigação desnecessária.');
    }
  }

  Future<void> _verificarRemocao() async {
    final pode = await _repositorio.podeRemoverEstacao(_idEstacaoAtual!);
    print('\n--- Verificação de remoção: $_nomeEstacaoAtual ---');
    if (pode) {
      print(' A estação PODE ser removida (sem dados vinculados).');
    } else {
      print(' A estação NÃO pode ser removida: ainda possui dados vinculados.');
    }
  }

  Future<void> _menuCadastro() async {
    var voltar = false;
    while (!voltar) {
      print('\n--- Cadastrar novo registro ---');
      print(' 1) Nova leitura de telemetria');
      print(' 2) Novo gasto');
      print(' 3) Nova anotação de campo');
      print(' 0) Voltar');
      final opcao = _lerInteiro('Opção');
      if (opcao == null) continue;
      switch (opcao) {
        case 1:
          await _executarSeguro(_cadastrarLeitura, 'Erro ao cadastrar leitura');
          _pausar();
          break;
        case 2:
          await _executarSeguro(_cadastrarGasto, 'Erro ao cadastrar gasto');
          _pausar();
          break;
        case 3:
          await _executarSeguro(_cadastrarAnotacao, 'Erro ao cadastrar anotação');
          _pausar();
          break;
        case 0:
          voltar = true;
          break;
        default:
          print('Opção inválida.');
      }
    }
  }

  Future<void> _cadastrarLeitura() async {
    print('\nNova leitura de telemetria');
    final nivel = _lerDouble('Nível de água (%)');
    if (nivel == null) return;
    final solo = _lerDouble('Umidade do solo (%)');
    if (solo == null) return;
    final temperatura = _lerDouble('Temperatura (°C)');
    if (temperatura == null) return;
    final data = _lerDataHoraOuPadrao('Data e hora (vazio = agora)');
    if (data == null) return;
    final leitura = LeituraTelemetria(
      dataHora: data,
      nivelAguaPct: nivel,
      umidadeSoloPct: solo,
      temperaturaCelsius: temperatura,
    );
    final id = await _repositorio.inserirLeitura(leitura, _idEstacaoAtual!);
    print('Leitura registrada com sucesso. ID: $id | Situação: ${leitura.statusMensagem}');
  }

  Future<void> _cadastrarGasto() async {
    print('\nNovo gasto');
    final descricao = _lerLinha('Descrição');
    final categoria = _lerLinha('Categoria');
    final valor = _lerDouble('Valor (R\$)');
    if (valor == null) return;
    final data = _lerDataHoraOuPadrao('Data (vazio = hoje)');
    if (data == null) return;
    final gasto = RegistroGasto(
      descricao: descricao,
      valor: valor,
      dataGasto: data,
      categoria: categoria,
    );
    final id = await _repositorio.inserirGasto(gasto, _idEstacaoAtual!);
    print('Gasto registrado com sucesso. ID: $id');
  }

  Future<void> _cadastrarAnotacao() async {
    print('\nNova anotação de campo');
    final titulo = _lerLinha('Título');
    final texto = _lerLinha('Texto');
    final autor = _escolherAutor();
    if (autor == null) return;
    final data = _lerDataHoraOuPadrao('Data (vazio = agora)');
    if (data == null) return;
    final anotacao = AnotacaoCampo(
      dataRegistro: data,
      titulo: titulo,
      texto: texto,
      autor: autor,
    );
    final id = await _repositorio.inserirAnotacao(anotacao, _idEstacaoAtual!);
    print('Anotação registrada com sucesso. ID: $id');
  }

  Usuario? _escolherAutor() {
    if (_usuarios.isEmpty) {
      print('Nenhum autor cadastrado.');
      return null;
    }
    print('Autores disponíveis:');
    for (var i = 0; i < _usuarios.length; i++) {
      final u = _usuarios[i];
      print(' ${i + 1}) ${u['nome']} <${u['email']}> (${u['cargo']})');
    }
    print(' 0) Cancelar');
    final opcao = _lerInteiro('Escolha o autor');
    if (opcao == null || opcao == 0) return null;
    if (opcao < 1 || opcao > _usuarios.length) {
      print('Autor inválido.');
      return null;
    }
    final u = _usuarios[opcao - 1];
    return Usuario.comId(
      idUsuario: int.tryParse(u['idUsuario'].toString()) ?? 0,
      nome: u['nome'] as String,
      email: u['email'] as String,
      cargo: u['cargo'] as String,
    );
  }

  Future<void> _simularLeitura() async {
    final nivel = _arredondar(10 + _random.nextDouble() * 85);
    final solo = _arredondar(35 + _random.nextDouble() * 55);
    final temperatura = _arredondar(16 + _random.nextDouble() * 22);
    final leitura = LeituraTelemetria(
      dataHora: DateTime.now(),
      nivelAguaPct: nivel,
      umidadeSoloPct: solo,
      temperaturaCelsius: temperatura,
    );
    final id = await _repositorio.inserirLeitura(leitura, _idEstacaoAtual!);
    print('\nLeitura automática simulada e registrada. ID: $id');
    print(' ${_formatarData(leitura.dataHora)} | '
        'água ${leitura.nivelAguaPct.toStringAsFixed(1)}% | '
        'solo ${leitura.umidadeSoloPct.toStringAsFixed(1)}% | '
        '${leitura.temperaturaCelsius.toStringAsFixed(1)} °C | '
        '${leitura.statusMensagem}');
  }

  Future<void> _mostrarEstatisticas() async {
    final contagens = await _repositorio.contagensTabelas();
    print('\n--- Estatísticas do banco de dados ---');
    contagens.forEach((tabela, total) {
      print(' $tabela: $total');
    });
  }

  Future<T> _executarSeguro<T>(Future<T> Function() acao, String mensagemErro) async {
    try {
      return await acao();
    } on ArgumentError catch (e) {
      print('Erro de validação: ${e.message}');
    } on RegraDeNegocioException catch (e) {
      print('Erro de regra de negócio: ${e.mensagem}');
    } on SocketException catch (e) {
      print('Erro de conexão: ${e.message}');
    } on MySQLException catch (e) {
      print('Erro do banco de dados: $e');
    } catch (e) {
      print('$mensagemErro: $e');
    }
    return null as T;
  }

  String _lerLinha(String rotulo) {
    stdout.write('$rotulo: ');
    final linha = stdin.readLineSync();
    if (linha == null) {
      print('\nEntrada encerrada. Encerrando o sistema.');
      exit(0);
    }
    return linha.trim();
  }

  int? _lerInteiro(String rotulo) {
    final texto = _lerLinha(rotulo);
    final valor = int.tryParse(texto);
    if (valor == null) {
      print('Entrada inválida. Digite um número inteiro.');
    }
    return valor;
  }

  double? _lerDouble(String rotulo) {
    final texto = _lerLinha(rotulo).replaceAll(',', '.');
    final valor = double.tryParse(texto);
    if (valor == null) {
      print('Entrada inválida. Digite um número (ex.: 62.5).');
    }
    return valor;
  }

  DateTime? _lerDataHoraOuPadrao(String rotulo) {
    final texto = _lerLinha(rotulo);
    if (texto.isEmpty) return DateTime.now();
    final data = DateTime.tryParse(texto);
    if (data == null) {
      print('Data inválida. Use o formato AAAA-MM-DD ou AAAA-MM-DD HH:MM.');
      return null;
    }
    return data;
  }

  void _pausar() {
    stdout.write('\nPressione Enter para voltar ao menu...');
    final linha = stdin.readLineSync();
    if (linha == null) {
      print('\nEntrada encerrada. Encerrando o sistema.');
      exit(0);
    }
  }

  double _arredondar(double valor) => (valor * 10).round() / 10;

  double _num(dynamic valor) => double.tryParse(valor.toString()) ?? 0.0;

  String _formatarData(dynamic valor) {
    if (valor == null) return '-';
    final data = valor is DateTime ? valor : DateTime.tryParse(valor.toString());
    if (data == null) return valor.toString();
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(data.day)}/${dois(data.month)}/${data.year} '
        '${dois(data.hour)}:${dois(data.minute)}';
  }
}
