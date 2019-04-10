BEGIN{
  OFS=FS;
}
{
  label = ""
  name = ""
  c1 = split($2, a, ",");
  c2 = split($3, b, "@en");
  for (i in a) {
    gsub(/^\,/,"", b[i])
    if( a[i] == l) {
      if (label == ""){ label=b[i] }
      else { label=label ";" b[i]}
    }
    else if ( a[i] == n) {
      if (name == ""){ name=b[i] }
      else{ name=name ";" b[i]}
    }
  }
  gsub("\";\"",";",name);
  name = substr(name, 2, length(name)-2)
  name = gensub(/(\"|\\)/,"\\\\\\0", "g", name)
  gsub("\";\"",";",label);
  label = substr(label, 2, length(label)-2)
  label = gensub(/(\"|\\)/,"\\\\\\0", "g", label)
  print $1,"names","{\"label\":\""label"\",\"name\":\""name"\"}"
}
