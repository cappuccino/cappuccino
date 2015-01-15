import SimpleHTTPServer
import SocketServer
import logging
import cgi

logging.basicConfig(level=logging.INFO)
PORT = 8001

class ServerHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):

    def end_headers (self):
        self.send_header('Set-Cookie', 'mycookie=cappuccino!')
        self.send_header('Access-Control-Allow-Origin', 'http://142.157.142.237:8000')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header("Access-Control-Allow-Headers", "X-Requested-With, If-Modified-Since, Cache-Control, Pragma")
        self.send_header('Access-Control-Allow-Credentials', 'true')
        SimpleHTTPServer.SimpleHTTPRequestHandler.end_headers(self)

    def do_OPTIONS(self):
        logging.info("OPTIONS Request")
        self.send_response(204, "No Content")
        self.send_header('Access-Control-Allow-Origin', 'http://142.157.142.237:8000')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header("Access-Control-Allow-Headers", "X-Requested-With, If-Modified-Since, Cache-Control, Pragma")
        self.send_header('Access-Control-Allow-Credentials', 'true')
        self.send_header("Access-Control-Max-Age", 10)
        self.send_header("content-length", 0)

    def do_GET(self):
        try:
            self.headers['Cookie']
            logging.info("CORS: With Credentials")
            logging.info(self.headers['Cookie'])
        except KeyError, e:
            logging.info("CORS: No Credentials")
        SimpleHTTPServer.SimpleHTTPRequestHandler.do_GET(self)

Handler = ServerHandler

SocketServer.TCPServer.allow_reuse_address = True
httpd = SocketServer.TCPServer(("0.0.0.0", PORT), Handler)

print "serving at port", PORT
httpd.serve_forever()