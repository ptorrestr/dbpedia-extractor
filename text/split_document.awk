BEGIN{
  OFS=FS;
}
{
  c1 = split($2, a, ",")
  c2 = split($3, b, "@en")
  ac = ""
  for (i=1; i<= length(a); i++) {
    s = "\""a[i]"\":"
    if ( b[i] != ",") {
      gsub(/^,/,"", b[i])
      s = s b[i]
    } else {
      s = s "{}"
    }
    if ( i > 1) {
      ac = ac ","
    }
    ac = ac s
  }
  print "{"ac"}"
}
