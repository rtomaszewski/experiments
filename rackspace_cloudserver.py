
import getopt
import sys
import httplib
from pprint import pprint
from pprint import pformat
import json
import re
import time

DEBUG=0
PROGRAM_NAME="rackspace_cloudserver.py"

##http://docs.rackspace.com/auth/api/v1.1/auth-client-devguide/content/List_Versions-d1e232.html
#endpoints=[ 
#   "https://lon.identity.api.rackspacecloud.com",
#   "https://identity.api.rackspacecloud.com"
#]


#http://docs.rackspace.com/servers/api/v1.0/cs-devguide/content/Authentication-d1e506.html
endpoints=[
           ("lon.auth.api.rackspacecloud.com", "/v1.0"),
           (    "auth.api.rackspacecloud.com", "/v1.0")
]

ENDPOINT=()

COUNT=0
DEFAULT_CLOUD_SERVER={
    "server" : {
        "name" : "cstest",
        "imageId" : 112,
        "flavorId" : 1
    }
}

def get_debug():
    return DEBUG

def log(message):
    print message 

def debug(message):
    if DEBUG>0:
        log("debug[%2d]: " % DEBUG + message)

def usage(message=None):
    if message is not None: 
        print message
    
    print """
    usage: %s [-v] [-h] [-c file] -u user -k key run | help
      -h - usage help 
      -v - verbose/debug output
      -c - specify the file name with the json specification what cloud server should be created
      -u 
      -k 
      
      args:
        help - displays info about this program
        run - run this program
      
      defaults:

        # json specification used to create a cloud sever if no -c option is specified  
        {
            "server" : {
                "name" : "mytest",
                "imageId" : 112,
                "flavorId" : 1,
                "metadata" : {
                    "key1" : "value1"
                }
            }
        }
      
      example:
         todo
       
""" % PROGRAM_NAME 

def debug_http_connection(e,method, index, body, headers ):
    if DEBUG!=1:
        return 
    
    debug("http request");
    log("  "+e + " " + method + " " + index)
    log("  headers: ")
    for hname, hvalue in headers.items():
        log("    " + hname + ": " + hvalue)
    if body: 
        log("body:")
        log("   "+body)
    

def debug_http_response(res):
    if DEBUG!=1:
        return
    
    debug("http response");
    log("  "+str(res.status) + " " + res.reason )
    log("  headers")
    for hname, hvalue in res.getheaders():
        log("    " + hname + ": " + hvalue)
    
    #", ".join( map (str, res.getheaders() ) ) )

def debug_paylaod(payload):
    if DEBUG!=1:
        return
    
    l=len(payload)
    debug("read " + str(l) + " from the server:")
    
    if l!=0 :
        log(payload)
        

def autenticate(user, key):
    for (e, index ) in endpoints:
        conn=httplib.HTTPSConnection(e)
        
        headers={ "X-Auth-User": user, 
                  "X-Auth-Key" : key     }
        method="GET"
        body=""
        
        debug_http_connection(e,method, index, body, headers )
        conn.request(method, index,body, headers)
        
        res = conn.getresponse()
        debug_http_response(res)
        
        payload= res.read()
        debug_paylaod(payload)
        
        conn.close()
        
        if res.status > 200:
            ENDPOINT=(e, index)
            return res
        
    return None

def get_token(res):
    if res is None:
        return
    
    return res.getheader("x-auth-token")

def get_server_mgmt_url(res):
    if res is None:
        return
    
    return res.getheader("x-server-management-url")

#curl --verbose -d @create-cloud.txt 
#   -H "Content-Type: application/json" 
#   -H "X-Auth-Token: a2772b...9de" 
# https://lon.servers.api.rackspacecloud.com/v1.0/10001641/servers | json_xs -t dump
 
def create_cloud_server (token, mgmt_url, nr, cs=DEFAULT_CLOUD_SERVER):
    (tmp , e, index)=re.search("(https://)([^/]*)(/.*)", mgmt_url).groups()
    conn=httplib.HTTPSConnection(e)
    
    headers={ "X-Auth-Token" : token,
              "Content-Type" : "application/json" } 
    method="POST"
    body=cs
    cs_name=body['server']['name'] + str(nr)
    body['server']['name']=cs_name
    index=index + "/servers"
    
    log("creating new cloud server with a name: " + cs_name )
    
    debug_http_connection(e, method, index, json.dumps(body), headers )
    conn.request(method, index, json.dumps(body), headers)
        
    res = conn.getresponse()
    debug_http_response(res)
        
    payload= res.read()
    tmp=json.dumps(json.loads(payload), indent=1)
    
    if DEBUG:
        debug_paylaod(tmp)
    else:
        log(tmp)
        
    conn.close()


def main(): 
    debug("main start")
    debug(sys.argv[0])
    
    optlist, args = getopt.getopt(sys.argv[1:], 'vu:k:')
    
    debug("options: " + ', '.join( map(str,optlist) ) ) 
    debug("arguments: " + ", ".join(args ))
    
    user, key = None, None
    
    for o, val in optlist:
        if o == "-v":
            global DEBUG; 
            DEBUG = 1
        elif o == "-h":
            usage()
            sys.exit()
        elif o =="-u":
            user=val
        elif o =="-k":
            key=val
        else:
            assert False, "unhandled option"
            
    debug("user: <" + str(user) + "> key: <" + str(key) + ">")

    if len(args) == 0: 
        usage("missing arguments")
        sys.exit()    
    if args[0] == "help":
        usage("displaying help")
        sys.exit()    
    elif args[0] is None: 
        usage("missing argument")
        sys.exit()
    elif args[0] == "run" and user is not None and key is not None:
        res=autenticate(user, key)
        
        if not res :
            log("can't authenticate, try using -v")
            usage("")
            sys.exit()
        
        token=get_token(res)
        mgmt_url=get_server_mgmt_url(res)
        create_cloud_server(token, mgmt_url, int(time.time()))
        
    else:
        usage("unrecognized arguments")
        sys.exit()
    
    

if __name__ == '__main__': 
    main()
        