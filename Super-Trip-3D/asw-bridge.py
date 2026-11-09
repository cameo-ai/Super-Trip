#!/usr/bin/env python3
"""Puente local Super-Trip 3D -> Auto Sea Way; solo loopback."""
from __future__ import annotations
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlencode, urlsplit
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

HOST, PORT = '127.0.0.1', 8766
UPSTREAM = 'http://127.0.0.1:3000'
ALLOWED_ORIGINS = {'http://127.0.0.1:8765', 'http://localhost:8765', 'http://127.0.0.1:8780'}
ENV_PATH = Path(__file__).with_name('asw.env')

def load_key():
    key = os.environ.get('ASW_API_KEY', '').strip()
    if key:
        return key
    if ENV_PATH.is_file():
        for line in ENV_PATH.read_text(encoding='utf-8-sig').splitlines():
            if line.startswith('ASW_API_KEY='):
                return line.split('=', 1)[1].strip()
    raise RuntimeError('Falta ASW_API_KEY en entorno o asw.env')

def point(raw):
    p = [float(x.strip()) for x in raw.split(',')]
    if len(p) != 2 or not (-90 <= p[0] <= 90 and -180 <= p[1] <= 180):
        raise ValueError('Se requiere latitud,longitud válidas')
    if not all(abs(v) < float('inf') for v in p):
        raise ValueError('Coordenadas no finitas')
    return f'{p[0]},{p[1]}'

class Handler(BaseHTTPRequestHandler):
    def reply(self, status, payload):
        raw = json.dumps(payload, ensure_ascii=False, separators=(',', ':')).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(raw)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        origin = self.headers.get('Origin', '')
        if origin in ALLOWED_ORIGINS:
            self.send_header('Access-Control-Allow-Origin', origin)
            self.send_header('Vary', 'Origin')
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self):
        origin = self.headers.get('Origin', '')
        if origin not in ALLOWED_ORIGINS:
            self.reply(403, {'error': 'Origen no permitido'})
            return
        url = urlsplit(self.path)
        if url.path == '/health':
            self.reply(200, {'status': 'bridge-ready'})
            return
        if url.path != '/route':
            self.reply(404, {'error': 'Ruta no encontrada'})
            return
        try:
            params = parse_qs(url.query)
            start, end = point(params['from'][0]), point(params['to'][0])
            req = Request(f'{UPSTREAM}/route?{urlencode({"from": start, "to": end})}', headers={'X-Api-Key': load_key(), 'Accept': 'application/json'})
            with urlopen(req, timeout=25) as response:
                data = json.load(response)
            geometry = data.get('geometry')
            if not isinstance(geometry, dict) or geometry.get('type') != 'LineString':
                raise ValueError('Geometría inválida')
            coords = geometry.get('coordinates')
            if not isinstance(coords, list) or not (2 <= len(coords) <= 50000):
                raise ValueError('Geometría ausente o excesiva')
            self.reply(200, {'geometry': geometry, 'distance_nm': data.get('distance_nm'), 'land_legs': data.get('land_legs', [])})
        except KeyError:
            self.reply(400, {'error': 'Faltan from/to'})
        except (ValueError, OverflowError) as exc:
            self.reply(400, {'error': str(exc)})
        except RuntimeError:
            self.reply(503, {'error': 'Falta configuración local de Auto Sea Way'})
        except HTTPError as exc:
            self.reply(502 if exc.code == 401 else exc.code, {'error': f'Motor devolvió HTTP {exc.code}'})
        except (URLError, TimeoutError, OSError):
            self.reply(503, {'error': 'Motor no disponible'})

    def do_OPTIONS(self):
        origin = self.headers.get('Origin', '')
        if origin not in ALLOWED_ORIGINS:
            self.send_response(403)
            self.end_headers()
            return
        self.send_response(204)
        self.send_header('Access-Control-Allow-Origin', origin)
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Accept')
        self.end_headers()

    def log_message(self, fmt, *args):
        return

if __name__ == '__main__':
    load_key()
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f'Puente marítimo listo en http://{HOST}:{PORT}', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
