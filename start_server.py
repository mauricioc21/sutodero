import http.server
import socketserver
import os

PORT = 5060

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('X-Frame-Options', 'ALLOWALL')
        self.send_header('Content-Security-Policy', "frame-ancestors *")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

# Ensure we are serving the correct directory
web_dir = os.path.join(os.getcwd(), 'build/web')
if os.path.exists(web_dir):
    os.chdir(web_dir)
    print(f"Serving content from {web_dir}")
else:
    print(f"Warning: build/web not found in {os.getcwd()}, serving current directory")

Handler = CORSRequestHandler

with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
    print(f"Serving at port {PORT}")
    httpd.serve_forever()
