"""Run Smart Class on this PC for testing with phones on the same network.

    python tool/run_local.py            (use the backend's virtualenv Python)

Starts, and stops together when this window is closed (or Ctrl+C):
  * the backend on port 8000 (all network interfaces) with its built-in TURN
    relay (LOCAL_TURN_RELAY, port 3478), so live-class audio/video works
    between this PC and phones even when they cannot connect directly;
  * the web app (build/web) on http://127.0.0.1:5500, opened in the browser.

An older backend already running on port 8000 (e.g. started by hand with
uvicorn) is stopped first, so the phones always reach this one.

Phones use the APK built with --dart-define=API_BASE_URL=http://<this PC's
LAN address>:8000; the address is printed at start-up.
"""

import argparse
import os
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


_STOP_SERVER = r"""
$line = netstat -ano | Select-String '^\s*TCP\s+\S+:{port}\s+\S+:0\s+\S+\s+(\d+)' | Select-Object -First 1
if (-not $line) {{ exit 0 }}
$id = [int]$line.Matches[0].Groups[1].Value
$p = Get-CimInstance Win32_Process -Filter "ProcessId=$id"
if (-not $p -or $p.CommandLine -notmatch 'python|uvicorn') {{ Write-Output "OTHER $($p.Name)"; exit 0 }}
# uvicorn --reload runs a supervisor process: stop the topmost one (only
# through python/uvicorn processes, never the terminal that started them).
while ($true) {{
  $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$($p.ParentProcessId)"
  if ($parent -and $parent.Name -match '^(python|pythonw|uvicorn)\.exe$' -and $parent.CommandLine -match 'uvicorn') {{ $p = $parent }} else {{ break }}
}}
Write-Output "STOPPED $($p.CommandLine)"
taskkill /PID $p.ProcessId /T /F | Out-Null
"""


def stop_server_on(port: int) -> bool:
    """Stops a Python/uvicorn server listening on [port] (Windows). Returns
    False when the port is used by another kind of program."""
    if os.name != "nt":
        return False
    out = subprocess.run(
        ["powershell", "-NoProfile", "-Command", _STOP_SERVER.format(port=port)],
        capture_output=True,
        text=True,
    ).stdout.strip()
    if out.startswith("OTHER"):
        return False
    if out.startswith("STOPPED"):
        print(f"Stopped the backend that was already running on port {port}:\n  {out[8:].strip()}")
    for _ in range(20):
        if not port_open(port):
            return True
        time.sleep(0.5)
    return not port_open(port)


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
    if port_open(8000) and not stop_server_on(8000):
        print("Port 8000 is used by another program. Close it, then start Smart Class again.")
        return 1

    ip = args.ip or lan_ip()
    env = dict(os.environ)
    env["LOCAL_TURN_RELAY"] = "true"
    if args.ip:
        env["LOCAL_TURN_IP"] = args.ip  # otherwise the relay follows Wi-Fi changes
    print("Starting the backend (with the live-class relay) on port 8000 ...")
    backend = subprocess.Popen(
        [python, "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"],
        cwd=BACKEND,
        env=env,
    )
    try:
        for _ in range(60):
            if backend_healthy():
                break
            if backend.poll() is not None:
                print("The backend stopped with an error (see above). Is PostgreSQL running?")
                return 1
            time.sleep(1)
        else:
            print("The backend did not start within 60 s.")
            return 1

        app_url = f"http://127.0.0.1:{args.web_port}/"
        if port_open(args.web_port):
            print(f"Port {args.web_port} is in use; the app may already be open at {app_url}")
        else:
            server = ThreadingHTTPServer(("127.0.0.1", args.web_port), partial(Handler, directory=str(web)))
            threading.Thread(target=server.serve_forever, daemon=True).start()

        print()
        print(f"  PC app      : {app_url}")
        print(f"  Phone       : same Wi-Fi; in the app's sign-in screen tap 'Server' and enter {ip}:8000")
        print(f"  Check phone : open http://{ip}:8000/health in the phone's browser")
        print("  Close this window (or press Ctrl+C) to stop Smart Class.")
        print()
        if not args.no_browser:
            webbrowser.open(app_url)

        while backend.poll() is None:
            time.sleep(1)
        print("The backend stopped.")
        return 1
    except KeyboardInterrupt:
        return 0
    finally:
        if backend.poll() is None:
            backend.terminate()


if __name__ == "__main__":
    sys.exit(main())
