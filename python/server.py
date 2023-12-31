# echo-server.py

import socket
from characterai import PyCAI
from openai import OpenAI
from os import getenv
import os.path
import json
import argparse

import context
import memory

from transformers import pipeline

EMOTION_ANALYSIS = True
NEUTRAL_THRESHHOLD = 0.7

USE_CONTEXT = False
REPEAT_BACK = False
RECORD = True

char = "cEJr8YzuRSvwKr3WHcUJ0dMirh9bZdwJWt9DR2ku1QQ"

#HOST = "127.0.0.1"  # Standard loopback interface address (localhost) 127.0.0.1
#HOST = "192.168.68.58"
#HOST = "192.168.68.50"
HOST = "0.0.0.0" # Public

PORT = 8001  # Port to listen on (non-privileged ports are > 1023)


use_openai = True


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

def openai_message(msg, human="Thomas", bot="Niko"):
    client = OpenAI()

    relevant = ""

    relevant_conversations = []
    unique_ids = set()
    unique_data = []

    
    for item in memory.get_closest_conversations(memory.embed(msg)):
        if item["id"] not in unique_ids:
            unique_ids.add(item["id"])
            relevant_conversations.append(item)
            
    conversation_messages = memory.get_most_recent_messages(human, bot)

    if conversation_messages:
        t = ""
        for message in conversation_messages:
            #print(message)
            t += f"{message['content']}\n\n"
        for item in memory.get_closest_conversations(memory.embed(t)):
            if item["id"] not in unique_ids:
                unique_ids.add(item["id"])
                relevant_conversations.append(item)
            


    for r in relevant_conversations:
        relevant += f"{r['summary']}\n\n"

    print(f"Relevant: {relevant}\n END RELEVANT\n")

    systemPrompt = memory.load_from_file(os.path.join(os.path.dirname(os.path.abspath(__file__)), "memory", "system.txt")).replace("<<RELEVANT>>", relevant)
    response = client.chat.completions.create(
        model="gpt-3.5-turbo-1106",
        messages=[
            {"role": "system", "content": systemPrompt},
        ] + conversation_messages + [
            {"role": "user", "content": msg}
        ]
    )
    
    return response.choices[0].message.content

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

def get_history(human_name="Thomas", bot_name="Niko"):
    if not use_openai:
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
    else:

        msgs = memory.get_most_recent_messages()
        history_dict = {"messages": []}
        for message in msgs:
            history_dict['messages'].append(
                {
                    "name" : human_name if message['role'] == 'user' else bot_name,
                    "human" : message['role'] == 'user',
                    "text" : message['content']
                }
            )

        return json.dumps(history_dict)

def main():
    

    parser = argparse.ArgumentParser(description="Command line script with IP, PORT, HUMAN, and BOT arguments.")

    # Adding command line arguments with default values
    parser.add_argument("-i", "--ip", help="IP address", default="127.0.0.1")
    parser.add_argument("-p", "--port", help="Port number", default="8001")
    parser.add_argument("-H", "--human", help="Human argument", default="Thomas")
    parser.add_argument("-b", "--bot", help="Bot argument", default="Niko")

    # Parsing command line arguments
    args = parser.parse_args()

    # Accessing the values
    ip = args.ip
    port = int(args.port)
    human = args.human
    bot = args.bot

    # Displaying the values
    print(f"IP: {ip}")
    print(f"Port: {port}")
    print(f"Human: {human}")
    print(f"Bot: {bot}")

    # Main loop
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((ip, port))
        print(f"Starting server on {ip}:{port}")
        s.listen()
        
        while True:
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

                        print("User Message recieved: %s" % stripped)

                        if USE_CONTEXT:
                            if "CONTEXT" in stripped:
                                stripped = stripped.replace("CONTEXT", context.get_context())
                            elif context.is_context_out_of_date():
                                stripped = context.get_context() + stripped

                        responsetext = ""
                        if REPEAT_BACK:
                            responsetext = stripped
                        elif not use_openai:
                            responsetext = charai_message(stripped)
                        else:
                            responsetext = openai_message(stripped, human=human, bot=bot)

                        if RECORD:
                            memory.store_in_conversation({'author': human, 'text': stripped})
                            memory.store_in_conversation({'author': bot, 'text': responsetext})

                        if EMOTION_ANALYSIS:
                            responsetext = analyze_emotion(responsetext) + responsetext

                        

                        responsetext = "MSG:" + responsetext
                        response = bytes(responsetext, 'utf-8')
                        print("AI Response recieved: %s" % responsetext)
                        conn.sendall(response)

                        memory.summarize_previous_conversations()
                    
                    isHistoryRequest = string == "HISTORY"
                    if isHistoryRequest:
                        historytext = get_history(human, bot)
                        historytext = "HISTORY:"+historytext
                        history = bytes(historytext, "utf-8")
                        conn.sendall(history)

if __name__ == "__main__":
    main()
