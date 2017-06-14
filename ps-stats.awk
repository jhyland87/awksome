#!/usr/local/bin/awk -f

# Todo:
#   skip empty rows
#   Look for duplicate pids
#   Validate data types in columns:
#     - pid   (int)
#     - ppid  (int)
#     - uid   (int)
#     - ruid  (int)
#     - user  (str)
#     - gid   (int)
#     - rgid  (int)
#     - %cpu  (float)
#     - %mem  (float)
#   Show ending summary with:
#     - sum cpu
#     - sum mem
#     - count user procs
#     - top N highest CPU/MEM/Time
# Monitor for multiple awk versions in PROCINFO


#ps -w -E -a -x -o logname,gid,rgid,uid,ruid,user,ruser
# ps -w -E -a -x -o pid,ppid,%cpu,cpu,%mem,uid,ruid,user,gid,rgid,state,time,sl,re,pagein,vsz,rss,lim,tsiz,command,args | ./ps-stats.awk
# ps -w -E -a -x -o pid=dip,ppid,%cpu,cpu,%mem,uid,ruid,user,gid,rgid,state,time,sl,re,pagein,vsz,rss,lim,tsiz,command,args| head | awk -f ./ps-stats.awk rename="baz:bang"
# awk 'BEGIN{ for (i = 0; i < ARGC; i++)  print ARGV[i] }' rename="foo:bar" rename="baz:bang"
# ps -w -h -E -a -x -o pid=dip,ppid,%cpu,cpu,%mem,uid,ruid,user,gid,rgid,state,time,sl,re,pagein,vsz,rss,lim,tsiz,command,args| awk -f ./ps-stats.awk colname="pid:dipd"
# ps -w -h -E -a -x -o pid=procid,ppid,%cpu,cpu,%mem,uid,ruid,user,gid,rgid,state,time,sl,re,pagein,vsz,rss,lim,tsiz,command,args| awk -f ./ps-stats.awk colname="pid:dipd:procid"

#@include "./utils.awk"
@include "/Users/jhyland/Documents/scripts/awk/utils.awk"

executable = ARGV[0]


function standardize_row( column_data ){
  column_data = tolower(column_data)
  gsub(/[[:space:]][[:space:]]+/, " ", column_data)
  gsub(/^[[:space:]]*/, "", column_data)
  gsub(/[[:space:]]*$/, "", column_data)

  #printf "column_data: \"%s\"\n", column_data
  return column_data
}

BEGIN {
  awk_version = 0

  if ( "version" in PROCINFO ){
    awk_version = PROCINFO["version"]
  }
  else if ( "mpfr_version" in PROCINFO ){
    awk_version = PROCINFO["mpfr_version"]
  }

  if ( awk_version == 0 ){
    print "idk what version"
  }
  else {
    printf("Awk Version: %s\n", awk_version)
  }

  users[""] = ""
  #columns[""] = ""
  colwidths["user"] = 5
  header_format = 0
  column_full = 0

  required_cols["userid"] = "user uid login logname ruser ruid"
  required_cols["pid"] = "pid"
  required_cols["cpu"] = "cpu %cpu"
  required_cols["mem"] = "mem %mem"
  #required_cols["idk"] = "foo bar"
  #required_cols["idka"] = "foo bar"

  arg_keys["colname"] = "colrename rename"

  # Iterate over the arguments...
  if ( ARGC > 1 ){
    for ( i = 0; i < ARGC; i++ ) {
      split( ARGV[i] , arg_keyval, "=", seps )
      # arg_keyval[1] = the argument key
      # arg_keyval[2] = the argument value

      #printf "ARG #%s; key: %s; val: %s\n", i, _arg_arr[1], _arg_arr[2]

      # If this arg is colname, then its value should be the overridden column 
      # title in a format like "pid:procid"
      if ( tolower( arg_keyval[1] ) == "colname" ){
        split( arg_keyval[2], col_rename, ":", seps )

        # Make sure the columns new name is also provided
        if ( length( col_rename ) == 1 ){
          _err( sprintf("The colname argument needs to also contain the new name for the column %s", col_rename[1] ) )
          exit 1
        }

        # Loop through the array, value #1 is the original name, anything
        # after that is another name
        for ( c in col_rename ){
          if ( c == 1 ){
            # Save the columns original name
            _col_rname = tolower( col_rename[1] )

            if ( ! ( _col_rname in required_cols ) )
              required_cols[ _col_rname ] = ""

            continue
          }
          
          required_cols[ _col_rname ] = required_cols[ _col_rname ]" "tolower( col_rename[c] )
        }

        #printf "The column %s will be named %s\n", col_rename[1], col_rename[2]

        #if ( tolower(col_rename[1]) in required_cols )
        #  required_cols[ tolower(col_rename[1]) ] = required_cols[ tolower(col_rename[1]) ]" "tolower(_col_change_arr[2])
        #else 
        #  equired_cols[ tolower(col_rename[1]) ] = tolower(col_rename[2])
        
      }
    }
  }

  if ( uid_col && length( uid_col ) > 0 ) {
    uid_col_priority = tolower( uid_col )
  }
  else {
    uid_col_priority = "user uid login logname ruser ruid"
  }

  split( uid_col_priority, uid_col_pri_arr, " ", seps )
}
{
  # The very first row should be the PS column headers. Iterate over that to create an array of column data
  if( NR == 1 ){
    # Iterate over the header row, saving what columns have what values
    for(i = 1; i <= NF; i++) {
      columns[tolower($i)]["pos"] = i
      columns[tolower($i)]["width"] = length($i)
    }

    header_format = standardize_row($0)

    #printf "column_full: \"%s\"\n", standardize_row($0)

    #req_cols_notfound[""]=""
    # Iterate over the required columns..
    for ( _reqcols in required_cols ){
      #printf "Reqcol %s ==========\n",tolower(_reqcols)
      #printf "arr2str(req_cols_notfound, ): %s\n",arr2str(req_cols_notfound, ",")
      #printf "length(req_cols_notfound): %s\n",length(req_cols_notfound)
      #printf "arrlen(req_cols_notfound): %s\n",arrlen(req_cols_notfound)
      #if ( req_cols_notfound && isarray( req_cols_notfound ) == 1 ){
      #if( 0 in req_cols_notfound ){

      #printf("Adding %s to req_cols_notfound\n",tolower(_reqcols))
      req_cols_notfound[tolower(_reqcols)] = tolower(_reqcols)
      #}
      #else {
      #  req_cols_notfound[0] = _reqcols
      #}
      # Add it to the unfound cols, then delete it when/if found
      #req_cols_notfound[(type_get(req_cols_notfound) == "array" ? arrlen(req_cols_notfound)+1 : 0)] = _reqcols

      # Create an array of possible header values for said column
      split( required_cols[tolower(_reqcols)], col_names, " ", seps )

      for ( _cname in col_names ){
        if ( tolower( col_names[_cname] ) in columns ){
          required_col_names[_reqcols] = tolower( col_names[_cname] )
          #printf("Deleting %s from req_cols_notfound\n",tolower(_reqcols))
          # Delete it from the unfound cols
          delete req_cols_notfound[tolower(_reqcols)] 
          break
        }
      }
    }
    
    if ( length(req_cols_notfound) > 0 ){
      #print "arrlen(req_cols_notfound):",arrlen(req_cols_notfound)
      #print "length(req_cols_notfound):",length(req_cols_notfound)
      #print "arrlen(required_cols):",arrlen(required_cols)
      #print "length(required_cols):",length(required_cols)
      _err( sprintf("It seems that %i of the %i required columns was not found: %s", length(req_cols_notfound), length(required_cols),  arr2str(req_cols_notfound, ",") ) )
      exit 1
    }

    if ( length(required_col_names) == 0 ){
      _err( "None of the required columns were found" )
      exit 1
    }

    if ( length(required_col_names) != length(required_cols) ){
      _err( "Not all required columns were found" )
      exit 1
    }
    # Verify that a PID column exists
    #if ( "pid" in columns == 0 ){
    #  _err( "No PID column found" )
    #  exit 1
    #}

    # Iterate over the acceptable UID column names, using the first match
    for ( idx in uid_col_pri_arr ){
      if ( tolower( uid_col_pri_arr[idx] ) in columns ){
        uid_col = tolower( uid_col_pri_arr[idx] )
        break
      }
    }

    # If no user ID column is found, exit
    if ( ! uid_col ){
      _err( "No UID column found" )
      exit 1
    }

    next
  }

  #printf("NR: %s; Data: %s\n", NR, standardize_row($0))
  #printf("%s: %s\n", "NR", NR)
  #printf("%s: %s\n", "header_format", header_format)
  #printf("%s: %s\n", "standardize_row($0)", standardize_row($0))
    if ( header_format == standardize_row($0) ){
      #printf "SKIPPING ROW %s\n",RN
      next
    }

  if ( $7 in users ){
    users[$7]["pids"][0] = $1
    users[$7]["cpu"] = users[$7]["cpu"]+$3
    users[$7]["mem"] = users[$7]["mem"]+$4
  }
  else {
    users[$7]["pids"][length(users[$7]["pids"])+1] = $1
    users[$7]["cpu"] = users[$7]["cpu"]+$3
    users[$7]["mem"] = users[$7]["mem"]+$4

  }
}
END {
  for( usr in users){
    if( ! usr ) continue
    printf("Username: %s\n\tProcs: %s\n\tCPU: %s\n\tMem: %s\n", usr, length(users[usr]), users[usr]["cpu"], users[usr]["mem"])
  }
}

