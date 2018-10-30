{
  c1 = split($2, a, ",");
  c2 = split($3, b, "@en");
  line = ""
  for (i in a) {
    value = b[i]
    gsub(/^\,/,"", value)
    value = substr(value, 2, length(value)-2)
		gsub(/\\/,"\\\\", value);
    gsub("\"","\\\"", value);
    if (line != "") { line = line "," }
    line = line "\""a[i]"\":\""value"\""
  }
  print $1"|attributes|{"line"}"
}
