bplist00�_WebMainResource�	
_WebResourceData_WebResourceMIMEType_WebResourceTextEncodingName_WebResourceFrameName^WebResourceURLO
<html><head></head><body><pre style="word-wrap: break-word; white-space: pre-wrap;">#MySQL
mysql = require 'mysql'

#CWLogger
log = require 'cwsyslog'

#Config
config = require './config.json'

#Flag
closing = false ; retryTimer = null

#Max
max_conn = config.max_conn ; max_fail = config.max_fail

#Interval for FailSafe Mode
retryInterval = config.retryInterval

#Count
fail_count = 0

#Connection Pool
conns = []

#Automatic Initialization
init = ()-&gt;
    log.notice 'Initializing MYSQL Pool...'
    for i in [1..max_conn]
        log.info "Creating MYSQL Connection #{i}/#{max_conn}"
        tmp = mysql.createConnection config
        keepconn tmp
        tmp.connect()
        conns[i-1] = tmp

#Shutdown
close = ()-&gt;
    closing = true
    clearInterval retryTimer if retryTimer?
    log.alert 'CWMySQL is Shutting Down'
    for conn in conns
        try
            conn.end() if conn.state is not 'disconnected'
        catch ex
            log.error ex
    log.close()


#Keep Connection
keepconn = (conn)-&gt;
    conn.on 'error',resume
    conn.on 'end',resume
    conn.on 'connection',()-&gt;
        log.info 'A New MySQL Connection Established'
        fail_count = 0
        if retryTimer?
            log.notice 'CWMySQL Failsafe Mode Exited'
            clearInterval retryTimer
            retryTimer = null

#Resume Function
resume = (err)-&gt;
    return if closing or retryTimer?
    log.error err if err?
    log.error 'MySQL Connection Failure Captured'
    fail_count++
    if fail_count &gt; max_fail then dofailsafe() else doresume()

#DoResume Function
doresume = ()-&gt;
    conns.forEach (conn,i)-&gt;
        if conn.state is 'disconnected'
            log.notice 'Resuming a MySQL Connection'
            tmp = mysql.createConnection config
            keepconn tmp
            tmp.connect()
            conns[i] = tmp

#DoResume With Reload
doresumeWR=()-&gt;
    cfgfilename = require.resolve './config.json'
    delete require.cache[cfgfilename]
    config=require './config.json'
    doresume()

#Faisafe Mode
dofailsafe = ()-&gt;
    log.emerg '***[Node.js API Server] MySQL Module Failed***'
    retryTimer = setInterval doresumeWR,retryInterval

#The Connection to Provide
_r = 0

r = ()-&gt;
    if _r is max_conn-1
        _r=0
    else
        _r++
    _r

#Provide a connection
module.exports = ()-&gt;
    conns[r()]

#Provide a connection by Property
Object.defineProperty module.exports,'conn',
    get:()-&gt;
        conns[r()]

#Provide a close method
module.exports.shutdown=close

init()
</pre></body></html>_text/coffescriptUUTF-8P_chttps://git.colorwork.com/nodejs/cwmysql/blob/b574cceea8ad9f43edc47df39459ad2f4fbbb6ff/index.coffee    ( : P n � �
�
�
�
�                           