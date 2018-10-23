{
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
