
prefix="http://dbpedia.org/resource/"
label="http://www.w3.org/2000/01/rdf-schema#label"
name="http://xmlns.com/foaf/0.1/name"
category="http://purl.org/dc/terms/subject"
sameas="http://www.w3.org/2002/07/owl#sameAs"
disambiguates="http://dbpedia.org/ontology/wikiPageDisambiguates"
redirects="http://dbpedia.org/ontology/wikiPageRedirects"
res="results"
proc="12"
proc2="4"
sep="|"
mem="1G"


# This program remove garbage from the output of hdtSearch
awk_prog='{
  if ($0 != ">> " && $3 != r && $2 != "Dictionary" && $2 != r) {
    gsub(">> ", "", $0);
    print $0
  } 
}
'

# This program trim white spaces and set '|' as the separator
awk_prog_2='{
  f=$1; s=$2; $1="";
  $2="";
  gsub(/^[ \t]+/, "", $0);
  print f"|"s"|" $0 
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

# Flatten each categories into a single text
flatten_document() {
  jq '
  def tokenise(a):
    [a 
      | match("([a-z]+|[A-Z][a-z]+)";"g")
      | .string ] 
    | join(" ")
  ;
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
        | map(tokenise(.key) + " "+.value.label)
        | join(", ") 
    else
      ""
    end
  )
}
'
}
