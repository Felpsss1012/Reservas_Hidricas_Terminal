import 'package:reservas_hidricas/menu/menu_interativo.dart';
import 'package:reservas_hidricas/src/banco.dart';
import 'package:reservas_hidricas/src/repositorio.dart';

Future<void> main() async {
  final banco = ConexaoBanco();
  try {
    await banco.conectar();
  } on Exception catch (_) {
    print('Erro ao conectar ao banco de dados: verifique se o MySQL está rodando e se as credenciais estão corretas.');
    return;
  }
  try {
    final repositorio = Repositorio(banco);
    await MenuInterativo(repositorio: repositorio).executar();
  } finally {
    await banco.fechar();
  }
}
