import http.server
import socketserver
import os

PORT = 5060
DIRECTORY = "build/web"

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header("Access-Control-Allow-Headers", "X-Requested-With, Content-Type")
        self.send_header('X-Frame-Options', 'ALLOWALL')
        self.send_header('Content-Security-Policy', "frame-ancestors *")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200, "ok")
        self.end_headers()

os.chdir(DIRECTORY)
print(f"Serving {DIRECTORY} on port {PORT}")

with socketserver.TCPServer(("", PORT), CORSRequestHandler) as httpd:
    print("Server started")
    httpd.serve_forever()
