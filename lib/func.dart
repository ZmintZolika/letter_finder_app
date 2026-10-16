//Valamelyik betű megegyezik-e az aktuálissal
bool isThisLetter(String? a, String? b, String? letter) =>
    a == letter || b == letter;

//Van-e a betűnek szomszédja (ha van olyan ami nem szerepel a Set-ben ami tárolja a felfordított betűket és szomszédos)
bool isHaveNextLetter(String a, Set<String> list) {
  int aCode = a.codeUnitAt(0);
  Set<int> codeList = {};

  list.forEach((i) => codeList.add(i.codeUnitAt(0)));

  if (a == 'A') return !codeList.contains(aCode + 1);
  if (a == 'Z') return !codeList.contains(aCode - 1);
  return !codeList.contains(aCode - 1) || !codeList.contains(aCode + 1);
}
