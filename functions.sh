
prefix="http://dbpedia.org/resource/"
label="http://www.w3.org/2000/01/rdf-schema#label"
name="http://xmlns.com/foaf/0.1/name"
category="http://purl.org/dc/terms/subject"
sameas="http://www.w3.org/2002/07/owl#sameAs"
disambiguates="http://dbpedia.org/ontology/wikiPageDisambiguates"
redirects="http://dbpedia.org/ontology/wikiPageRedirects"
proc="12"
proc2="4"
sep="|"
mem="1G"


# This program trim white spaces, remves '|' from objects and set '|' as the separator
awk_prog_1='{
  f=$1; s=$2; $1="";  $2="";
  gsub(/^[ \t]+/, "", $0);
  gsub(/\|/, " ", $0);
  print f"|"s"|" $0 
}'

# Make sure the input is composed by triples exclusively. Print to stderr what
# does not look like a triple.
awk_prog_2='{
  if (NF == 3) { print $0 }
  else { print $0 > "/dev/stderr" }
}'

# Tansform dbpedia urls to <dbpedia:xxx>
awk_prog_3='{
  gsub(p, "<dbpedia:", $1); 
  a = gsub(p, "<dbpedia:", $3);
  if ( a > 0) { $3 = $3 ">" }
  print $1">|"$2"|"$3
}'

# Capture labels in the triple stream.
awk_prog_4='{
  if ($2 == l || $2 == n){ 
    print $0 
  }
}'

# Add @en at the end of the line
awk_prog_5='{
  print $0"@en"
}'

# Get the name of the resources in the mapping format.
get_name() {
  cut -d '|' -f2 \
    | cut --complement -d ":" -f1 \
    | tr -d '>'
}
