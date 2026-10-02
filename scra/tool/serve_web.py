"""Serve the Flutter web build for local testing - fast.

    python tool/serve_web.py [--port 8080] [--host 127.0.0.1] [--dir build/web]

Compared with `python -m http.server`: gzip-compresses text files (the 3-4 MB
main.dart.js shrinks to ~1 MB) and answers unchanged files with
"304 Not Modified", so reloads don't download the app again. Serves several
requests at once. For deployment use a real web server / static hosting.
"""

import argparse
import gzip
import mimetypes
import os
from functools import partial
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

COMPRESSIBLE = {".js", ".mjs", ".wasm", ".json", ".html", ".css", ".svg", ".txt", ".map", ".symbols"}
mimetypes.add_type("application/wasm", ".wasm")
mimetypes.add_type("text/javascript", ".js")
mimetypes.add_type("text/javascript", ".mjs")

_gzip_cache: dict[tuple[str, float], bytes] = {}


class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # Always revalidate (file names are not content-hashed), but reuse the
        # browser's copy when unchanged (ETag / 304).
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def do_GET(self):
        path = self.translate_path(self.path)
        if os.path.isdir(path):
            path = os.path.join(path, "index.html")
        ext = os.path.splitext(path)[1].lower()
        if not os.path.isfile(path):
            return super().do_GET()

        stat = os.stat(path)
        etag = f'"{int(stat.st_mtime)}-{stat.st_size}"'
        if self.headers.get("If-None-Match") == etag:
            self.send_response(HTTPStatus.NOT_MODIFIED)
            self.send_header("ETag", etag)
            self.end_headers()
            return

        gzip_ok = ext in COMPRESSIBLE and "gzip" in self.headers.get("Accept-Encoding", "")
        if gzip_ok:
            key = (path, stat.st_mtime)
            body = _gzip_cache.get(key)
            if body is None:
                with open(path, "rb") as f:
                    body = gzip.compress(f.read(), compresslevel=6)
                _gzip_cache[key] = body
        else:
            with open(path, "rb") as f:
                body = f.read()

        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", mimetypes.guess_type(path)[0] or "application/octet-stream")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("ETag", etag)
        if gzip_ok:
            self.send_header("Content-Encoding", "gzip")
            self.send_header("Vary", "Accept-Encoding")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):  # quiet console
        pass


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--dir", default=os.path.join(os.path.dirname(__file__), "..", "build", "web"))
    args = parser.parse_args()
    directory = os.path.abspath(args.dir)
    server = ThreadingHTTPServer((args.host, args.port), partial(Handler, directory=directory))
    print(f"Serving {directory} on http://{args.host}:{args.port}")
    server.serve_forever()


if __name__ == "__main__":
    main()
