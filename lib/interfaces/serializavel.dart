// Interface dos objetos que podem ser convertidos em mapa e em JSON.
abstract class Serializavel {
  // Monta um mapa com os dados do objeto.
  Map<String, dynamic> toMap();

  // Transforma o mapa em texto JSON.
  String toJson();
}
