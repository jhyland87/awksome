#
# hello.awk
# usage:
# - gawk -f hello.awk
# - open up localhost:3001 in your browser
#

@include "src/awkserver.awk"

function hello()
{
    setResponseBody("Hello!")
}

function printeaanv()
{
    sendFile("printenv.txt")
}

function printenv()
{
  sendCmdStdout("printenv")
}

function timestamp()
{
  date_type = getRequestParam("format")
  setResponseBody(date_type)
}

function procs()
{
  javascript[1] = ""
  javascript[length(javascript)+1] = "console.debug(\"Page generated at %s\", new Date())"

  cols  = getRequestParam("cols", "pid,ppid,uid,user,%mem,%cpu,start,sess,comm")
  user  = getRequestParam("user")
  uid   = getRequestParam("uid")
  limit = getRequestParam("limit", 10)

  head_text = ""
  ps_cmd = "ps -o " cols

  if ( length(user) > 0 ){
    user = tolower(user)
    head_text = head_text " <h3>Processes for user " user "</h3>"
    ps_cmd = ps_cmd " -U " user
    javascript[length(javascript)+1] = "console.debug(\"Processes for user "user"\")"
  }
  else if ( length(uid) > 0 ){
    head_text = head_text " Processes for UID " uid
    ps_cmd = ps_cmd " -u " uid
    javascript[length(javascript)+1] = "console.debug(\"Processes for UID "uid"\")"
  }

  javascript[length(javascript)+1] = "console.debug(\"Full PS command: "ps_cmd"\")"

  rmEmpty( javascript )
  
  debug("[procs] command: " ps_cmd)
  proclist = getCmdStdout( ps_cmd )

  head_text = head_text "Command execution took "exec_time" seconds"

  if ( limit != "all" )
    proclist = strHead(proclist, limit)
  setResponseStatus("200 OK")
  setResponseHeader("Content-Type", "text/html")

  respBody = "<html><head><title>Processes</title></head><body>" \
                    head_text "</hr>" \
                    "<pre>" proclist "</pre>" 
                    
  if ( length(javascript) > 0 ){
    respBody = respBody"\n<script>"
    for ( js in javascript ){
      respBody = respBody"\n"javascript[js]";"
    }
    respBody = respBody"\n</script>"
  }

  respBody = respBody "</body></html>"

  setResponseBody(respBody)
  #sendCmdStdout("ps -o pid,ppid,uid,user,%mem,%cpu,start,sess,comm -U jhyland")
}

BEGIN {
    addRoute("GET", "/", "hello")   # route requests on "/" to the function "hello()"
    addRoute("GET", "/printenv", "printenv")   # route requests on "/" to the function "hello()"
    addRoute("GET", "/sessions", "w")   # route requests on "/" to the function "hello()"
    addRoute("GET", "/procs", "procs")   # route requests on "/" to the function "hello()"
    addRoute("GET", "/timestamp", "timestamp")   # route requests on "/" to the function "hello()"

    startAwkServer(3001)            # start listening. this function never exits
}