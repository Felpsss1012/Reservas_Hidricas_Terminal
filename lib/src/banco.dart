import 'dart:io';

import 'package:mysql_client/mysql_client.dart';

class ConexaoBanco {
  MySQLConnection? _conexao;

  String get host => Platform.environment['DB_HOST'] ?? '127.0.0.1';
  int get port => int.tryParse(Platform.environment['DB_PORT'] ?? '3306') ?? 3306;
  String get user => Platform.environment['DB_USER'] ?? 'root';
  String get senha => Platform.environment['DB_PASS'] ?? 'Felipe&Root#1012';
  String get database => Platform.environment['DB_NAME'] ?? 'reservas_hidricas';
  bool get secure =>
      (Platform.environment['DB_SECURE'] ?? 'false').toLowerCase() == 'true';

  Future<void> conectar() async {
    _conexao = await MySQLConnection.createConnection(
      host: host,
      port: port,
      userName: user,
      password: senha,
      secure: secure,
      databaseName: database,
    );
    await _conexao!.connect();
  }

  Future<IResultSet> executar(String consulta,
      {Map<String, dynamic>? parametros}) async {
    return _conexao!.execute(consulta, parametros);
  }

  Future<List<Map<String, dynamic>>> consultar(String consulta,
      {Map<String, dynamic>? parametros}) async {
    final resultado = await _conexao!.execute(consulta, parametros);
    return resultado.rows.map((linha) => linha.typedAssoc()).toList();
  }

  Future<T> transacao<T>(Future<T> Function(MySQLConnection conexao) acao) async {
    return _conexao!.transactional(acao);
  }

  Future<void> fechar() async {
    await _conexao?.close();
    _conexao = null;
  }

  bool get conectado => _conexao?.connected ?? false;
  MySQLConnection? get conexao => _conexao;
}
