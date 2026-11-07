"""Local TURN relay (app/signaling/local_relay.py): the protocol steps WebRTC
clients use, and the backend starting it with LOCAL_TURN_RELAY=true."""

import asyncio
import hashlib
import os
import socket
import struct

from app.signaling import local_relay as turn

USER, PASSWORD, REALM = "smartclass", "secret-123", "smartclass"


def _key() -> bytes:
    return hashlib.md5(f"{USER}:{REALM}:{PASSWORD}".encode()).digest()


def _request(method: int, nonce: bytes | None = None, *attrs: tuple[int, bytes]) -> tuple[bytes, bytes]:
    msg = turn.Message(method, turn.REQUEST, os.urandom(12))
    for t, v in attrs:
        msg.add(t, v)
    if nonce is None:
        return msg.transaction_id, msg.encode(fingerprint=False)
    msg.add(turn.USERNAME, USER.encode()).add(turn.REALM, REALM.encode()).add(turn.NONCE, nonce)
    return msg.transaction_id, msg.encode(integrity_key=_key())


async def _exchange(sock: socket.socket, data: bytes, port: int) -> turn.Message:
    loop = asyncio.get_running_loop()
    sock.sendto(data, ("127.0.0.1", port))
    reply = await asyncio.wait_for(loop.sock_recv(sock, 4096), 3)
    message = turn.parse_message(reply)
    assert message is not None
    return message


def test_relay_allocates_and_forwards_data_both_ways():
    async def scenario():
        relay = await turn.start_relay("127.0.0.1", 0, {USER: PASSWORD})
        client = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        peer = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        client.setblocking(False)
        peer.setblocking(False)
        peer.bind(("127.0.0.1", 0))
        peer_addr = peer.getsockname()
        loop = asyncio.get_running_loop()
        try:
            transport = (turn.REQUESTED_TRANSPORT, bytes([turn.UDP_PROTOCOL, 0, 0, 0]))

            # 1. Unauthenticated Allocate -> 401 with realm and nonce.
            _, data = _request(turn.ALLOCATE, None, transport)
            challenge = await _exchange(client, data, relay.port)
            assert challenge.cls == turn.ERROR
            assert challenge.get(turn.ERROR_CODE)[2:4] == bytes([4, 1])
            nonce = challenge.get(turn.NONCE)
            assert challenge.get(turn.REALM) == REALM.encode() and nonce

            # Wrong password -> 401 again.
            bad = turn.Message(turn.ALLOCATE, turn.REQUEST, os.urandom(12))
            bad.add(*transport).add(turn.USERNAME, USER.encode()).add(turn.REALM, REALM.encode())
            bad.add(turn.NONCE, nonce)
            wrong_key = hashlib.md5(f"{USER}:{REALM}:nope".encode()).digest()
            refused = await _exchange(client, bad.encode(integrity_key=wrong_key), relay.port)
            assert refused.cls == turn.ERROR

            # 2. Authenticated Allocate -> relayed address, signed response.
            tid, data = _request(turn.ALLOCATE, nonce, transport)
            allocated = await _exchange(client, data, relay.port)
            assert allocated.cls == turn.SUCCESS and allocated.transaction_id == tid
            assert turn.check_integrity(allocated, _key())
            relayed = turn.decode_xor_address(allocated.get(turn.XOR_RELAYED_ADDRESS))
            assert relayed[0] == "127.0.0.1" and relayed[1] > 0

            # 3. Permission for the peer, then Send indication -> peer.
            peer_attr = (turn.XOR_PEER_ADDRESS, turn.encode_xor_address(peer_addr, b""))
            _, data = _request(turn.CREATE_PERMISSION, nonce, peer_attr)
            assert (await _exchange(client, data, relay.port)).cls == turn.SUCCESS
            send = turn.Message(turn.SEND, turn.INDICATION, os.urandom(12))
            send.add(*peer_attr).add(turn.DATA_ATTR, b"hello peer")
            client.sendto(send.encode(fingerprint=False), ("127.0.0.1", relay.port))
            payload, source = await asyncio.wait_for(loop.sock_recvfrom(peer, 4096), 3)
            assert payload == b"hello peer" and source[1] == relayed[1]

            # 4. Peer answers the relayed address -> Data indication to client.
            peer.sendto(b"hello client", ("127.0.0.1", relayed[1]))
            indication = turn.parse_message(await asyncio.wait_for(loop.sock_recv(client, 4096), 3))
            assert indication.method == turn.DATA and indication.get(turn.DATA_ATTR) == b"hello client"

            # 5. Channel binding, then ChannelData both ways.
            channel = (turn.CHANNEL_NUMBER, struct.pack("!HH", 0x4001, 0))
            _, data = _request(turn.CHANNEL_BIND, nonce, channel, peer_attr)
            assert (await _exchange(client, data, relay.port)).cls == turn.SUCCESS
            client.sendto(struct.pack("!HH", 0x4001, 5) + b"media", ("127.0.0.1", relay.port))
            payload, _ = await asyncio.wait_for(loop.sock_recvfrom(peer, 4096), 3)
            assert payload == b"media"
            peer.sendto(b"back", ("127.0.0.1", relayed[1]))
            framed = await asyncio.wait_for(loop.sock_recv(client, 4096), 3)
            assert framed == struct.pack("!HH", 0x4001, 4) + b"back"

            # A peer IP without permission is not forwarded (permissions are
            # per IP, so this needs another loopback address).
            stranger = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            try:
                stranger.bind(("127.0.0.2", 0))
            except OSError:
                stranger.close()
                stranger = None
            if stranger is not None:
                stranger.sendto(b"spam", ("127.0.0.1", relayed[1]))
                await asyncio.sleep(0.2)
                try:
                    client.recv(4096)
                    raise AssertionError("unexpected data from a peer without permission")
                except BlockingIOError:
                    pass
                stranger.close()
        finally:
            client.close()
            peer.close()
            relay.close()

    asyncio.run(scenario())


def test_backend_starts_local_relay_and_hands_it_to_the_app(world, monkeypatch):
    from fastapi.testclient import TestClient

    from app.config import settings
    from app.main import app

    monkeypatch.setattr(settings, "local_turn_relay", True)
    monkeypatch.setattr(settings, "local_turn_ip", "127.0.0.1")
    monkeypatch.setattr(settings, "local_turn_port", 0)
    for name in ("turn_urls", "turn_username", "turn_credential"):
        monkeypatch.setattr(settings, name, "")

    with TestClient(app) as client:
        body = client.get("/signaling/ice-servers", headers=world["student"]).json()
        assert body["turn_configured"] is True
        relay = next(s for s in body["ice_servers"] if s.get("username") == "smartclass")
        assert relay["credential"]
        urls = relay["urls"]
        assert urls[0].startswith("turn:127.0.0.1:") and urls[0].endswith("?transport=udp")
        assert urls[1].endswith("?transport=tcp")
        port = int(urls[0].split(":")[2].split("?")[0])

        # The relay answers a TURN Allocate (401 challenge) on that port.
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.settimeout(3)
        _, data = _request(turn.ALLOCATE, None, (turn.REQUESTED_TRANSPORT, bytes([17, 0, 0, 0])))
        sock.sendto(data, ("127.0.0.1", port))
        reply = turn.parse_message(sock.recv(4096))
        sock.close()
        assert reply.cls == turn.ERROR and reply.get(turn.NONCE)


def test_relay_address_follows_the_address_clients_used(monkeypatch):
    """Phones get the Wi-Fi address they reached the backend on (it changes
    with the network); LOCAL_TURN_IP still wins when set."""
    from app.config import settings
    from app.signaling import ice
    from app.signaling.local_relay import lan_ip

    monkeypatch.setattr(settings, "local_turn_ip", "")
    assert ice.relay_host(("10.194.53.114", 8000)) == "10.194.53.114"
    assert ice.relay_host(("127.0.0.1", 8000)) == "127.0.0.1"
    assert ice.relay_host(("0.0.0.0", 8000)) == lan_ip()
    assert ice.relay_host(("testserver", 80)) == lan_ip()
    assert ice.relay_host(None) == lan_ip()
    monkeypatch.setattr(settings, "local_turn_ip", "192.168.1.20")
    assert ice.relay_host(("10.194.53.114", 8000)) == "192.168.1.20"

    ice.use_local_relay(3478, "smartclass", "pw")
    try:
        monkeypatch.setattr(settings, "local_turn_ip", "")
        relay = next(s for s in ice.ice_servers(("10.194.53.114", 8000)) if s.get("username") == "smartclass")
        assert relay["urls"] == [
            "turn:10.194.53.114:3478?transport=udp",
            "turn:10.194.53.114:3478?transport=tcp",
        ]
        assert ice.turn_configured()
    finally:
        ice.clear_local_relay()

