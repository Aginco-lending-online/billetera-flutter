/// Género esperado por [billetera-widget] en query `genero`: una letra M / F / O.
enum BilleteraGenero {
  masculino('M'),
  femenino('F'),
  otro('O');

  const BilleteraGenero(this.queryLetter);
  final String queryLetter;
}

String normalizeGeneroToQuery(Object genero) {
  if (genero is BilleteraGenero) {
    return genero.queryLetter;
  }
  final s = genero.toString().trim().toLowerCase();
  if (s.length == 1) {
    switch (s) {
      case 'm':
        return 'M';
      case 'f':
        return 'F';
      case 'o':
        return 'O';
    }
  }
  if (s.contains('mascul')) return 'M';
  if (s.contains('femen')) return 'F';
  if (s == 'otro' || s.contains('otro')) return 'O';
  throw ArgumentError.value(
    genero,
    'genero',
    'Usá BilleteraGenero o una letra M, F u O (o texto Masculino/Femenino/Otro).',
  );
}
