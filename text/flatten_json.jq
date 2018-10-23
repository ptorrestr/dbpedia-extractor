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
