BEGIN{
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
}
