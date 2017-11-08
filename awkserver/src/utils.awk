
function rmEmpty( arr ){
  for ( idx in arr ){
    if ( length(arr[idx]) == 0 )
      delete arr[idx]
  }
}

function isInt(val){ 
  return val ~ /^[0-9]+$/
}

function isFloat(val){ 
  return val ~ /^[0-9]*\.[0-9]+$/
}

function push( a, b ) { 
  a[ length( a ) ] = b 
}

# Trim left only
function ltrim( str ) {
  return trim( str, "l" )
}

# Trim right only
function rtrim( str ) {
  return trim( str, "r" )
}

# Trim left and right
function trim( str, side )  {
  # Trim if side is any of:
  #   - undefined
  #   - left (or just l)
  #   - both (or just b)
  if ( ! side || side ~ "^(l(eft)?|b(oth)?)$" )
    sub( /^[ \t\r\n]+/, "", str )
    
  # Trim if side is any of:
  #   - undefined
  #   - right (or just r)
  #   - both (or just b)
  if ( ! side || side ~ "^(r(ight)?|b(oth)?)$" )
    sub( /[ \t\r\n]+$/, "", str )

  return str
}

function stripEmpty( arr ){
  for( a in arr ) {
    #printf "> [stripEmpty] arr[ %s ] = %s\n", a, arr[ a ]
    if( length( arr[ a ] ) == 0 ) {
      #printf "> [stripEmpty] Length of value i %s\n", a
      delete arr[ a ]
    }
  }
}

function date_date(){
  return strftime("%Y-%m-%d")
}

function date_time(){
  return strftime("%H:%M:%S")
}

function date_timestamp(){
  return strftime("%Y-%m-%d %H:%M:%S")
}

function date_epoch(){
  return strftime("%s")
}

function strHead(string, limit){
  debug("[strHead limit: "limit"]")
  limit_ = (isInt(limit) ? limit : 10)
  split(string, lines, "\n")
  out=""

  for( line in lines ){ 
    out = out"\n"lines[line]
    if( line == limit_ ) break
  }
  return out 
}