BEGIN{
  OFS=FS;
}
{
  c = split($2, a, "@en");
  b = ""
  for (i=1; i<= length(a); i++) {
    if ( a[i] != "," && a[i] != "" ) {
      b = b a[i]
    }
  }
  gsub(/^,/, "", b)
  print $1,t,"["b"]"
}
