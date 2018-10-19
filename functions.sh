
prefix="http://dbpedia.org/resource/"
label="http://www.w3.org/2000/01/rdf-schema#label"
name="http://xmlns.com/foaf/0.1/name"
category="http://purl.org/dc/terms/subject"
sameas="http://www.w3.org/2002/07/owl#sameAs"
disambiguates="http://dbpedia.org/ontology/wikiPageDisambiguates"
redirects="http://dbpedia.org/ontology/wikiPageRedirects"
res="results"

# Read queries from stdin and query the hdt_file with them. The queries are in
# the format of "a b c", where a b c can be any resource or ? to denote *. 
# Each query is contained in one line.
# The output is capturead and cleaned. URIs based on dbpedia.org are transformed
# to <dbpedia:*>.
#1: hdt_file
read_triples() {
  parallel --pipe -j1 --round-robin hdtSearch $1 \
    | awk -F ' ' -v r=$res '{
  if ($0 != ">> " && $3 != r && $2 != "Dictionary" && $2 != r) { 
    gsub(">> ", "", $0); print $0 
  }
}' \
    | awk -F ' ' '{
  f=$1; s=$2; $1="";
  $2="";
  gsub(/^[ \t]+/, "", $0);
  print f"|"s"|" $0 }' \
    | awk -F '|' -v p=$prefix '{
  gsub(p, "<dbpedia:", $1); 
  a = gsub(p, "<dbpedia:", $3);
  if ( a > 0) { $3 = $3 ">" }
  print $1">|"$2"|"$3
}'
}

# Get the name of the resources in the mapping format.
get_name() {
  cut -d '|' -f2 \
    | cut --complement -d ":" -f1 \
    | tr -d '>'
}

# Obtain any triple in hdtfile for the given mapping keys.
get_all() {
  get_name \
    | awk -v p=$prefix '{print p $0" ? ?"}' \
    | read_triples $hdtfile
}

# Capture labels in the triple stream.
proc_labels() {
  awk -F'|' -v l=$label -v n=$name '{if ($2 == l || $2 == n){ print $0 }}' 
}

# Parse labels to json format
parse_labels() {
  datamash -s -t '|' -g 1 collapse 2 collapse 3 \
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
  print $1"|names|{\"label\":\""label"\",\"name\":\""name"\"}"
}' 
}

# Capture literals in the triple stream
proc_literals() {
  awk -F'|' -v l=$label -v n=$name '{
  if ($3 !~ /^<dbpedia/ && $3 !~ /^http:/ && $2 !=l && $2 !=n ) { 
    print $0 } 
}' \
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

# Parse literals to json format
parse_literals(){
  datamash -s -t '|' -g 1 collapse 2 collapse 3 \
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
  print $1"|attributes|{"line"}"
}'
}

# Capture categories in triple stream
proc_categories() {
  awk -F"|" -v c=$category '{
  if ($2 == c){
    d=split($2,a,"/");
    ac=a[d];
    d2=split(ac,b,"#"); 
    if(d2>1) { 
      ac=b[2]
    }
    print $1"|"ac"|"$3
  }
}
' \
    | sort -t'|' -k 1
}

# Write in json format the result of datamash
split_datamash() {
  awk -F'|' '{
  c = split($2, a, "@en");
  b = ""
  for (i=1; i<= length(a); i++) {
    if ( a[i] != "," && a[i] != "" ) {
      b = b a[i]
    }
  }
  gsub(/^,/, "", b)
  print $1"|["b"]"
}'
}

# Parse categories in json format
parse_categories() {
  awk '{print $0"@en" }' \
    | datamash -s -t'|' -g 1 collapse 2 \
    | split_datamash \
    | awk -F'|' '{print $1"|categories|"$2}'
}

# Capture similar in the triple stream
proc_similar() {
  awk -F'|' -v d=$disambiguates -v r=$redirects -v s=$sameas '{
  c=split($2,a,"/");
  ac=a[c];
  c2=split(ac,b,"#"); 
  if(c2>1) { 
    ac=b[2]
  }
  if ($2 == s || $2 == d || $2 == r ) {
    print $1"|"ac"|"$3
  }
}'
}

# Parse similar in json format
parse_similar() {
  awk '{print $0"@en" }' \
    | datamash -s -t'|' -g 1 collapse 2 \
    | split_datamash \
    | awk -F'|' '{print $1"|similar|"$2}'
}

# Capture related in the triple stream
proc_related() {
  awk -F'|' -v c=$category -v s=$sameas -v r=$redirects -v d=$disambiguates 'BEGIN{
  m[c] = 1
  m[s] = 1
  m[r] = 1
  m[d] = 1
}
{
  if ($3 ~ /^<dbpedia/ && m[$2] != 1) {
    c=split($2,a,"/");
    ac=a[c];
    c2=split(ac,b,"#"); 
    if(c2>1) { 
      ac=b[2]
    }
    print $1"|"ac"|"$3
  }
}' \
    | sort -t'|' -k 1
}

# Parse related in json format
parse_related() {
  awk '{print $0"@en" }' \
    | datamash -s -t'|' -g 1 collapse 2 collapse 3 \
    | awk -F'|' '{
  c1 = split($2, a, ",")
  c2 = split($3, b, "@en")
  ac = ""
  for (i=1; i<= length(a); i++) {
    s = "\""a[i]"\":"
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
  print $1"|related|{"ac"}"
}'
}

# Build json document from the five fields: labels, literals, categories
# similar and related.
parse_document() {
  awk '{print $0"@en"}' \
    | datamash -s -t'|' -g 1 collapse 2 collapse 3 \
    | awk -F'|' '{
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
  ac = ac ",\"uri\":\"" $1 "\""
  print "{"ac"}"
}'   
}

# Flatten each categories into a single text
flatten_document() {
  jq '
  {
  name: (
    if .names == null then
      empty
    else
      if .names.label != "" then
        .names.label 
      else 
        .names.name 
      end
    end
  )
  ,attributes: (
    if .attributes != null then
      .attributes | flatten | join(" ")
    else
      ""
    end
  )
  ,categories: (
    if .categories != null then
      .categories 
        | to_entries 
        | map(.value.label) 
        | flatten 
        | join(", ") 
    else
      ""
    end
  )
  ,similar: (
    if .similar != null then
      .similar
    else
      ""
    end
  )
  ,related: (
    if .related != null then
      .related
        | with_entries(select(.value != {})) 
        | to_entries 
        | map(.key + " "+.value.label)
        | join(", ") 
    else
      ""
    end
  )
}
'
}
