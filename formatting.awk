#! /usr/local/bin/awk -f

# Need to fix this, as any special char for str will return true
#awk -v a="test" -v b="t" 'BEGIN { ptrn = sprintf( "%s$", b ); print "ptrn:",ptrn; printf "Answer: %s\n", match( a, ptrn) ? "A" : "B" }'
function endswith( str, word, noCase ){
  if ( ! str ){
    _err("No needle found")
    return 1
  }

  if ( ! word ){
    _err("No haystack found")
    return 1
  }

  if ( noCase ){
    if ( str ~ /[a-zA-Z]+$/ )
      str = tolower( str )

    if ( word ~ /[a-zA-Z]+$/ )
      word = tolower( word )
  }

  ptrn = sprintf( "%s$", str )

  return match( word, ptrn )
}

function endwith( str, char, nocase ){
  #return sprintf("%s%s", str, char)
  return endswith( char, str, nocase) ? str : sprintf("%s%s", str, char)
}

# Need to fix this, as any special char for str will return true
function startswith( str, word, noCase ){
  if ( ! str ){
    _err("No needle found")
    return 1
  }

  if ( ! word ){
    _err("No haystack found")
    return 1
  }

  if ( noCase ){
    str = tolower( str )
    word = tolower( word )
  }

  ptrn = sprintf( "^%s", str )

  return match( word, ptrn )
}

function startwith( str, char, nocase ){
  return startswith( char, str, nocase) ? str : sprintf("%s%s", char, str)
}

function startwithaa( str, char ){
  pos = length(char)
  first = substr(str, 0, pos)

  if ( first == char )
    return str

  return sprintf("%s%s", char, str)
}

# TODO - Add option to escape spaces and unescape quotes
function unquote( str, formatStr ){
  str = trim( str, "", "\"")

  if ( formatStr ){
    #gsub( /(^\"|\"$)/, "", str ) # Removes beginning/ending quotes
    gsub( / /, "\\ ", str )       # Escapes spaces
    gsub( /\t/, "\\\t", str )     # Escapes tabs
    gsub( /\\\"/, "\"", str ) 
  }

  return str
}

# TODO - Add option to escape quotes and un-escape spaces
function quote( str ){
  return trim( str, "", "\"")
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
function trim( str, side, extra ) {
  # Trim if side is any of:
  #   - undefined
  #   - left (or just l)
  #   - both (or just b)
  if ( ! side || side ~ "^(l(eft)?|b(oth)?)$" ){
    sub( /^[ \t\r\n]+/, "", str )
    if ( length( extra ) > 0 ){
      sub( "^"extra, "", str )
    }
  }
    
  # Trim if side is any of:
  #   - undefined
  #   - right (or just r)
  #   - both (or just b)
  if ( ! side || side ~ "^(r(ight)?|b(oth)?)$" ){
    sub( /[ \t\r\n]+$/, "", str )
    if ( length( extra ) > 0 ){
      sub( extra"$", "", str )
    }
  }

  return str
}