# echo-server.py

import socket

from characterai import PyCAI
from os import getenv

char = "cEJr8YzuRSvwKr3WHcUJ0dMirh9bZdwJWt9DR2ku1QQ"

HOST = "127.0.0.1"  # Standard loopback interface address (localhost) 127.0.0.1
PORT = 8081  # Port to listen on (non-privileged ports are > 1023)

client = PyCAI(getenv("CHARACTERAI_TOKEN"))
chat = client.chat.get_chat(char)
participants = chat['participants']

if not participants[0]['is_human']:
    tgt = participants[0]['user']['username']
else:
    tgt = participants[1]['user']['username']

def charai_message(msg):
    message = msg

    data = client.chat.send_message(
        chat['external_id'], tgt, message
    )

    name = data['src_char']['participant']['name']
    text = data['replies'][0]['text']

    return (f"{text}") # {name}: {text}

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((HOST, PORT))
    s.listen()
    conn, addr = s.accept()
    with conn:
        print(f"Connected by {addr}")


        #print(chat['replies'][0]['text'])

        while True:
            data = conn.recv(1024)
            if not data:
                break

            string = data.decode("utf8")
            isMessage = string.startswith("MSG:")

            #if isMessage: conn.sendall(data)
            if isMessage:
                stripped = string.removeprefix("MSG:")
                #stripped = stripped.removesuffix("")
                print("User Message recieved: %s" % stripped)
                responsetext = charai_message(stripped)
                response = bytes(responsetext, 'utf-8')
                print("AI Response recieved: %s" % responsetext)
                conn.sendall(response)







