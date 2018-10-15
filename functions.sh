
prefix="http://dbpedia.org/resource/"
label="http://www.w3.org/2000/01/rdf-schema#label"
name="http://xmlns.com/foaf/0.1/name"
category="http://purl.org/dc/terms/subject"
res="results"

# Queries are submitted in stdin
#1: hdt_file
read_triples() {
  parallel --pipe -j1 --round-robin hdtSearch $1 \
    | awk -F ' ' -v r=$res '{ if ($0 != ">> " && $3 != r && $2 != "Dictionary" && $2 != r) { gsub(">> ", "", $0); print $0 }}' \
    | awk -F ' ' '{f=$1; s=$2; $1=""; $2="";gsub(/^[ \t]+/, "", $0); print f"|"s"|" $0 }' \
    | awk -F '|' -v p=$prefix '{gsub(p, "<dbpedia:", $1); gsub(p, "<dbpedia:", $3); print $1">|"$2"|"$3">"}'
}

# Get name of the resource
get_name() {
  cut -d '|' -f2 \
    | cut --complement -d ":" -f1 \
    | tr -d '>'
}

# Get all triples
get_all() {
  get_name \
    | awk -v p=$prefix '{print p $0" ? ?"}' \
    | read_triples $hdtfile
}

# Get labels
proc_labels() {
  awk -F'|' -v l=$label -v n=$name '{if ($2 == l || $2 == n){ print $0 }}' \
    | datamash -t '|' -g 1 collapse 2 collapse 3 \
    | awk -F"|" -v l=$label -v n=$name '{
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
  gsub("\"","\\\"", name);
  gsub("\";\"",";",label);
  label = substr(label, 2, length(label)-2)
  gsub("\"","\\\"", label);
  print "label|"$1"|{\"label\":\""label"\",\"name\":\""name"\"}"
}' 
}

# Get literals
proc_literals() {
  awk -F'|' -v l=$label -v n=$name '{ if ($3 !~ /^http:/ && $2 !=l && $2 !=n ) { print $0 } }' \
    | awk -F'|' '{
  c=split($2,a,"/");
  ac=a[c];
  c2=split(ac,d,"#"); 
  if(c2>1) { 
    ac=d[2]
  }
  split($3, b,"^");
  val = b[1]
  c3 = split(b[1],e,"@en")
  if(c3==1) {
    val = b[1]"@en"
  }
  print $1"|"ac"|"val
}' \
    | datamash -t '|' -g 1 collapse 2 collapse 3 \
    | awk -F"|" '{
  c1 = split($2, a, ",");
  c2 = split($3, b, "@en");
  line = ""
  for (i in a) {
    value = b[i]
    gsub(/^\,/,"", value)
    value = substr(value, 2, length(value)-2)
    gsub("\"","\\\"", value);
    if (line != "") { line = line "," }
    line = line "\""a[i]"\":\""value"\""
  }
  print $1"|{"line"}"
}'
}

proc_categories() {
  awk -F"|" -v c=$category 'BEGIN{
  s=0
}
{
  if ($1=="label") {
    m[$2] = $3
  }
  if ($2==c){
    m2[s] = $1"|"$3
    s++;
  }
}
END {
  for (i in m2) {
    split(m2[i], a, "|")
    print a[2]"|"m[a[2]]
  }
}
'
}
