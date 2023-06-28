#!/usr/bin/env python

import asyncio
from websockets.sync.client import connect

def hello():
    with connect("ws://192.168.31.209:8888") as websocket:
        websocket.send("Hi!")
        message = websocket.recv()
        print(f"Received: {message}")

hello()
