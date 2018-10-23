{
  if ($3 !~ /^<dbpedia/ && $3 !~ /^http:/ && $2 !=l && $2 !=n ) { 
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
  }
}
