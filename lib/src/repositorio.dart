import 'package:reservas_hidricas/src/banco.dart';
import 'package:reservas_hidricas/models/anotacao_campo.dart';
import 'package:reservas_hidricas/models/leitura_telemetria.dart';
import 'package:reservas_hidricas/models/registro_gasto.dart';

class Repositorio {
  final ConexaoBanco _banco;

  Repositorio(this._banco);

  Future<List<Map<String, dynamic>>> listarEstacoes() async {
    return _banco.consultar(
      'SELECT idEstacao, nome, localizacao FROM Estacao_Monitoramento ORDER BY nome',
    );
  }

  Future<Map<String, dynamic>?> buscarEstacao(int idEstacao) async {
    final linhas = await _banco.consultar(
      'SELECT idEstacao, nome, localizacao FROM Estacao_Monitoramento WHERE idEstacao = :id',
      parametros: {'id': idEstacao},
    );
    return linhas.isEmpty ? null : linhas.first;
  }

  Future<List<Map<String, dynamic>>> listarLeituras(
      int idEstacao, {bool somenteAlertas = false, int limite = 100}) async {
    if (somenteAlertas) {
      return _banco.consultar(
        '''
        SELECT idLeitura, dataHora, nivelAguaPct, umidadeSoloPct, temperaturaCelsius, statusMensagem
        FROM Leitura_Telemetria
        WHERE idEstacao = :id AND (nivelAguaPct < 20 OR temperaturaCelsius > 35 OR statusMensagem <> 'OK')
        ORDER BY dataHora DESC
        LIMIT :limite
        ''',
        parametros: {'id': idEstacao, 'limite': limite},
      );
    }
    return _banco.consultar(
      '''
      SELECT idLeitura, dataHora, nivelAguaPct, umidadeSoloPct, temperaturaCelsius, statusMensagem
      FROM Leitura_Telemetria
      WHERE idEstacao = :id
      ORDER BY dataHora DESC
      LIMIT :limite
      ''',
      parametros: {'id': idEstacao, 'limite': limite},
    );
  }

  Future<Map<String, dynamic>?> mediasEstacao(int idEstacao) async {
    final linhas = await _banco.consultar(
      '''
      SELECT
        AVG(nivelAguaPct) AS mediaNivel,
        AVG(umidadeSoloPct) AS mediaUmidade,
        AVG(temperaturaCelsius) AS mediaTemperatura,
        COUNT(*) AS total
      FROM Leitura_Telemetria
      WHERE idEstacao = :id
      ''',
      parametros: {'id': idEstacao},
    );
    return linhas.isEmpty ? null : linhas.first;
  }

  Future<List<Map<String, dynamic>>> listarGastos(int idEstacao) async {
    return _banco.consultar(
      '''
      SELECT idGasto, descricao, valor, dataGasto, categoria
      FROM Registro_Gasto
      WHERE idEstacao = :id
      ORDER BY dataGasto DESC
      ''',
      parametros: {'id': idEstacao},
    );
  }

  Future<double?> totalGastos(int idEstacao) async {
    final linhas = await _banco.consultar(
      'SELECT SUM(valor) AS total FROM Registro_Gasto WHERE idEstacao = :id',
      parametros: {'id': idEstacao},
    );
    if (linhas.isEmpty) return null;
    final valor = linhas.first['total'];
    return valor == null ? null : double.tryParse(valor.toString());
  }

  Future<List<Map<String, dynamic>>> gastosPorCategoria(int idEstacao) async {
    return _banco.consultar(
      '''
      SELECT categoria, SUM(valor) AS total
      FROM Registro_Gasto
      WHERE idEstacao = :id
      GROUP BY categoria
      ORDER BY total DESC
      ''',
      parametros: {'id': idEstacao},
    );
  }

  Future<List<Map<String, dynamic>>> listarAcionamentos(int idEstacao) async {
    return _banco.consultar(
      '''
      SELECT idAcionamento, dataHoraInicio, dataHoraFim, modoAcionamento,
        TIMESTAMPDIFF(MINUTE, dataHoraInicio, COALESCE(dataHoraFim, NOW())) AS minutos
      FROM Acionamento_Bomba
      WHERE idEstacao = :id
      ORDER BY dataHoraInicio DESC
      ''',
      parametros: {'id': idEstacao},
    );
  }

  Future<int?> totalMinutosBomba(int idEstacao) async {
    final linhas = await _banco.consultar(
      '''
      SELECT SUM(TIMESTAMPDIFF(MINUTE, dataHoraInicio, COALESCE(dataHoraFim, NOW()))) AS total
      FROM Acionamento_Bomba
      WHERE idEstacao = :id
      ''',
      parametros: {'id': idEstacao},
    );
    if (linhas.isEmpty) return null;
    final valor = linhas.first['total'];
    return valor == null ? null : int.tryParse(valor.toString());
  }

  Future<List<Map<String, dynamic>>> listarAnotacoes(int idEstacao) async {
    return _banco.consultar(
      '''
      SELECT a.idAnotacao, a.dataRegistro, a.titulo, a.texto,
             u.idUsuario, u.nome AS autorNome, u.cargo AS autorCargo
      FROM anotacao_campo a
      JOIN usuario u ON a.idUsuario = u.idUsuario
      WHERE a.idEstacao = :id
      ORDER BY a.dataRegistro DESC
      ''',
      parametros: {'id': idEstacao},
    );
  }

  Future<Map<String, dynamic>?> ultimaLeitura(int idEstacao) async {
    final linhas = await _banco.consultar(
      '''
      SELECT nivelAguaPct, umidadeSoloPct, temperaturaCelsius, statusMensagem
      FROM Leitura_Telemetria
      WHERE idEstacao = :id
      ORDER BY dataHora DESC
      LIMIT 1
      ''',
      parametros: {'id': idEstacao},
    );
    return linhas.isEmpty ? null : linhas.first;
  }

  Future<bool> podeRemoverEstacao(int idEstacao) async {
    final tabelas = [
      'Leitura_Telemetria',
      'Acionamento_Bomba',
      'Registro_Gasto',
      'anotacao_campo',
      'Dispositivo_Broker',
    ];
    for (final tabela in tabelas) {
      final coluna = tabela == 'Dispositivo_Broker' ? 'idEstacao' : 'idEstacao';
      final linhas = await _banco.consultar(
        'SELECT COUNT(*) AS total FROM $tabela WHERE $coluna = :id',
        parametros: {'id': idEstacao},
      );
      final total = int.tryParse(linhas.first['total'].toString()) ?? 0;
      if (total > 0) return false;
    }
    return true;
  }

  Future<List<Map<String, dynamic>>> listarUsuarios() async {
    return _banco.consultar(
      'SELECT idUsuario, nome, email, cargo FROM usuario ORDER BY nome',
    );
  }

  Future<int> inserirLeitura(LeituraTelemetria leitura, int idEstacao) async {
    final resultado = await _banco.executar(
      '''
      INSERT INTO Leitura_Telemetria (dataHora, nivelAguaPct, umidadeSoloPct, temperaturaCelsius, statusMensagem, idEstacao)
      VALUES (:dataHora, :nivelAgua, :umidadeSolo, :temperatura, :status, :idEstacao)
      ''',
      parametros: {
        'dataHora': leitura.dataHora.toIso8601String(),
        'nivelAgua': leitura.nivelAguaPct,
        'umidadeSolo': leitura.umidadeSoloPct,
        'temperatura': leitura.temperaturaCelsius,
        'status': leitura.statusMensagem,
        'idEstacao': idEstacao,
      },
    );
    return resultado.lastInsertID.toInt();
  }

  Future<int> inserirGasto(RegistroGasto gasto, int idEstacao) async {
    final resultado = await _banco.executar(
      '''
      INSERT INTO Registro_Gasto (descricao, valor, dataGasto, categoria, idEstacao)
      VALUES (:descricao, :valor, :dataGasto, :categoria, :idEstacao)
      ''',
      parametros: {
        'descricao': gasto.descricao,
        'valor': gasto.valor,
        'dataGasto': gasto.dataGasto.toIso8601String(),
        'categoria': gasto.categoria,
        'idEstacao': idEstacao,
      },
    );
    return resultado.lastInsertID.toInt();
  }

  Future<int> inserirAnotacao(AnotacaoCampo anotacao, int idEstacao) async {
    final resultado = await _banco.executar(
      '''
      INSERT INTO anotacao_campo (dataRegistro, titulo, texto, idEstacao, idUsuario)
      VALUES (:dataRegistro, :titulo, :texto, :idEstacao, :idUsuario)
      ''',
      parametros: {
        'dataRegistro': anotacao.dataRegistro.toIso8601String(),
        'titulo': anotacao.titulo,
        'texto': anotacao.texto,
        'idEstacao': idEstacao,
        'idUsuario': anotacao.autor.idUsuario,
      },
    );
    return resultado.lastInsertID.toInt();
  }

  Future<Map<String, dynamic>> contagensTabelas() async {
    final tabelas = [
      'usuario',
      'Estacao_Monitoramento',
      'Dispositivo_Broker',
      'Componente',
      'Leitura_Telemetria',
      'Acionamento_Bomba',
      'Registro_Gasto',
      'anotacao_campo',
    ];
    final resultado = <String, dynamic>{};
    for (final tabela in tabelas) {
      final linhas = await _banco.consultar('SELECT COUNT(*) AS total FROM $tabela');
      resultado[tabela] = int.tryParse(linhas.first['total'].toString()) ?? 0;
    }
    return resultado;
  }
}
