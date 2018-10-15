
prefix="http://dbpedia.org/resource/"
label="http://www.w3.org/2000/01/rdf-schema#label"
name="http://xmlns.com/foaf/0.1/name"
res="results"

# Queries are submitted in stdin
#1: hdt_file
read_triples() {
  parallel --pipe -j1 --round-robin hdtSearch $1 \
    | awk -F ' ' -v r=$res '{ if ($0 != ">> " && $3 != r && $2 != "Dictionary" && $2 != r) { gsub(">> ", "", $0); print $0 }}' \
    | awk -F ' ' '{f=$1; s=$2; $1=""; $2="";gsub(/^[ \t]+/, "", $0); print f"|"s"|" $0 }' \
    | awk -F '|' -v p=$prefix '{gsub(p, "<dbpedia:", $1); print $1">|"$2"|"$3}'
}

# Get name of the resource
get_name() {
  cut -d '|' -f2 \
    | cut --complement -d ":" -f1 \
    | tr -d '>'
}

# Get literals
get_literals() {
  get_name \
    | awk -v p=$prefix '{print p $0" ? ?"}' \
    | read_triples $1 \
    | awk -F'|' -v l=$label -v n=$name '{ if ($3 !~ /^http:/ && $2 !=l && $2 !=n ) { print $0 } }' \
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
}'
}

