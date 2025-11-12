#!/usr/bin/env python3
import http.server
import socketserver

PORT = 5060

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('X-Frame-Options', 'ALLOWALL')
        self.send_header('Content-Security-Policy', 'frame-ancestors *')
        super().end_headers()

if __name__ == '__main__':
    with socketserver.TCPServer(('0.0.0.0', PORT), CORSRequestHandler) as httpd:
        print(f"✓ Servidor CORS iniciado en puerto {PORT}")
        print(f"🌐 Accede a: http://0.0.0.0:{PORT}")
        httpd.serve_forever()
