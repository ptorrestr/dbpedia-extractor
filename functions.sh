
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
# Also, it remove newlines if necessary.
# We cannot set OFS as it modifies $0 when printing output. We use variable 'se' to
# define the separator
awk_prog_1='
{
  if (FNR > 1)
  {
    if ( $1 !~ /^http:/ && $2 !~ /^http:/ )
    {
      t = t" "$0;
      next;
    }
    gsub(/^[[:blank:]]+/, "", t);
    gsub(/\|/, " ", t);
    print f se s se t
  }
  f=$1; s=$2; $1=""; $2="";
  t=$0;
}
END{
  gsub(/^[[:blank:]]+/, "", t);
  gsub(/\|/, " ", t);
  print f se s se t
}
'

# Make sure the input is composed by triples exclusively. Print to stderr what
# does not look like a triple.
awk_prog_2='{
  if (NF == 3) { print $0 }
  else { print $0 > "/dev/stderr" }
}'

# Tansform dbpedia urls to <dbpedia:xxx>
awk_prog_3='
BEGIN{
  OFS=s;
}
{
  gsub(p, "<dbpedia:", $1);
  a = gsub(p, "<dbpedia:", $3);
  if ( a > 0) { $3 = $3 ">" }
  print $1">",$2,$3
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
  cut -d "$sep" -f2 \
    | cut --complement -d ":" -f1 \
    | tr -d '>'
}

# add symbols to triples when extracting
awk_prog_6='
BEGIN{
  OFS=s;
}
{
  print "<"$1">","<"$2">","<"$3">"
}'
