BEGIN{
  OFS=FS;
}
{
  c1 = split($2, a, ",")
  c2 = split($3, b, "@en")
  ac = ""
  for (i=1; i<= length(a); i++) {
    key = a[i]
    if (!(key in map)) {
      map[key] = 0
    }
    nkey = key"_"map[key]
    map[key] = map[key] + 1
    key = nkey
    s = "\""key"\":"
    if ( b[i] != "," && b[i] != "" ) {
      gsub(/^,/,"", b[i])
      s = s b[i]
    } else {
      s = s "{}"
    }
    if ( i > 1 ) {
      ac = ac ","
    }
    ac = ac s
  }
  print $1,"related","{"ac"}"
}
