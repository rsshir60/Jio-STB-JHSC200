#!/usr/bin/env python3
"""
standalone_jhs_server.py -- Zero-dependency Standalone ACS + Selective DNS + Captive Portal Spoofer for Jio STB JHSC200

Features:
  1. Selective DNS server (UDP :53):
     - Spoofs *.jio.com, acs.oss.jio.com -> 192.168.137.1
     - Forwards all other queries (connectivitycheck, ntp, google) to 8.8.8.8 so internet & time sync pass!
  2. Built-in Captive Portal / HTTP :80 responder -> Returns 204 No Content to instantly validate network
  3. Built-in TLS server (:8443 and :9443) using tls/forged_chain.pem
  4. Built-in network check spoofer (/common/v1/network/check -> 200 OK)
  5. Built-in CWMP SOAP server handling Inform -> SetParameterValues -> 204 No Content
  6. Built-in ADB monitor & automatic JHS baseline workflow
"""

import sys
import os
import socket
import ssl
import threading
import time
import subprocess
import re
import datetime

# Color formatting
CYAN = '\033[0;36m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
RED = '\033[0;31m'
NC = '\033[0m'
BOLD = '\033[1m'

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_DIR = os.path.dirname(SCRIPT_DIR)
TLS_DIR = os.path.join(REPO_DIR, "tls")
CERT_FILE = os.path.join(TLS_DIR, "forged_chain.pem")
ADB_BIN = os.path.join(REPO_DIR, "adb.exe")
if not os.path.exists(ADB_BIN):
    ADB_BIN = "adb"

PRECOMPUTED_NETCHECK = "UzLgdFHvJkBfRQiHnNQit+55dub3o1PbxIhuNZ7oJc8="
UPSTREAM_DNS = "8.8.8.8"

def get_lan_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.bind(("192.168.137.1", 0))
        s.close()
        return "192.168.137.1"
    except Exception:
        pass
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "192.168.137.1"

HOST_IP = get_lan_ip()
TARGET_STB_IP = "192.168.137.237"
STOP_FLAG = False

def log(tag, msg):
    ts = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] {CYAN}[{tag}]{NC} {msg}", flush=True)

# ===============================================================
# 1. SELECTIVE DNS SERVER (UDP 53)
# ===============================================================
def forward_dns(query_data):
    try:
        fwd_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        fwd_sock.settimeout(1.5)
        fwd_sock.sendto(query_data, (UPSTREAM_DNS, 53))
        resp, _ = fwd_sock.recvfrom(512)
        fwd_sock.close()
        return resp
    except Exception:
        return None

def start_dns_server(ip):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    bound = False
    for bind_target in [ip, "192.168.137.1", "0.0.0.0"]:
        try:
            if bind_target == "0.0.0.0":
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            sock.bind((bind_target, 53))
            log("DNS", f"{GREEN}Selective DNS Server active on UDP {bind_target}:53{NC}")
            log("DNS", f"  -> Intercepting: *.jio.com / acs.* -> {ip}")
            log("DNS", f"  -> Forwarding: all others -> {UPSTREAM_DNS}")
            bound = True
            break
        except Exception:
            continue

    if not bound:
        log("DNS", f"{RED}Could not bind UDP 53 on any interface.{NC}")
        return

    while not STOP_FLAG:
        try:
            data, addr = sock.recvfrom(512)
            if len(data) < 12:
                continue

            # Parse query name
            i = 12
            qname_parts = []
            while i < len(data) and data[i] != 0:
                length = data[i]
                i += 1
                qname_parts.append(data[i:i+length].decode('latin1', 'ignore'))
                i += length
            qname = ".".join(qname_parts).lower()
            qname_end = i + 1 + 4

            # Check if this query should be intercepted
            should_intercept = (
                "jio.com" in qname or
                "acs." in qname or
                "tr069" in qname or
                "cwmp" in qname
            )

            if should_intercept:
                tid = data[:2]
                flags = b'\x81\x80'
                qdcount = data[4:6]
                ancount = b'\x00\x01'
                nscount = b'\x00\x00'
                arcount = b'\x00\x00'
                question = data[12:qname_end]
                resolved_ip = "192.168.137.1" if addr[0].startswith("192.168.137.") else ip
                answer = b'\xc0\x0c\x00\x01\x00\x01\x00\x00\x00\x3c\x00\x04' + socket.inet_aton(resolved_ip)
                resp = tid + flags + qdcount + ancount + nscount + arcount + question + answer
                sock.sendto(resp, addr)
                log("DNS", f"{YELLOW}[INTERCEPT]{NC} {qname} -> {resolved_ip} for {addr[0]}")
            else:
                # Forward to real upstream DNS
                upstream_resp = forward_dns(data)
                if upstream_resp:
                    sock.sendto(upstream_resp, addr)
                    log("DNS", f"[PASSTHROUGH] {qname} -> forwarded to 8.8.8.8 for {addr[0]}")
                else:
                    log("DNS", f"{RED}[UPSTREAM TIMEOUT]{NC} {qname}")
        except Exception:
            break
    sock.close()

# ===============================================================
# 2. CAPTIVE PORTAL / HTTP :80 RESPONDER
# ===============================================================
def serve_http_portal():
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        srv.bind(("0.0.0.0", 80))
        srv.listen(32)
        log("PORTAL", f"{GREEN}HTTP Portal active on :80 (instant 204 for Android connectivity checks){NC}")
    except Exception as e:
        log("PORTAL", f"{YELLOW}Could not bind port 80: {e} (continuing){NC}")
        return

    while not STOP_FLAG:
        try:
            conn, addr = srv.accept()
            req = conn.recv(1024).decode("latin1", "ignore")
            # Always return 204 No Content for connectivity checks
            resp = b"HTTP/1.1 204 No Content\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
            conn.sendall(resp)
            conn.close()
            log("PORTAL", f"204 No Content served to {addr[0]}")
        except Exception:
            break
    srv.close()

# ===============================================================
# 3. CWMP SOAP TEMPLATES
# ===============================================================
INFORM_RESPONSE = """<?xml version="1.0" encoding="UTF-8"?>
<soap-env:Envelope xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cwmp="urn:dslforum-org:cwmp-1-0">
  <soap-env:Header>
    <cwmp:ID soap-env:mustUnderstand="1">0</cwmp:ID>
  </soap-env:Header>
  <soap-env:Body>
    <cwmp:InformResponse>
      <MaxEnvelopes>1</MaxEnvelopes>
    </cwmp:InformResponse>
  </soap-env:Body>
</soap-env:Envelope>"""

SET_PARAM_VALUES = """<?xml version="1.0" encoding="UTF-8"?>
<soap-env:Envelope xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cwmp="urn:dslforum-org:cwmp-1-0">
  <soap-env:Header>
    <cwmp:ID soap-env:mustUnderstand="1">1a16525bdc20001</cwmp:ID>
  </soap-env:Header>
  <soap-env:Body>
    <cwmp:SetParameterValues>
      <ParameterList soap-enc:arrayType="cwmp:ParameterValueStruct[4]">
        <ParameterValueStruct>
          <Name>Device.JioSTB.USB.USBDebugging</Name>
          <Value xsi:type="xsd:boolean">true</Value>
        </ParameterValueStruct>
        <ParameterValueStruct>
          <Name>Device.JioSTB.USB.DebugValidityDate</Name>
          <Value xsi:type="xsd:dateTime">2037-01-01T00:00:00.000Z</Value>
        </ParameterValueStruct>
        <ParameterValueStruct>
          <Name>Device.JioSTB.FOTA.DowngradeEnable</Name>
          <Value xsi:type="xsd:string">true</Value>
        </ParameterValueStruct>
        <ParameterValueStruct>
          <Name>Device.JioSTB.FOTA.DowngradeValidityDate</Name>
          <Value xsi:type="xsd:dateTime">2037-12-31T23:59:59.000Z</Value>
        </ParameterValueStruct>
      </ParameterList>
      <ParameterKey>STAGE1</ParameterKey>
    </cwmp:SetParameterValues>
  </soap-env:Body>
</soap-env:Envelope>"""

# ===============================================================
# 4. HTTP / TLS HANDLERS
# ===============================================================
def read_http(rf):
    line = rf.readline()
    if not line:
        return None
    reqline = line.decode("latin1").rstrip("\r\n")
    headers = {}
    while True:
        h = rf.readline()
        if not h or h in (b"\r\n", b"\n"):
            break
        k, _, v = h.decode("latin1").partition(":")
        headers[k.strip().lower()] = v.strip()
    body = b""
    if "content-length" in headers:
        n = int(headers["content-length"])
        body = rf.read(n) if n else b""
    return reqline, headers, body

def handle_client(conn, addr, ctx):
    global TARGET_STB_IP
    TARGET_STB_IP = addr[0]
    log("TLS", f"Inbound TLS connection from {addr[0]}:{addr[1]}")
    try:
        s = ctx.wrap_socket(conn, server_side=True)
    except Exception as e:
        log("TLS", f"Handshake failed with {addr[0]}: {e}")
        try: conn.close()
        except: pass
        return

    rf = s.makefile("rb")
    session_state = 0

    try:
        while True:
            req = read_http(rf)
            if req is None:
                break
            reqline, headers, body = req
            parts = reqline.split(" ")
            path = parts[1] if len(parts) > 1 else ""

            # 1. Network check spoof
            if "network/check" in path:
                resp_body = ('{"Network":"%s"}' % PRECOMPUTED_NETCHECK).encode("utf-8")
                header = (
                    "HTTP/1.1 200 OK\r\n"
                    "Content-Type: application/json\r\n"
                    f"Content-Length: {len(resp_body)}\r\n"
                    "Connection: keep-alive\r\n\r\n"
                ).encode("latin1")
                s.sendall(header + resp_body)
                log("SPOOF", f"{GREEN}200 OK Network Check spoofed for {addr[0]}{NC}")
                continue

            body_str = body.decode("latin1", "replace")

            # 2. CWMP Inform Handling
            if "Inform" in body_str and "cwmp:Inform" in body_str:
                sn = "Unknown"
                sn_m = re.search(r'<SerialNumber>([^<]+)</SerialNumber>', body_str)
                if sn_m:
                    sn = sn_m.group(1)
                log("CWMP", f"{GREEN}* CWMP Inform received from {addr[0]} (SN: {sn}){NC}")
                
                resp_body = INFORM_RESPONSE.encode("utf-8")
                header = (
                    "HTTP/1.1 200 OK\r\n"
                    "Content-Type: text/xml; charset=\"utf-8\"\r\n"
                    "Set-Cookie: session=1a165052ab70000\r\n"
                    f"Content-Length: {len(resp_body)}\r\n"
                    "Connection: keep-alive\r\n\r\n"
                ).encode("latin1")
                s.sendall(header + resp_body)
                log("CWMP", f"Sent InformResponse to {addr[0]}")
                session_state = 1
                continue

            # 3. Empty POST -> Send SetParameterValues
            if len(body) == 0 and session_state >= 1:
                log("CWMP", f"Empty POST received from {addr[0]} -> Dispatching SetParameterValues RPC...")
                resp_body = SET_PARAM_VALUES.encode("utf-8")
                header = (
                    "HTTP/1.1 200 OK\r\n"
                    "Content-Type: text/xml; charset=\"utf-8\"\r\n"
                    f"Content-Length: {len(resp_body)}\r\n"
                    "Connection: keep-alive\r\n\r\n"
                ).encode("latin1")
                s.sendall(header + resp_body)
                log("CWMP", f"{YELLOW}Dispatched USBDebugging=true & Validity=2037 RPC to {addr[0]}{NC}")
                session_state = 2
                continue

            # 4. SetParameterValuesResponse Handling
            if "SetParameterValuesResponse" in body_str:
                status_m = re.search(r'<Status>([^<]+)</Status>', body_str)
                status = status_m.group(1) if status_m else "0"
                log("CWMP", f"{GREEN}* STB confirmed SetParameterValues! Status: {status} (0 = Success!){NC}")
                header = (
                    "HTTP/1.1 204 No Content\r\n"
                    "Content-Length: 0\r\n"
                    "Connection: close\r\n\r\n"
                ).encode("latin1")
                s.sendall(header)
                log("CWMP", f"{GREEN}* CWMP Provisioning Complete! Port 5555 opening now...{NC}")
                break

            # Generic 204 fallback
            header = "HTTP/1.1 204 No Content\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".encode("latin1")
            s.sendall(header)
            break
    except Exception as e:
        log("CWMP", f"Session error with {addr[0]}: {e}")
    finally:
        try: s.close()
        except: pass

def serve_tls(port, ctx):
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        srv.bind(("0.0.0.0", port))
        srv.listen(64)
        log("TLS", f"{GREEN}Listening on https://0.0.0.0:{port}{NC}")
    except Exception as e:
        log("TLS", f"{RED}Could not bind port {port}: {e}{NC}")
        return

    while not STOP_FLAG:
        try:
            conn, addr = srv.accept()
            threading.Thread(target=handle_client, args=(conn, addr, ctx), daemon=True).start()
        except Exception:
            break
    srv.close()

# ===============================================================
# 5. ADB MONITOR & POST-SETUP AUTOMATION
# ===============================================================
def run_post_setup(stb_ip):
    log("ADB", f"{BOLD}{CYAN}=== STARTING AUTOMATED JHS BASELINE SETUP ==={NC}")
    target = f"{stb_ip}:5555"

    def adb_sh(cmd):
        full = f'"{ADB_BIN}" -s {target} shell {cmd}'
        res = subprocess.run(full, shell=True, capture_output=True, text=True)
        return res.stdout.strip()

    # Step 1: Baseline settings
    adb_sh("settings put global device_provisioned 1")
    adb_sh("settings put global development_settings_enabled 1")
    log("POST", "Enabled global development settings")

    # Step 2: Disable Iwedia OTA update services
    ota_pkgs = [
        "com.iwedia.httpupdate",
        "com.iwedia.updateservice",
        "com.iwedia.pvodupdateservice",
        "com.iwedia.updatercuotaservice"
    ]
    for pkg in ota_pkgs:
        out = adb_sh(f"pm disable-user --user 0 {pkg}")
        log("OTA", f"Disabled {pkg}: {out}")
    adb_sh("pm clear com.iwedia.httpupdate")
    adb_sh("pm clear com.iwedia.updateservice")
    log("OTA", "Cleared staged OTA update caches")

    # Step 3: Uninstall Ad service
    ad_out = adb_sh("pm uninstall -k --user 0 com.jio.stbadservice")
    log("ADS", f"Uninstalled Jio Ad Service: {ad_out}")

    # Check TR-069 persistence
    tr069_state = adb_sh("pm list packages | grep -i tr069client")
    log("SAFE", f"TR-069 status: {tr069_state} (Preserved for persistence)")

    log("ADB", f"{BOLD}{GREEN}* BASELINE UNLOCK COMPLETE! Device ready for Debloat & Launcher Suite. *{NC}")

def adb_monitor_thread():
    log("MONITOR", f"ADB watcher started. Polling for STB port 5555 on {TARGET_STB_IP}...")
    while not STOP_FLAG:
        if TARGET_STB_IP:
            stb_ip = TARGET_STB_IP
            try:
                with socket.create_connection((stb_ip, 5555), timeout=1.0):
                    log("MONITOR", f"{GREEN}* PORT 5555 IS OPEN ON {stb_ip}! Connecting ADB...{NC}")
                    subprocess.run(f'"{ADB_BIN}" connect {stb_ip}:5555', shell=True)
                    time.sleep(2)
                    
                    state_out = subprocess.run(f'"{ADB_BIN}" -s {stb_ip}:5555 get-state', shell=True, capture_output=True, text=True).stdout.strip()
                    if state_out != "device":
                        print(f"\n{BOLD}{YELLOW}>>> LOOK AT TV SCREEN: Check 'Always allow from this computer' and select OK! <<<{NC}\n", flush=True)
                        while not STOP_FLAG:
                            state_out = subprocess.run(f'"{ADB_BIN}" -s {stb_ip}:5555 get-state', shell=True, capture_output=True, text=True).stdout.strip()
                            if state_out == "device":
                                break
                            time.sleep(2)
                    
                    log("MONITOR", f"{GREEN}* ADB AUTHORIZED! Handshake established successfully. *{NC}")
                    run_post_setup(stb_ip)
                    break
            except Exception:
                pass
        time.sleep(2)

# ===============================================================
# MAIN ENTRYPOINT
# ===============================================================
def main():
    global STOP_FLAG
    print(f"\n==================================================================", flush=True)
    print(f"       Jio STB JHSC200 - Standalone Zero-Dependency Unlock Server", flush=True)
    print(f"==================================================================\n", flush=True)

    log("INIT", f"Host Hotspot Gateway: {BOLD}{HOST_IP}{NC}")
    log("INIT", f"Target STB IP: {BOLD}{TARGET_STB_IP}{NC}")
    log("INIT", f"Certificate: {CERT_FILE}")

    if not os.path.exists(CERT_FILE):
        log("INIT", f"{RED}Certificate {CERT_FILE} not found!{NC}")
        sys.exit(1)

    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(CERT_FILE)
    try:
        ctx.set_ciphers("DEFAULT:@SECLEVEL=0")
    except Exception:
        pass

    threading.Thread(target=start_dns_server, args=(HOST_IP,), daemon=True).start()
    threading.Thread(target=serve_http_portal, daemon=True).start()
    threading.Thread(target=serve_tls, args=(8443, ctx), daemon=True).start()
    threading.Thread(target=serve_tls, args=(9443, ctx), daemon=True).start()
    threading.Thread(target=adb_monitor_thread, daemon=True).start()

    print(f"\n{BOLD}{GREEN}* SERVER ARMED AND AWAITING STB BOOT INFORM! *{NC}", flush=True)
    print(f"  Target STB IP: {BOLD}{TARGET_STB_IP}{NC}", flush=True)
    print(f"  {BOLD}{YELLOW}Unplug the STB wall power brick, wait 5 seconds, and plug it back in.{NC}\n", flush=True)

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        STOP_FLAG = True
        print(f"\n{YELLOW}Server stopped.{NC}", flush=True)

if __name__ == "__main__":
    main()
