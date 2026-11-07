"""Run the local TURN relay on its own (see app/signaling/local_relay.py).

Usually not needed: the backend starts the relay itself when
LOCAL_TURN_RELAY=true. Standalone use (the PC's LAN address must be reachable
from the phones):

    python scripts/local_turn_server.py --password some-secret [--public-ip 10.27.198.114]

then start the backend with TURN_URLS=turn:<ip>:3478?transport=udp,
turn:<ip>:3478?transport=tcp, TURN_USERNAME=smartclass and
TURN_CREDENTIAL=some-secret.
"""

import argparse
import asyncio
import logging
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from app.signaling.local_relay import lan_ip, serve  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description="Local TURN relay for Smart Class live classes")
    parser.add_argument("--public-ip", help="This PC's LAN address (default: detected)")
    parser.add_argument("--port", type=int, default=3478)
    parser.add_argument("--user", default="smartclass")
    parser.add_argument("--password", required=True)
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()
    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO, format="[turn] %(message)s")
    try:
        asyncio.run(serve(args.public_ip or lan_ip(), args.port, {args.user: args.password}))
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
