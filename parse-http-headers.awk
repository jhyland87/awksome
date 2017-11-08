#! /usr/local/bin/awk -f

# https://gist.github.com/jhyland87/95d88e9f32a77f8d6860f69c3332719d

function trim( str ) { 
  gsub( /([ \t\r\n]+$|^[ \t\r\n]+)/, "", str )
  return str
}

function simplify( str ){
  str = trim( str )
  str = tolower( str )
  gsub( /[^a-zA-Z0-9]/, "", str )
  return str
}

function printrow(){
  item_value = trim($2)

  if ( cfg_format ){
    if ( cfg_showkeys == 1 )
      printf( cfg_format, $1, $2 )
    else 
      printf( cfg_format, $2 )
    return
  }

  delimiters["single_quote"] = "\x27%s\x27"
  delimiters["double_quote"] = "\x22%s\x22"
  delimiters["ticks"] = "\x60%s\x60"
  delimiters["parenthesis"] = "\x28%s\x29"
  delimiters["default"] = "%s"


  val_fmt = ( cfg_quotes"_quote" in  delimiters ) ? 
    cfg_quotes"_quote" :
    "default"


  output_value = sprintf( delimiters[val_fmt], item_value )

  
  print ( cfg_showkeys == 1 ) ? 
    sprintf( "%s=%s", $1, output_value ) : 
    output_value
}

BEGIN {
  FS = ": "

  # If -v item=foo was defined, change item to itemS
  if ( item ) items = item
  else if ( ! items ) exit 1
  
  # Define the format config (Can be used to format output, passed to printf() directly)
  if ( format ) cfg_format = format

  # Define the quote config (Determines if the values should be quoted)
  if ( quotes == "single" || quotes == "double" )
    cfg_quotes = quotes 
  else if ( quotes == 1 )
    cfg_quotes = "double" 

  # Define the limit config (Determines how many lines to return)
  if ( limit == 0 || limit == "all" ) 
    cfg_limit = 0
  else if ( ! limit ) 
    cfg_limit = 1
  else  
    cfg_limit = int(limit)
  
  # Define the show keys config (Determines if the keys will be included in the results)
  cfg_showkeys = ( keys && keys != 0 ) ? 1 : 0

  split( items, item_arr, "," )

  # Declare/populate the header keys config (determines which vals to show)
  for( i = 0; i < length(item_arr); i++ ){
    if ( length(item_arr[i]) == 0 ) continue
    cfg_headers[ simplify(item_arr[i]) ] = item_arr[i]
  }
}
{
  # TODO Should I manually define a key for record #1 (HTTP response code)
  if ( NR == 1 ) next
  if ( ! $1 ) next

  if ( simplify($1) in cfg_headers ){
    results[$1] = $2
    printrow()

    # If limit is set, and the result count matches it, then exit
    if ( cfg_limit != 0 && length(results) == cfg_limit ) exit 0
  }
}
END {
  if ( ! length(results) ) exit 1
  
  exit 0
}