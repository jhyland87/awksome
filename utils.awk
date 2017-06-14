#! /usr/local/bin/awk -f

function charcount(data){
  gsub(/[[:space:]]/, "", data)

  return length(data)
}

function awkversion(){
  for ( p in PROCINFO ){
    if ( index("version",tolower(p)) != 0 )
      return PROCINFO[p]
    #printf("PROCINFO[%s]: %s - idx: %s\n", p, PROCINFO[p], index("version",tolower(p)))
  }
}

# https://www.gnu.org/software/gawk/manual/html_node/Shell-Quoting.html#Shell-Quoting
function shell_quote(s,             # parameter
    SINGLE, QSINGLE, i, X, n, ret)  # locals
{
  if (s == "") return "\"\""

  SINGLE = "\x27"  # single quote
  QSINGLE = "\"\x27\""
    n = split(s, X, SINGLE)

    ret = SINGLE X[1] SINGLE
    for (i = 2; i <= n; i++)
        ret = ret QSINGLE SINGLE X[i] SINGLE

    return ret
}


function printdata(data, title){
  if( length(title) == 0) title = "printdata"

  fmt =  "["title"] %-20s : %s\n"

  printf( fmt, "type_get(data)", type_get(data) )
  printf( fmt, "isarray(data)", isarray(data) )

  if(isarray(data)){
    printf( fmt, "arrlen(data)", arrlen(data) )
    data_str = ""
    for( idx in data){
      data_str = sprintf("%s, %s", data_str, data[idx])
    }
    printf( fmt, "data_str", data_str )
  }
  printf( fmt, "length(data)", length(data) )
}

function arr2str(flds, seps, sortOrder,      sortedInPresent, sortedInValue, currIdx, prevIdx, idxCnt, outStr) {
 
  printdata(flds)

  if ( isarray(flds) != 1 ) return flds

    if ( "sorted_in" in PROCINFO ) {
        sortedInPresent = 1
        sortedInValue = PROCINFO["sorted_in"]
    }

    if ( sortOrder == "" ) {
        sortOrder = (sortedInPresent ? sortedInValue : "@ind_num_asc")
    }
    PROCINFO["sorted_in"] = sortOrder

    if ( isarray(seps) ) {
        # An array of separators.
        if ( sortOrder ~ /desc$/ ) {
            for (currIdx in flds) {
                outStr = outStr (currIdx in seps ? seps[currIdx] : "") flds[currIdx]
            }
        }

        for (currIdx in seps) {
            if ( !(currIdx in flds) ) {
                outStr = outStr seps[currIdx]
            }
        }

        if ( sortOrder !~ /desc$/ ) {
            for (currIdx in flds) {
                outStr = outStr flds[currIdx] (currIdx in seps ? seps[currIdx] : "")
            }
        }
    }
    else {
        # Fixed scalar separator.
        # We would use this if we could distinguish an unset variable arg from a missing arg:
        #    seps = (magic_argument_present_test == true ? seps : OFS)
        # but we cant so just use whatever value was passed in.
        for (currIdx in flds) {
            outStr = outStr (idxCnt++ ? seps : "") flds[currIdx]
        }
    }

    if ( sortedInPresent ) {
        PROCINFO["sorted_in"] = sortedInValue
    }
    else {
        delete PROCINFO["sorted_in"]
    }

    return outStr
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

function stripEmpty( arr ){
  for( a in arr ) {
    #printf "> [stripEmpty] arr[ %s ] = %s\n", a, arr[ a ]
    if( length( arr[ a ] ) == 0 ) {
      #printf "> [stripEmpty] Length of value i %s\n", a
      delete arr[ a ]
    }
  }
}

# Source: https://www.gnu.org/software/gawk/manual/html_node/Join-Function.html
function join( array, start, end, sep,  result, i ){
  if ( sep == "" )
    sep = " "
  else if ( sep == SUBSEP ) # magic value
    sep = ""
  
  result = array[ start ]

  for ( i = start + 1; i <= end; i++ )
    result = result sep array[ i ]

  return result
}

function bold( txt ){
  return sprintf("%s%s%s", "\033[1m", txt, "\033[0m" )
}

function underline( txt ){
  return sprintf("%s%s%s", "\033[4m", txt, "\033[0m" )
}

# 
# Examples:
#   printf("%s%s%s%s\n", ansi("f","red"), ansi("b","whi"), "TEST", ansi("off"))
#   print ansi("f","red") ansi("a","bold") ansi("a","underline") ansi("b","blu") "TEST" ansi("off")
function ansi( trait, desc ){
  _ansi[ "attrs" ][ "" ] = ""

  _ansi[ "tmpl" ][ "on" ]  = "\033[%sm"
  _ansi[ "tmpl" ][ "off" ] = "\033[0m"

  # Foreground Colors
  _ansi[ "fg" ][ "def" ] = 0
  _ansi[ "fg" ][ "bla" ] = 30 # Black
  _ansi[ "fg" ][ "red" ] = 31 # Red
  _ansi[ "fg" ][ "gre" ] = 32 # Green
  _ansi[ "fg" ][ "yel" ] = 33 # Yellow
  _ansi[ "fg" ][ "blu" ] = 34 # Blue
  _ansi[ "fg" ][ "mag" ] = 35 # Magenta
  _ansi[ "fg" ][ "cya" ] = 36 # Cyan
  _ansi[ "fg" ][ "whi" ] = 37 # White

  # Background Colors
  _ansi[ "bg" ][ "def" ] = 0
  _ansi[ "bg" ][ "bla" ] = 40 # Black
  _ansi[ "bg" ][ "red" ] = 41 # Red
  _ansi[ "bg" ][ "gre" ] = 42 # Green
  _ansi[ "bg" ][ "yel" ] = 43 # Yellow
  _ansi[ "bg" ][ "blu" ] = 44 # Blue
  _ansi[ "bg" ][ "mag" ] = 45 # Magenta
  _ansi[ "bg" ][ "cya" ] = 46 # Cyam
  _ansi[ "bg" ][ "whi" ] = 47 # White

  # Other Attributes
  _ansi[ "attr" ][ "def" ] = 0 # None
  _ansi[ "attr" ][ "non" ] = 0 # None
  _ansi[ "attr" ][ "bol" ] = 1 # Bold
  _ansi[ "attr" ][ "und" ] = 4 # Underscore
  _ansi[ "attr" ][ "bli" ] = 5 # Blink
  _ansi[ "attr" ][ "rev" ] = 7 # ReverseVideo
  _ansi[ "attr" ][ "con" ] = 8 # Concealed

  # If no trait is provided, then just return the ansi OFF thingy
  if ( ( ! trait || length( trait ) == 0 ) || trim(tolower(trait)) == "off" )
    return _ansi[ "tmpl" ][ "off" ]

  if ( match( tolower( trait ), /^b(g|ack)?/ ) )
    _trait = "bg"
  else if ( match( tolower( trait ), /^a(ttr)?/ ) )
    _trait = "attr"
  else 
    _trait = "fg"

  # Check if the trait selected is in the _ansi
  if ( ! ( _trait in _ansi ) )
    return 0
  
  if ( length( desc ) > 0 ){
    _desc = tolower( substr( desc, 1, 3 ) )

    # Veify the trait has this color/whatever
    if ( ! ( _desc in _ansi[ _trait ] ) )
      return 0
  }
  else {
    _desc = "def"
  }
 
  res = _ansi[ _trait ][ _desc ]

  # One last verification
  if ( length( res ) == 0 )
    return 0

  return sprintf( _ansi[ "tmpl" ][ "on" ], res )
}

#
# Examples:
#   highlight( "Foobar", "cya")
function highlight( txt, hlfg, hlbg, hlattr ){
  #color_code_tpl = "\033[1;%sm"
  #color_off = "\033[0m"

  _ansi[ "attrs" ][ "" ] = ""
  #ascii[ "fg" ]

  _ansi[ "tmpl" ][ "on" ]  = "\033[%sm"
  _ansi[ "tmpl" ][ "off" ] = "\033[0m"

  # Foreground Colors
  _ansi[ "fg" ][ "bla" ] = 30 # Black
  _ansi[ "fg" ][ "red" ] = 31 # Red
  _ansi[ "fg" ][ "gre" ] = 32 # Green
  _ansi[ "fg" ][ "yel" ] = 33 # Yellow
  _ansi[ "fg" ][ "blu" ] = 34 # Blue
  _ansi[ "fg" ][ "mag" ] = 35 # Magenta
  _ansi[ "fg" ][ "cya" ] = 36 # Cyan
  _ansi[ "fg" ][ "whi" ] = 37 # White

  # Background Colors
  _ansi[ "bg" ][ "bla" ] = 40 # Black
  _ansi[ "bg" ][ "red" ] = 41 # Red
  _ansi[ "bg" ][ "gre" ] = 42 # Green
  _ansi[ "bg" ][ "yel" ] = 43 # Yellow
  _ansi[ "bg" ][ "blu" ] = 44 # Blue
  _ansi[ "bg" ][ "mag" ] = 45 # Magenta
  _ansi[ "bg" ][ "cya" ] = 46 # Cyam
  _ansi[ "bg" ][ "whi" ] = 47 # White

  # Other Attributes
  _ansi[ "attr" ][ "non" ] = 0 # None
  _ansi[ "attr" ][ "bol" ] = 1 # Bold
  _ansi[ "attr" ][ "und" ] = 4 # Underscore
  _ansi[ "attr" ][ "bli" ] = 5 # Blink
  _ansi[ "attr" ][ "rev" ] = 7 # ReverseVideo
  _ansi[ "attr" ][ "con" ] = 8 # Concealed

  # Add the FOREGROUND color attribute, if set
  if ( length( hlfg ) > 0 ){
    if ( isInt( hlfg ) ){
      push( _ansi[ "attrs" ], hlfg )
    }
    else {
      _hlfg = substr( tolower( trim( hlfg ) ), 0, 3 )

      if ( _hlfg in _ansi[ "fg" ] ){
        push( _ansi[ "attrs" ], _ansi[ "fg" ][ _hlfg ] )
      }
      else {
        printf "Unable to find a color for %s (%s)\n", hlfg, _hlfg
        return 0
      }
    }

    #printf "Color code for %s: %s\n", fg, color_code
    #stripEmpty( _ansi[ "attrs" ] )

    #for ( a in _ansi[ "attrs" ] ) printf "attr %s: %s\n", a, _ansi[ "attrs" ][ a ]


    #color_ascii = sprintf( _ansi[ "tmpl" ][ "on" ], join( _ansi[ "attrs" ], 1, length(_ansi[ "attrs" ]), ";") )

    #printf "%s%s%s\n", color_ascii, txt, color_off
  }

  # Add the BACKGROUND color attribute, if set
  if ( length( hlbg ) > 0 ){
    if ( isInt( hlbg ) ){
      push( _ansi[ "attrs" ], hlbg )
    }
    else {
      _hlbg = substr( tolower( trim( hlbg ) ), 0, 3 )

      if ( _hlbg in _ansi[ "bg" ] ){
        push( _ansi[ "attrs" ], _ansi[ "bg" ][ _hlbg ] )
      }
      else {
        printf "Unable to find a color for %s (%s)\n", hlbg, _hlbg
        return 0
      }
    }
  }

  # Add the STYLE attribute, if set
  if ( length( hlattr ) > 0 ){
    if ( isInt( hlattr ) ){
      push( _ansi[ "attrs" ], hlattr )
    }
    else {
      _hlattr = tolower( trim( hlattr ) )
      _hlattr = tolower( _hlattr )
      _hlattr = substr( tolower( trim( hlattr ) ), 0, 3 )

      if ( _hlattr in _ansi[ "attr" ] ){
        push( _ansi[ "attrs" ], _ansi[ "attr" ][ _hlattr ] )
      }
      else {
        printf "Unable to find a color for %s (%s)\n", hlattr, _hlattr
        return 0
      }
    }
  }


    #printf "Color code for %s: %s\n", fg, color_code
    stripEmpty( _ansi[ "attrs" ] )

    #for ( a in _ansi[ "attrs" ] ) printf "attr %s: %s\n", a, _ansi[ "attrs" ][ a ]


    cl = sprintf( _ansi[ "tmpl" ][ "on" ], join( _ansi[ "attrs" ], 1, length(_ansi[ "attrs" ]), ";")  )

    return sprintf( "%s%s%s", cl, txt, _ansi[ "tmpl" ][ "off" ] )
return

    #color_ascii = sprintf( _ansi[ "tmpl" ][ "on" ], join( _ansi[ "attrs" ], 1, length(_ansi[ "attrs" ]), ";") )

    #printf "%s%s%s\n", color_ascii, txt, color_off

  

  stripEmpty( _ansi[ "attrs" ] )


  #hl[ "on" ]  = sprintf( "\033[1;%sm", color )
  #hl[ "off" ] = "\033[0m"
}


# Getopt
#
# @see https://www.gnu.org/software/gawk/manual/html_node/Getopt-Function.html
function getopt(argc, argv, options, thisopt, i){
  if ( length( options) == 0 )    # no options given
    return -1

  if ( argv[Optind] == "--" ) {  # all done
    Optind++
    _opti = 0
    return -1
  } 
  else if ( argv[Optind] !~ /^-[^:[:space:]]/ ) {
    _opti = 0
    return -1
  }

  if ( _opti == 0 )
    _opti = 2

  thisopt = substr( argv[Optind], _opti, 1 )
  Optopt = thisopt
  i = index(options, thisopt)

  if ( i == 0 ) {
    if ( Opterr )
      printf("%c -- invalid option\n", thisopt) > "/dev/stderr"

    if (_opti >= length(argv[Optind])) {
      Optind++
      _opti = 0
    } 
    else {
      _opti++
    }

    return "?"
  }

  if ( substr( options, i + 1, 1 ) == ":" ) {
    # get option argument
    if ( length( substr( argv[Optind], _opti + 1 ) ) > 0 )
      Optarg = substr(argv[Optind], _opti + 1)
    else
      Optarg = argv[++Optind]

    _opti = 0
    
  } 
  else {
    Optarg = ""
  }
    
  if ( _opti == 0 || _opti >= length( argv[Optind] ) ) {
    Optind++
    _opti = 0
  } 
  else {
    _opti++
  }
    
  return thisopt
}

# Functions to add:
#   arrSort :   Sort array by value in specific key or index
#   arrType :   Determine if an array is a scalar or hash array
#   parsedate : Function to parse a date provided (EG: ps -o etime)
#   ucwirds 
#   lcwords
#   remove multiple spaces
#   
function splitby ( data, char ){
  split(data, result, char, seps)

  data = result
  return 0
  print "wtf"
  if ( ! data ){
    _err( "No needle found" )
    return 1
  }

  if ( ! char ) char = " "

  #match( $1, /^(.+)\([0-9a-zA-Z]+\)$/, arr);
  match( data, char, arr )

  #if (  length( arr ) == 0 ) return 1
  #printf "data: %s\n", data
  #printf "char: %s\n", char
  #printf "length(arr): %s\n", length(arr)

  #for ( a in arr ) printf "%s: %s\n", a, arr[a]
  print "Returning:",length(data),"things"
  #return arr
  return 1
}

function abs( num ) { 
  return ( num > 0 ? num : -num ) 
}

function max( a, b ) { 
  return ( a > b ? a : b ) 
}

function min( a, b ) { 
  return ( a < b ? a : b ) 
}

# Function to check if a value (typically an entire line of a file) is either empty, or
# commented out (with a pound (#) symbol).
function containsData ( line ){
  return line !~ /^([[:space:]]*?|[[:space:]]*#.*?)$/
}

function arrlen ( arr ){
  if ( ! isarray( arr ) ) return 0

  for ( i in arr )
    return i
}

function getBiggest( arr ){
    return getSize( "b", arr )
}

function printKeyVal( key, val ){
    printf "%-15s: %s\n", key, val
}

function _ln ( var, val ){
  printf _fmt, var, val
}



function indexof( col, itm, noCase ){

  return 0
}

# Execute a system command, optionally specify what file descriptors to 
# use (stdout, stderr)
#
# @param    _cmd  string    command to execute
# @param    cd    number    int for FDs (1 = stdout, 2 = stderr, 12 = both) 
# Todo  Catch sterr
function exec( _cmd, fd ){
  fullcmd = sprintf( "{ %s ; } >&1", _cmd )
  fullcmd | getline result

  linecount = 0
  while ( ( _cmd | getline result ) > 0 ) {
    printf "%-1s | %s\n", linecount, result
    output[ linecount ] = result
    linecount++
  } 
  close(_cmd)
  printf "There were %s lines in total\n", length(output)
  return linecount
  #return join(output)
}

# Execute a system command
# 
# @param  _cmd  string    Command to execute
#
function syseval( _cmd, _retstat ){
  mod = _cmd " 2>/dev/null; echo \"$?\""

  while ( ( mod | getline line ) > 0 ) {
    if (numLines++){
      #print "got a line of text: " prev
      result = prev
    }
    prev = line
  }

  status = line
  close(mod)
  #printf "Status: %s\n", status

  if (status != 0) {
    if ( _retstat ) return status
    #print "ERROR: command '" _cmd "' failed" | "cat >&2"
    return 0
  }

  #print "command '" _cmd "' was successful"
  if ( _retstat )
    return status

  return result
}


# Debug message function
function _dbg( msg ){
  # Abort function if debug isnt enabled
  if ( ! debug ) return

  # If this is the first time the debug function has been called, display the header
  if ( ! hasDebugged ){
    hasDebugged = 1
    # Only display it if nohead hasn't been set to 1 (true)
    if ( nohead != 1 )
      printf "%-2s|%-10s|%-5s|%s\n", "D","SOURCE", "LINE","MSG"
  }

  # Debug lvl 1 message format
  if ( debug == 1 )
    printf "[D] LN: %s: %s\n", FNR, msg

  # Debug lvl 2 msg format
  if ( debug >= 2 ) # "%-2s|%-10s|%-5s|%s\n"
    printf "%-2s|%-10s|%-5s|%s\n", "D",FILENAME == "-" ? "STDIN" : FILENAME, FNR, msg
}

function _err( msg ){
  cmd = sprintf("echo \"[ERROR] %s\" 1>&2", msg)
  system( cmd ) 
}

function type_get(var, k, q, z ) {
  k = CONVFMT
  CONVFMT = "% g"

  if ( isarray( var ) ) 
    return "array"
  
  split( " " var "\34" var, z, "\34" )

  q = sprintf("%d%d%d%d%d", 
    var == 0, 
    var == z[1], 
    var == z[2],
    var "" == +var, 
    sprintf(CONVFMT, var) == sprintf(toupper(CONVFMT), var))
  
  CONVFMT = k
  
  if ( index( "01100 01101 11101", q ) )
    return "numeric string"
  
  if ( index( "00100 00101 00110 00111 10111", q ) )
    return "string"
  
  return "number"
}

function ucfirst( s ) {
  
  return toupper(substr(s, 1, 1)) tolower(substr(s, 2, length(s)-1))
}

# Function to skip to the next record if the current line is empty or commented out
function skipUseless(){
  if ( $0 ~ "^[[:space:]]*(#|;|$)" ) {
    _dbg("Line is empty or commented out - skipping")
    next 
  }
}

# If the line contains a comment after some real data, then remove the comment and
# re-define $0
function clearComment(){
  if ( length( cmtfmts ) == 0 )
    return

  if ( match( $0, /^([^#;].+)(#|;)/, m ) ) { 
    _dbg("\""$0"\" -> \""m[1]"\"")
    $0 = m[1] 
  }
}

# Tweak all items in a specified array
# Valid Actions:
#   - tolower   Converts each value to lower case
#               AKA: lower, lowercase, tolowercase, lower
#   - toupper   Converts each value to upper case
#               AKA: upper, uppercase, touppercase, upper
#   - ucfirst   Upper case the first letter of each value
#               AKA: uc, ucf, uppercasefirst uppercasef
#   - trim      Trims the empty spaces on both sides of each value
#   - rtrim     Trims the right side of the values
#   - ltrim     Trims the left side of the values
#   - strtonum  Executes the native strtonum() function
#   - flip      Switch the keys and values for every item
#   - fillkey   Update the keys to match the values
#   - fillval   Update the values to match the keys    
# Actions To Add:
#   - round up/down
#   - substr
#   - gsub(find, replace, str)
#   - pad values
#   - asort/asorti
#   awk '{a[$0]}END{asorti(a,b);for(i=1;i<=NR;i++)print b[i]}' f 
#   awk '{a[$0]}END{asorti(a,b,"@val_num_asc");for(i=1;i<=NR;i++)print b[i]}' f
#   http://stackoverflow.com/questions/22666799/sorting-numerically-with-awk-gawk
function tweakarray( arr, action, arg1, arg2 ){
  if ( length( arr ) == 0 || ! action )
    return

  # Standardize the action
  action = trim( tolower( action ) )

  # This determines if a case within the switch statement needs to break the 
  # parent for loop
  breakforloop = 0

  # Iterate over the array of data, using a switch statement to determine what
  # should happen to the data
  # Note: If something within the switch needs to abort the for loop, the 
  # breakforloop variable will be set to 0, and that should be checked right
  # after the switch statement at the end of the for loop (to prevent going 
  # to another iteration)
  for ( a in arr ){
    switch ( action ) {

      # execute gsub with provided data
      case /gsub/:
        if ( ! arg1 || ! arg2 ){
          dbg("Expecting two extra arguments for the action " action)
          breakforloop = 1
        }
        else {
          gsub( arg1, arg2, valarr[a])
        }
        break

      # Re-define the array keys to match the values
      case /fillkeys/:
        arr[ arr[a] ] = arr[a]
        delete arr[a]
        break

      # Re-define the array valuess to match the keys
      case /fillval(ue)?s/:
        arr[ a ] = a
        break

      # Switch key/valye
      case /(flip|swap)/:
        arr[ arr[a] ] = d
        delete arr[a]
        break

      # Upper case the FIRST letter
      case /u(pper)?c(ase)?(f(irst)?)/:
        dbg("Executing ucfirst(" arr[a] ") -> " ucfirst( arr[a] ))
        arr[a] = ucfirst( arr[a] )
        break

      # Lower case the entire string
      case /(to)?lower(case)?/:
        dbg("Executing tolower(" arr[a] ") -> " tolower( arr[a] ))
        arr[a] = tolower( arr[a] )
        break

      # Upper case the entire string
      case /(to)?upper(case)?/:
        dbg("Executing toupper(" arr[a] ") -> " toupper( arr[a] ))
        arr[a] = toupper( arr[a] )
        break

      # Trim both sides of the string
      case "trim":
        dbg("Executing trim(" arr[a] ") -> " trim( arr[a] ))
        arr[a] = trim( arr[a] )
        break

      # Trim the right side of the stirng
      case "rtrim":
        dbg("Executing rtrim(" arr[a] ") -> " rtrim( arr[a] ))
        arr[a] = rtrim( arr[a] )
        break

      # Trim the left side of the string
      case "ltrim":
        dbg("Executing ltrim(" arr[a] ") -> " ltrim( arr[a] ))
        arr[a] = ltrim( arr[a] )
        break

      # Convert any numerical strings to integers
      case "strtonum":
        dbg("Executing strtonum(" arr[a] ") -> " strtonum( arr[a] ))
        arr[a] = strtonum( arr[a] )
        break

      # Somebody made a boo boo
      default:
        dbg("Invalid action specified: " action " - leaving value unmodified -> " arr[a])
        # Abort the for loop
        breakforloop = 1
        break
    }

    # If one of the actions set the breakforloop to true, then abort the for loop
    if ( breakforloop == 1 ){
      dbg("Aborting for loop in tweakedarray on item #" d)
      break
    }
  }
}