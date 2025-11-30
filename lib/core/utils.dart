String ismiGizle(String tamIsim) {
  if (tamIsim.isEmpty) return "Anonim";
  List<String> parcalar = tamIsim.trim().split(' ');
  if (parcalar.length < 2) return tamIsim;
  return "${parcalar[0]} ${parcalar[1][0]}.";
}
