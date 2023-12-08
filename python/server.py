# echo-server.py

import socket

from characterai import PyCAI
from os import getenv
import json

from transformers import pipeline

EMOTION_ANALYSIS = True
NEUTRAL_THRESHHOLD = 0.7

REPEAT_BACK = False


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


def analyze_emotion(text):
    # Load pre-trained emotion analysis model
    emotion_classifier = pipeline("text-classification", model="cardiffnlp/twitter-roberta-base-emotion-multilabel-latest", top_k=None)

    # Perform emotion analysis on the given text
    result = emotion_classifier(text)[0]
    #print(result)
    highestScore = result[0]['score']
    highestLabel = result[0]['label']

    for r in result:
        if r['score'] > highestScore:
            highestScore = r['score']
            highestLabel = r['label']
    
    if highestScore > NEUTRAL_THRESHHOLD:
        return "<" + highestLabel + ">"
    else:
        return ""

def get_history():
    history = client.chat.get_histories(char)['histories'][0]
    msgs = history['msgs']
    history_dict = {"messages": []}
    for message in msgs:
        history_dict['messages'].append(
            {
                "name" : message['src_char']['participant']['name'],
                "human" : message['src__is_human'],
                "text" : message['text']
            }
        )
    return json.dumps(history_dict)

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((HOST, PORT))
    print("Starting server on port " + str(PORT))
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
                responsetext = ""
                if REPEAT_BACK:
                    responsetext = stripped
                else:
                    responsetext = charai_message(stripped)
                
                if EMOTION_ANALYSIS:
                    responsetext = analyze_emotion(responsetext) + responsetext

                responsetext = "MSG:" + responsetext
                response = bytes(responsetext, 'utf-8')
                print("AI Response recieved: %s" % responsetext)
                conn.sendall(response)
            
            isHistoryRequest = string == "HISTORY"
            if isHistoryRequest:
                historytext = get_history()
                historytext = "HISTORY:"+historytext
                history = bytes(historytext, "utf-8")
                conn.sendall(history)




