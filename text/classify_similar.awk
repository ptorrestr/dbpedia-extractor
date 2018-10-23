{
  c=split($2,a,"/");
  ac=a[c];
  c2=split(ac,b,"#"); 
  if(c2>1) { 
    ac=b[2]
  }
  if ($2 == s || $2 == d || $2 == r ) {
    print $1"|"ac"|"$3
  }
}
