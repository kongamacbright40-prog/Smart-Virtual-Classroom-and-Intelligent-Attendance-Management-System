"""Minimal TURN relay for testing live classes on a local network.

Live-class audio/video goes directly between devices (WebRTC). When two
devices cannot reach each other directly (browser privacy addresses, some
Wi-Fi networks, different networks) media only flows through a TURN relay.
In production use a TURN provider (Metered, Cloudflare, see README). This is
a small, dependency-free TURN server (RFC 5766 over UDP and TCP) so a phone
and a PC on the same network can be tested without one.

The backend starts it by itself when LOCAL_TURN_RELAY=true (see main.py), or
run it alone with ``python scripts/local_turn_server.py``.
"""

from __future__ import annotations

import asyncio
import hashlib
import hmac
import logging
import os
import struct
import time
import zlib

log = logging.getLogger("local_turn")

MAGIC_COOKIE = 0x2112A442
FINGERPRINT_XOR = 0x5354554E

# Methods (RFC 5389 / RFC 5766).
BINDING = 0x001
ALLOCATE = 0x003
REFRESH = 0x004
SEND = 0x006
DATA = 0x007
CREATE_PERMISSION = 0x008
CHANNEL_BIND = 0x009

# Classes.
REQUEST = 0
INDICATION = 1
SUCCESS = 2
ERROR = 3

# Attributes.
USERNAME = 0x0006
MESSAGE_INTEGRITY = 0x0008
ERROR_CODE = 0x0009
CHANNEL_NUMBER = 0x000C
LIFETIME = 0x000D
XOR_PEER_ADDRESS = 0x0012
DATA_ATTR = 0x0013
REALM = 0x0014
NONCE = 0x0015
XOR_RELAYED_ADDRESS = 0x0016
REQUESTED_TRANSPORT = 0x0019
XOR_MAPPED_ADDRESS = 0x0020
SOFTWARE = 0x8022
FINGERPRINT = 0x8028

UDP_PROTOCOL = 17
DEFAULT_LIFETIME = 600
MAX_LIFETIME = 3600
PERMISSION_LIFETIME = 300
CHANNEL_LIFETIME = 600

Address = tuple[str, int]


# --------------------------------------------------------------------------
# STUN encoding
# --------------------------------------------------------------------------


def message_type(method: int, cls: int) -> int:
    return (
        (method & 0x000F)
        | ((method & 0x0070) << 1)
        | ((method & 0x0F80) << 2)
        | ((cls & 0x1) << 4)
        | ((cls & 0x2) << 7)
    )


def split_type(value: int) -> tuple[int, int]:
    method = (value & 0x000F) | ((value & 0x00E0) >> 1) | ((value & 0x3E00) >> 2)
    cls = ((value & 0x0010) >> 4) | ((value & 0x0100) >> 7)
    return method, cls


def _pad(length: int) -> int:
    return (4 - length % 4) % 4


def encode_xor_address(addr: Address, transaction_id: bytes) -> bytes:
    host, port = addr
    packed = bytes(int(part) for part in host.split("."))
    xport = port ^ (MAGIC_COOKIE >> 16)
    xaddr = bytes(a ^ b for a, b in zip(packed, struct.pack("!I", MAGIC_COOKIE)))
    return struct.pack("!BBH", 0, 0x01, xport) + xaddr


def decode_xor_address(value: bytes) -> Address | None:
    if len(value) < 8 or value[1] != 0x01:  # IPv4 only
        return None
    port = struct.unpack("!H", value[2:4])[0] ^ (MAGIC_COOKIE >> 16)
    host = ".".join(str(a ^ b) for a, b in zip(value[4:8], struct.pack("!I", MAGIC_COOKIE)))
    return host, port


class Message:
    def __init__(self, method: int, cls: int, transaction_id: bytes) -> None:
        self.method = method
        self.cls = cls
        self.transaction_id = transaction_id
        self.attributes: list[tuple[int, bytes]] = []
        # Raw bytes and attribute offsets, kept for integrity checks.
        self.raw = b""
        self.offsets: dict[int, int] = {}

    def get(self, attr_type: int) -> bytes | None:
        for t, v in self.attributes:
            if t == attr_type:
                return v
        return None

    def get_all(self, attr_type: int) -> list[bytes]:
        return [v for t, v in self.attributes if t == attr_type]

    def add(self, attr_type: int, value: bytes) -> "Message":
        self.attributes.append((attr_type, value))
        return self

    def encode(self, integrity_key: bytes | None = None, fingerprint: bool = True) -> bytes:
        body = b"".join(
            struct.pack("!HH", t, len(v)) + v + b"\x00" * _pad(len(v)) for t, v in self.attributes
        )
        header_type = message_type(self.method, self.cls)

        def header(length: int) -> bytes:
            return struct.pack("!HHI", header_type, length, MAGIC_COOKIE) + self.transaction_id

        if integrity_key is not None:
            # Length covers the MESSAGE-INTEGRITY attribute (24 bytes).
            mac = hmac.new(integrity_key, header(len(body) + 24) + body, hashlib.sha1).digest()
            body += struct.pack("!HH", MESSAGE_INTEGRITY, 20) + mac
        if fingerprint:
            crc = zlib.crc32(header(len(body) + 8) + body) ^ FINGERPRINT_XOR
            body += struct.pack("!HHI", FINGERPRINT, 4, crc & 0xFFFFFFFF)
        return header(len(body)) + body


def parse_message(data: bytes) -> Message | None:
    if len(data) < 20 or data[0] & 0xC0:
        return None
    msg_type, length, cookie = struct.unpack("!HHI", data[:8])
    if cookie != MAGIC_COOKIE or len(data) < 20 + length:
        return None
    method, cls = split_type(msg_type)
    message = Message(method, cls, data[8:20])
    message.raw = data[: 20 + length]
    pos = 20
    end = 20 + length
    while pos + 4 <= end:
        attr_type, attr_len = struct.unpack("!HH", data[pos : pos + 4])
        value = data[pos + 4 : pos + 4 + attr_len]
        message.offsets.setdefault(attr_type, pos)
        message.attributes.append((attr_type, value))
        pos += 4 + attr_len + _pad(attr_len)
    return message


def check_integrity(message: Message, key: bytes) -> bool:
    offset = message.offsets.get(MESSAGE_INTEGRITY)
    value = message.get(MESSAGE_INTEGRITY)
    if offset is None or value is None or len(value) != 20:
        return False
    raw = message.raw
    # Header length as if MESSAGE-INTEGRITY were the last attribute.
    adjusted = struct.pack("!H", offset + 24 - 20)
    signed = raw[:2] + adjusted + raw[4:offset]
    expected = hmac.new(key, signed, hashlib.sha1).digest()
    return hmac.compare_digest(expected, value)


def is_channel_data(data: bytes) -> bool:
    return len(data) >= 4 and (data[0] & 0xC0) == 0x40


# --------------------------------------------------------------------------
# TURN server
# --------------------------------------------------------------------------


class Allocation(asyncio.DatagramProtocol):
    """Relay socket for one client."""

    def __init__(self, server: "TurnServer", client: "ClientLink", username: str, lifetime: int) -> None:
        self.server = server
        self.client = client
        self.username = username
        self.expires = time.monotonic() + lifetime
        self.permissions: dict[str, float] = {}  # peer IP -> expiry
        self.channel_to_peer: dict[int, Address] = {}
        self.peer_to_channel: dict[Address, int] = {}
        self.transport: asyncio.DatagramTransport | None = None
        self.relay_port = 0

    def connection_made(self, transport: asyncio.BaseTransport) -> None:
        self.transport = transport  # type: ignore[assignment]
        self.relay_port = transport.get_extra_info("sockname")[1]

    def datagram_received(self, data: bytes, addr: Address) -> None:
        """Peer -> client."""
        now = time.monotonic()
        if self.permissions.get(addr[0], 0) < now:
            return
        channel = self.peer_to_channel.get(addr)
        if channel is not None:
            self.client.send(struct.pack("!HH", channel, len(data)) + data, channel_data=True)
            return
        indication = Message(DATA, INDICATION, os.urandom(12))
        indication.add(XOR_PEER_ADDRESS, encode_xor_address(addr, indication.transaction_id))
        indication.add(DATA_ATTR, data)
        self.client.send(indication.encode(fingerprint=False))

    def send_to_peer(self, data: bytes, peer: Address) -> None:
        if self.transport is not None and self.permissions.get(peer[0], 0) >= time.monotonic():
            self.transport.sendto(data, peer)

    def close(self) -> None:
        if self.transport is not None:
            self.transport.close()


class ClientLink:
    """A client reached over UDP (one address) or TCP (one connection)."""

    def __init__(self, server: "TurnServer", addr: Address, udp: asyncio.DatagramTransport | None = None,
                 tcp: asyncio.Transport | None = None) -> None:
        self.server = server
        self.addr = addr
        self.udp = udp
        self.tcp = tcp

    def send(self, data: bytes, channel_data: bool = False) -> None:
        if self.udp is not None:
            self.udp.sendto(data, self.addr)
        elif self.tcp is not None and not self.tcp.is_closing():
            if channel_data:
                data += b"\x00" * _pad(len(data))  # TCP framing (RFC 5766 11.5)
            self.tcp.write(data)


class TurnServer:
    def __init__(self, public_ip: str | None, users: dict[str, str], realm: str = "smartclass") -> None:
        self.public_ip = public_ip
        self.users = users
        self.realm = realm
        self.nonce = os.urandom(8).hex().encode()
        self.allocations: dict[tuple, Allocation] = {}

    # ---------------------------------------------------------------- helpers
    def _key(self, username: str) -> bytes:
        return hashlib.md5(f"{username}:{self.realm}:{self.users[username]}".encode()).digest()

    def _error(self, request: Message, code: int, reason: str, with_realm: bool = False) -> Message:
        response = Message(request.method, ERROR, request.transaction_id)
        response.add(ERROR_CODE, struct.pack("!HBB", 0, code // 100, code % 100) + reason.encode())
        if with_realm:
            response.add(REALM, self.realm.encode())
            response.add(NONCE, self.nonce)
        return response

    def _authenticate(self, request: Message) -> tuple[str | None, Message | None]:
        if request.get(MESSAGE_INTEGRITY) is None:
            return None, self._error(request, 401, "Unauthorized", with_realm=True)
        username = (request.get(USERNAME) or b"").decode(errors="replace")
        if username not in self.users or request.get(REALM) is None or request.get(NONCE) is None:
            return None, self._error(request, 401, "Unauthorized", with_realm=True)
        if not check_integrity(request, self._key(username)):
            return None, self._error(request, 401, "Unauthorized", with_realm=True)
        return username, None

    # --------------------------------------------------------------- dispatch
    def handle(self, data: bytes, link: ClientLink, link_key: tuple) -> None:
        if is_channel_data(data):
            channel, length = struct.unpack("!HH", data[:4])
            allocation = self.allocations.get(link_key)
            if allocation is not None:
                peer = allocation.channel_to_peer.get(channel)
                if peer is not None:
                    allocation.send_to_peer(data[4 : 4 + length], peer)
            return

        request = parse_message(data)
        if request is None:
            return

        if request.cls == INDICATION:
            if request.method == SEND:
                allocation = self.allocations.get(link_key)
                peer_value = request.get(XOR_PEER_ADDRESS)
                payload = request.get(DATA_ATTR)
                peer = decode_xor_address(peer_value) if peer_value else None
                if allocation is not None and peer is not None and payload is not None:
                    allocation.send_to_peer(payload, peer)
            return
        if request.cls != REQUEST:
            return

        if request.method == BINDING:
            response = Message(BINDING, SUCCESS, request.transaction_id)
            response.add(XOR_MAPPED_ADDRESS, encode_xor_address(link.addr, request.transaction_id))
            link.send(response.encode())
            return

        username, error = self._authenticate(request)
        if error is not None:
            link.send(error.encode())
            return
        assert username is not None
        key = self._key(username)

        if request.method == ALLOCATE:
            asyncio.ensure_future(self._allocate(request, link, link_key, username, key))
            return
        if request.method == REFRESH:
            response = self._refresh(request, link_key)
        elif request.method == CREATE_PERMISSION:
            response = self._create_permission(request, link_key)
        elif request.method == CHANNEL_BIND:
            response = self._channel_bind(request, link_key)
        else:
            response = self._error(request, 400, "Bad Request")
        link.send(response.encode(integrity_key=key))

    async def _allocate(self, request: Message, link: ClientLink, link_key: tuple, username: str,
                        key: bytes) -> None:
        response = await self._allocation_response(request, link, link_key, username)
        link.send(response.encode(integrity_key=key))

    async def _allocation_response(self, request: Message, link: ClientLink, link_key: tuple,
                                   username: str) -> Message:
        existing = self.allocations.get(link_key)
        if existing is not None:
            return self._error(request, 437, "Allocation Mismatch")
        transport = request.get(REQUESTED_TRANSPORT)
        if transport is None:
            return self._error(request, 400, "Bad Request")
        if transport[0] != UDP_PROTOCOL:
            return self._error(request, 442, "Unsupported Transport Protocol")
        lifetime_value = request.get(LIFETIME)
        lifetime = struct.unpack("!I", lifetime_value)[0] if lifetime_value else DEFAULT_LIFETIME
        lifetime = max(1, min(lifetime, MAX_LIFETIME))

        loop = asyncio.get_running_loop()
        _, allocation = await loop.create_datagram_endpoint(
            lambda: Allocation(self, link, username, lifetime), local_addr=("0.0.0.0", 0)
        )
        self.allocations[link_key] = allocation
        # No fixed address: the PC's current LAN address (Wi-Fi may change).
        relay_ip = self.public_ip or lan_ip()
        log.info("Allocation %s:%s for %s", relay_ip, allocation.relay_port, link.addr)

        response = Message(ALLOCATE, SUCCESS, request.transaction_id)
        response.add(
            XOR_RELAYED_ADDRESS,
            encode_xor_address((relay_ip, allocation.relay_port), request.transaction_id),
        )
        response.add(XOR_MAPPED_ADDRESS, encode_xor_address(link.addr, request.transaction_id))
        response.add(LIFETIME, struct.pack("!I", lifetime))
        return response

    def _refresh(self, request: Message, link_key: tuple) -> Message:
        allocation = self.allocations.get(link_key)
        if allocation is None:
            return self._error(request, 437, "Allocation Mismatch")
        value = request.get(LIFETIME)
        lifetime = struct.unpack("!I", value)[0] if value else DEFAULT_LIFETIME
        lifetime = min(lifetime, MAX_LIFETIME)
        if lifetime == 0:
            self.remove(link_key)
        else:
            allocation.expires = time.monotonic() + lifetime
        response = Message(REFRESH, SUCCESS, request.transaction_id)
        response.add(LIFETIME, struct.pack("!I", lifetime))
        return response

    def _create_permission(self, request: Message, link_key: tuple) -> Message:
        allocation = self.allocations.get(link_key)
        if allocation is None:
            return self._error(request, 437, "Allocation Mismatch")
        peers = [decode_xor_address(v) for v in request.get_all(XOR_PEER_ADDRESS)]
        if not peers or any(p is None for p in peers):
            return self._error(request, 400, "Bad Request")
        expiry = time.monotonic() + PERMISSION_LIFETIME
        for peer in peers:
            allocation.permissions[peer[0]] = expiry  # type: ignore[index]
        return Message(CREATE_PERMISSION, SUCCESS, request.transaction_id)

    def _channel_bind(self, request: Message, link_key: tuple) -> Message:
        allocation = self.allocations.get(link_key)
        if allocation is None:
            return self._error(request, 437, "Allocation Mismatch")
        channel_value = request.get(CHANNEL_NUMBER)
        peer_value = request.get(XOR_PEER_ADDRESS)
        peer = decode_xor_address(peer_value) if peer_value else None
        if channel_value is None or peer is None:
            return self._error(request, 400, "Bad Request")
        channel = struct.unpack("!H", channel_value[:2])[0]
        if not 0x4000 <= channel <= 0x7FFF:
            return self._error(request, 400, "Bad Request")
        if allocation.channel_to_peer.get(channel, peer) != peer or allocation.peer_to_channel.get(peer, channel) != channel:
            return self._error(request, 400, "Bad Request")
        allocation.channel_to_peer[channel] = peer
        allocation.peer_to_channel[peer] = channel
        allocation.permissions[peer[0]] = time.monotonic() + max(PERMISSION_LIFETIME, CHANNEL_LIFETIME)
        return Message(CHANNEL_BIND, SUCCESS, request.transaction_id)

    def remove(self, link_key: tuple) -> None:
        allocation = self.allocations.pop(link_key, None)
        if allocation is not None:
            allocation.close()

    async def expire_loop(self) -> None:
        while True:
            await asyncio.sleep(5)
            now = time.monotonic()
            for link_key, allocation in list(self.allocations.items()):
                if allocation.expires < now:
                    log.info("Allocation %s expired", allocation.relay_port)
                    self.remove(link_key)


class UdpListener(asyncio.DatagramProtocol):
    def __init__(self, server: TurnServer) -> None:
        self.server = server
        self.transport: asyncio.DatagramTransport | None = None

    def connection_made(self, transport: asyncio.BaseTransport) -> None:
        self.transport = transport  # type: ignore[assignment]

    def datagram_received(self, data: bytes, addr: Address) -> None:
        self.server.handle(data, ClientLink(self.server, addr, udp=self.transport), ("udp", addr))

    def error_received(self, exc: Exception) -> None:  # e.g. ICMP port unreachable
        log.debug("UDP error: %s", exc)


class TcpConnection(asyncio.Protocol):
    def __init__(self, server: TurnServer) -> None:
        self.server = server
        self.buffer = b""
        self.link: ClientLink | None = None

    def connection_made(self, transport: asyncio.BaseTransport) -> None:
        addr = transport.get_extra_info("peername")[:2]
        self.link = ClientLink(self.server, addr, tcp=transport)  # type: ignore[arg-type]

    def data_received(self, data: bytes) -> None:
        self.buffer += data
        while len(self.buffer) >= 4:
            if is_channel_data(self.buffer):
                length = struct.unpack("!H", self.buffer[2:4])[0]
                size = 4 + length + _pad(length)
            else:
                length = struct.unpack("!H", self.buffer[2:4])[0]
                size = 20 + length
            if len(self.buffer) < size:
                return
            frame, self.buffer = self.buffer[:size], self.buffer[size:]
            assert self.link is not None
            self.server.handle(frame, self.link, ("tcp", id(self)))

    def connection_lost(self, exc: Exception | None) -> None:
        self.server.remove(("tcp", id(self)))


class Relay:
    """A running relay (UDP + TCP listeners on one port)."""

    def __init__(self, server: TurnServer, udp: asyncio.DatagramTransport, tcp: asyncio.AbstractServer,
                 expiry: asyncio.Task, port: int) -> None:
        self.server = server
        self.port = port
        self._udp = udp
        self._tcp = tcp
        self._expiry = expiry

    def close(self) -> None:
        self._expiry.cancel()
        for key in list(self.server.allocations):
            self.server.remove(key)
        self._udp.close()
        self._tcp.close()


async def start_relay(public_ip: str | None, port: int, users: dict[str, str]) -> Relay:
    """Starts the relay on the running event loop (raises OSError if the
    port is taken). Port 0 picks a free port (see Relay.port)."""
    server = TurnServer(public_ip, users)
    loop = asyncio.get_running_loop()
    udp, _ = await loop.create_datagram_endpoint(lambda: UdpListener(server), local_addr=("0.0.0.0", port))
    port = udp.get_extra_info("sockname")[1]
    try:
        tcp = await loop.create_server(lambda: TcpConnection(server), host="0.0.0.0", port=port)
    except OSError:
        udp.close()
        raise
    log.info("TURN relay on %s:%s (UDP + TCP)", public_ip or "LAN address", port)
    return Relay(server, udp, tcp, asyncio.ensure_future(server.expire_loop()), port)


def lan_ip() -> str:
    """Address of the network interface used to reach other devices."""
    import socket

    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        try:
            s.connect(("8.8.8.8", 80))  # no packet is sent
            return s.getsockname()[0]
        except OSError:
            return "127.0.0.1"


async def serve(public_ip: str, port: int, users: dict[str, str]) -> None:
    await start_relay(public_ip, port, users)
    await asyncio.Event().wait()
