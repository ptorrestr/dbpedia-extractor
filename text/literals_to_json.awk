BEGIN{
  OFS=FS;
}
{
  c1 = split($2, a, ",");
  c2 = split($3, b, "@en");
  line = ""
  for (i in a) {
    key = a[i]
    if (!(key in map)) {
      map[key] = 0
    }
    nkey = key"_"map[key]
    map[key] = map[key] + 1
    key = nkey
    value = b[i]
    gsub(/^\,/,"", value)
    value = substr(value, 2, length(value)-2)
    gsub(/\\/,"\\\\", value);
    gsub("\"","\\\"", value);
    if (line != "") { line = line "," }
    line = line "\""key"\":\""value"\""
  }
  print $1,"attributes","{"line"}"
}
