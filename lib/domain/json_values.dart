Map<String, dynamic> jsonObject(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Objeto JSON inválido');
  }
  return value;
}

List<dynamic> jsonList(Object? value) {
  if (value is! List) throw const FormatException('Lista JSON inválida');
  return value;
}

String jsonString(Object? value) {
  if (value is! String || value.isEmpty) {
    throw const FormatException('Texto inválido');
  }
  return value;
}

int jsonInt(Object? value, {int? min}) {
  if (value is! int || (min != null && value < min)) {
    throw const FormatException('Inteiro inválido');
  }
  return value;
}

double jsonNumber(Object? value, {double? min, double? max}) {
  if (value is! num ||
      !value.isFinite ||
      (min != null && value < min) ||
      (max != null && value > max)) {
    throw const FormatException('Número fora do intervalo permitido');
  }
  return value.toDouble();
}

T jsonEnum<T extends Enum>(Object? value, List<T> values) {
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw const FormatException('Opção desconhecida');
}
