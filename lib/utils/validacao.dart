String textoObrigatorio(String valor, String campo, int max) {
  final texto = valor.trim();
  if (texto.isEmpty) {
    throw ArgumentError('$campo é obrigatório (NOT NULL).');
  }
  if (texto.length > max) {
    throw ArgumentError('$campo deve ter no máximo $max caracteres.');
  }
  return texto;
}

double percentual(double valor, String campo) {
  if (valor.isNaN || valor < 0 || valor > 100) {
    throw ArgumentError('$campo deve estar entre 0 e 100%.');
  }
  return valor;
}
