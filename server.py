#!/usr/bin/env python3
"""
Simple HTTP server for Flutter web app
Serves the build/web directory with CORS headers
"""

import http.server
import socketserver
import os
import sys

PORT = 5060
DIRECTORY = "build/web"

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP request handler with CORS support"""
    
    def __init__(self, *args, directory=None, **kwargs):
        # Use the provided directory without changing cwd
        super().__init__(*args, directory=directory, **kwargs)
    
    def end_headers(self):
        """Add CORS headers to all responses"""
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()
    
    def do_OPTIONS(self):
        """Handle preflight OPTIONS requests"""
        self.send_response(200)
        self.end_headers()
    
    def log_message(self, format, *args):
        """Custom log format"""
        sys.stderr.write("%s - - [%s] %s\n" %
                         (self.address_string(),
                          self.log_date_time_string(),
                          format % args))


def main():
    """Start the HTTP server"""
    # Get absolute path to build/web directory
    abs_directory = os.path.abspath(DIRECTORY)
    
    # Check if build/web directory exists
    if not os.path.exists(abs_directory):
        print(f"❌ Error: Directory '{abs_directory}' does not exist!")
        print("💡 Run 'flutter build web' first")
        sys.exit(1)
    
    print(f"🚀 Starting SU TODERO server...")
    print(f"📁 Serving directory: {abs_directory}")
    print(f"🌐 Server running on http://0.0.0.0:{PORT}")
    print(f"✅ Ready to accept connections")
    print(f"🛑 Press Ctrl+C to stop")
    
    # Create handler with fixed directory
    handler = lambda *args, **kwargs: CORSRequestHandler(*args, directory=abs_directory, **kwargs)
    
    with socketserver.TCPServer(("0.0.0.0", PORT), handler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Server stopped by user")
            sys.exit(0)


if __name__ == "__main__":
    main()
