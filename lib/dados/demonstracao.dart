import 'package:reservas_hidricas/models/acionamento_bomba.dart';
import 'package:reservas_hidricas/models/anotacao_campo.dart';
import 'package:reservas_hidricas/models/dispositivo_broker.dart';
import 'package:reservas_hidricas/models/estacao_monitoramento.dart';
import 'package:reservas_hidricas/models/leitura_telemetria.dart';
import 'package:reservas_hidricas/models/registro_gasto.dart';
import 'package:reservas_hidricas/models/usuario.dart';

void executarDemonstracao() {
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

  for (final l in [
    LeituraTelemetria(
      dataHora: DateTime(2026, 8, 25, 8),
      nivelAguaPct: 74.3,
      umidadeSoloPct: 61.7,
      temperaturaCelsius: 24.9,
    ),
    LeituraTelemetria(
      dataHora: DateTime(2026, 8, 25, 18),
      nivelAguaPct: 94.6,
      umidadeSoloPct: 55.4,
      temperaturaCelsius: 22.9,
    ),
    LeituraTelemetria(
      dataHora: DateTime(2026, 8, 26, 4),
      nivelAguaPct: 83.8,
      umidadeSoloPct: 74.5,
      temperaturaCelsius: 36.2,
    ),
  ]) {
    alpha.registrarLeitura(l);
  }

  alpha.registrarAcionamento(AcionamentoBomba(
    dataHoraInicio: DateTime(2026, 8, 25, 6),
    dataHoraFim: DateTime(2026, 8, 25, 6, 20),
    modoAcionamento: 'Automático',
  ));
  alpha.registrarAcionamento(AcionamentoBomba(
    dataHoraInicio: DateTime(2026, 8, 25, 12),
    dataHoraFim: DateTime(2026, 8, 25, 12, 25),
    modoAcionamento: 'Automático',
  ));

  alpha.registrarGasto(RegistroGasto(
    descricao: 'Compra de Solução Nutritiva NPK + Micronutrientes',
    valor: 450,
    dataGasto: DateTime(2026, 8, 10),
    categoria: 'Insumos / Fertilizantes',
  ));
  alpha.registrarGasto(RegistroGasto(
    descricao: 'Compra de Filtro de Disco para Linha Principal',
    valor: 210,
    dataGasto: DateTime(2026, 8, 20),
    categoria: 'Infraestrutura Hídrica',
  ));

  alpha.registrarAnotacao(AnotacaoCampo(
    dataRegistro: DateTime(2026, 8, 25, 8, 30),
    titulo: 'Ajuste na Nutri-irrigação',
    texto: 'Aumentada a dosagem de potássio na fase de maturação.',
    autor: carlos,
  ));

  print('=== ${alpha.nome} ===');
  print('Brokers: ${alpha.brokers.join(', ')}');
  print('Média nível de água: ${alpha.mediaNivelAgua.toStringAsFixed(1)}%');
  print('Média umidade do solo: ${alpha.mediaUmidadeSolo.toStringAsFixed(1)}%');
  print('Média temperatura: ${alpha.mediaTemperatura.toStringAsFixed(1)} °C');
  print('Total gasto: R\$ ${alpha.totalGasto.toStringAsFixed(2)}');
  print('Gasto por categoria: ${alpha.gastoPorCategoria()}');
  print('Minutos de bomba ligada: ${alpha.minutosBombaLigada}');
  print('Leituras com alerta:');
  for (final l in alpha.leiturasComAlerta) {
    print('  ! $l');
  }
  print('Recomendação: ${alpha.recomendacaoIrrigacao}');
  print('Pode ser removida? ${alpha.podeSerRemovida}');
  print('Autenticação correta? ${carlos.autenticar('senhaForte123')}');

  print('\n=== Testes de validação ===');
  _testar(
    'Nível de água > 100%',
    () => LeituraTelemetria(
      dataHora: DateTime.now(),
      nivelAguaPct: 130,
      umidadeSoloPct: 50,
      temperaturaCelsius: 25,
    ),
  );
  _testar(
    'Gasto com valor zero',
    () => RegistroGasto(
      descricao: 'Teste',
      valor: 0,
      dataGasto: DateTime.now(),
      categoria: 'Teste',
    ),
  );
  _testar('E-mail inválido', () => carlos.email = 'carlos.silva');
  _testar(
    'IP de broker inválido',
    () => DispositivoBroker(ipBroker: '300.1.1.1'),
  );
  _testar(
    'Fim da bomba antes do início',
    () => AcionamentoBomba(
      dataHoraInicio: DateTime(2026, 8, 25, 10),
      dataHoraFim: DateTime(2026, 8, 25, 9),
      modoAcionamento: 'Manual',
    ),
  );
  _testar('Dois acionamentos em andamento', () {
    alpha.registrarAcionamento(AcionamentoBomba(
      dataHoraInicio: DateTime(2026, 8, 28, 6),
      modoAcionamento: 'Automático',
    ));
    alpha.registrarAcionamento(AcionamentoBomba(
      dataHoraInicio: DateTime(2026, 8, 28, 7),
      modoAcionamento: 'Manual',
    ));
  });
  _testar('Senha curta', () => carlos.alterarSenha('123'));
}

void _testar(String descricao, void Function() acao) {
  try {
    acao();
    print('[FALHOU] $descricao: nenhuma exceção lançada.');
  } catch (e) {
    print('[OK] $descricao -> $e');
  }
}
