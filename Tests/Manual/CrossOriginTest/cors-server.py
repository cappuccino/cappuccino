#!/usr/bin/env python3
from    http.server   import  BaseHTTPRequestHandler
from    http.server   import  HTTPServer
import  cgi
import  logging

logging.basicConfig(level=logging.INFO)
PORT = 8001
HOST = "localhost"

class ServerHandler(BaseHTTPRequestHandler):

    def end_headers(self):
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
        except KeyError as e:
            logging.info("CORS: No Credentials")

if __name__ == "__main__":
    httpd = HTTPServer((HOST, PORT), ServerHandler)
    print(f"Server started http://{HOST}:{PORT}")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass

    httpd.server_close()
    print(f"Server on http://{HOST}:{PORT} stopped.")