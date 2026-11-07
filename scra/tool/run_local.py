"""Run Smart Class on this PC for testing with phones on the same network.

    python tool/run_local.py            (use the backend's virtualenv Python)

Starts, and stops together when this window is closed (or Ctrl+C):
  * a local TURN relay (backend/scripts/local_turn_server.py) on port 3478, so
    live-class audio/video works between this PC and phones even when they
    cannot connect directly;
  * the backend on port 8000 (all network interfaces), told to hand the relay
    to the app (TURN_URLS / TURN_USERNAME / TURN_CREDENTIAL);
  * the web app (build/web) on http://127.0.0.1:5500, opened in the browser.

Phones use the APK built with --dart-define=API_BASE_URL=http://<this PC's
LAN address>:8000; the address is printed at start-up.
"""

import argparse
import os
import secrets
import socket
import subprocess
import sys
import threading
import time
import urllib.request
import webbrowser
from functools import partial
from http.server import ThreadingHTTPServer
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from serve_web import Handler  # noqa: E402

APP_DIR = Path(__file__).resolve().parent.parent
REPO = APP_DIR.parent
BACKEND = REPO / "backend"
TURN_SCRIPT = BACKEND / "scripts" / "local_turn_server.py"


def lan_ip() -> str:
    """Address of the network interface used to reach other devices."""
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        try:
            s.connect(("8.8.8.8", 80))  # no packet is sent
            return s.getsockname()[0]
        except OSError:
            return "127.0.0.1"


def port_open(port: int, host: str = "127.0.0.1") -> bool:
    with socket.socket() as s:
        s.settimeout(0.5)
        return s.connect_ex((host, port)) == 0


def backend_healthy() -> bool:
    try:
        with urllib.request.urlopen("http://127.0.0.1:8000/health", timeout=2) as r:
            return r.status == 200
    except OSError:
        return False


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--ip", help="LAN address to announce (default: detected)")
    parser.add_argument("--web-port", type=int, default=5500)
    parser.add_argument("--no-browser", action="store_true")
    args = parser.parse_args()

    python = sys.executable
    web = APP_DIR / "build" / "web"
    if not (web / "index.html").exists():
        print(f"App files not found in {web}.\nBuild them first: flutter build web --release --no-web-resources-cdn")
        return 1
    if port_open(8000):
        print(
            "Port 8000 is already in use (a backend started separately?).\n"
            "Close it, then start Smart Class again: the backend must be started\n"
            "from here so live classes get the audio/video relay."
        )
        return 1

    ip = args.ip or lan_ip()
    password = secrets.token_urlsafe(12)
    children: list[subprocess.Popen] = []
    try:
        print(f"Starting the live-class relay (TURN) on {ip}:3478 ...")
        turn = subprocess.Popen(
            [python, str(TURN_SCRIPT), "--public-ip", ip, "--user", "smartclass", "--password", password]
        )
        children.append(turn)

        env = dict(os.environ)
        env["TURN_URLS"] = f"turn:{ip}:3478?transport=udp,turn:{ip}:3478?transport=tcp"
        env["TURN_USERNAME"] = "smartclass"
        env["TURN_CREDENTIAL"] = password
        print("Starting the backend on port 8000 ...")
        backend = subprocess.Popen(
            [python, "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"],
            cwd=BACKEND,
            env=env,
        )
        children.append(backend)
        for _ in range(60):
            if backend_healthy():
                break
            for child in children:
                if child.poll() is not None:
                    print("A service stopped with an error (see above). Is PostgreSQL running?")
                    return 1
            time.sleep(1)
        else:
            print("The backend did not start within 60 s.")
            return 1

        app_url = f"http://127.0.0.1:{args.web_port}/"
        server = ThreadingHTTPServer(("127.0.0.1", args.web_port), partial(Handler, directory=str(web)))
        threading.Thread(target=server.serve_forever, daemon=True).start()

        print()
        print(f"  PC app      : {app_url}")
        print(f"  Phone (APK) : must be built for http://{ip}:8000 and on the same Wi-Fi")
        print(f"  Check phone : open http://{ip}:8000/health in the phone's browser")
        print("  Close this window (or press Ctrl+C) to stop Smart Class.")
        print()
        if not args.no_browser:
            webbrowser.open(app_url)

        while all(child.poll() is None for child in children):
            time.sleep(1)
        print("A service stopped; shutting down.")
        return 1
    except KeyboardInterrupt:
        return 0
    finally:
        for child in children:
            if child.poll() is None:
                child.terminate()


if __name__ == "__main__":
    sys.exit(main())
