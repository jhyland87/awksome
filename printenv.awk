#! /usr/local/bin/awk -f

BEGIN { 
  max_key_width = 15

  while ( ( "printenv" | getline data ) > 0 ) {
    split(data, var, /=/)

    envdata[ var[1] ] = var[2]

    if ( length(var[1]) > max_key_width )
      max_key_width = length(var[1])
  } 

  fmt = "\033[1;36m%-"(max_key_width+3)"s\033[0m : \033[1m%s\033[0m\n"

  for( k in envdata )
    printf(fmt, k, envdata[k])
}