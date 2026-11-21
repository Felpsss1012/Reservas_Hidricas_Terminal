class RegraDeNegocioException implements Exception {
  final String mensagem;

  RegraDeNegocioException(this.mensagem);

  @override
  String toString() => 'RegraDeNegocioException: $mensagem';
}
