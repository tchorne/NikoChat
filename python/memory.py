from openai import OpenAI
from os import getenv
import os.path
from os import listdir
import json
import time

script_dir = os.path.dirname(os.path.abspath(__file__))

SUMMARY_PATH = os.path.join(script_dir, 'memory', 'summarized')
RAW_PATH = os.path.join(script_dir, 'memory', 'raw')

MAX_CONVERSATION_MESSAGES = 15

def save_to_file(filename, data):
    with open(filename, 'w') as file:
        file.write(data)

def load_from_file(filename):
    with open(filename, 'r') as file:
        return file.read()
    
def get_summary_path(id):
    return os.path.join(SUMMARY_PATH, str(id) + ".json")

def get_conversation_path(id):
    return os.path.join(RAW_PATH, str(id) + ".json")

# Returns the cosine similarity between 2 vectors
# https://en.wikipedia.org/wiki/Cosine_similarity
def cosine_similarity(a, b):
    dotsum = 0
    asum = 0
    bsum = 0
    for i in range(len(a)):
        dotsum += a[i]*b[i]
        asum += a[i]*a[i]
        bsum += b[i]*b[i]

    if asum==0 or bsum==0: return 0

    return dotsum / ((asum**0.5) * (bsum**0.5))

def embed(text):
    client = OpenAI()
    embeddingResponse = client.embeddings.create(
        input=text,
        model="text-embedding-ada-002"
    )
    return embeddingResponse.data[0].embedding

    
# Creates a summary
# {
#   "summary": "...",
#   "id": 00000000,
#   "vector": [ ... ]
# }
# Saves it to a file, and returns it
def summarize_conversation(conversation):
    summary = {}
    id = conversation["unix"]
    if os.path.exists(get_summary_path(id)):
        print(f"Summary already exists for conversation {id}")
        return load_from_file(get_summary_path(id))
    
    client = OpenAI()

    block = ""
    for message in conversation['messages']:
        block += f"{message['author']}: {message['text']}\n\n"

    summary['vector'] = embed(block)

    summaryPrompt = load_from_file("memory/summarize.txt").replace("<<CONVERSATION>>", block)
    summaryResponse = client.chat.completions.create(
        model="gpt-3.5-turbo-1106",
        messages=[
            {"role": "system", "content": summaryPrompt},
            {"role": "user", "content": block}
        ]
    )

    summary['summary'] = summaryResponse.choices[0].message.content
    summary['summary_prompt_tokens'] = summaryResponse.usage.prompt_tokens
    summary['summary_completion_tokens'] = summaryResponse.usage.completion_tokens

    summary['id'] = id

    save_to_file(get_summary_path(id), json.dumps(summary))
    return summary

# Returns the file path of the most recent unix.json file in the given path
def get_most_recent_file(directory_path):
    files = os.listdir(directory_path)

    time_files = [file for file in files if file.endswith('.json') and file[:-5].isdigit()]

    if not time_files:
        print("No matching files found.")
        return None

    most_recent_file = max(time_files, key=lambda x: int(x[:-5]))

    most_recent_file_path = os.path.join(directory_path, most_recent_file)

    return most_recent_file_path

def get_all_conversations():
    summaries = []

    files = os.listdir(SUMMARY_PATH)

    summary_files = [file for file in files if file.endswith('.json') and file[:-5].isdigit()]

    for file in summary_files:
        string = load_from_file(os.path.join(SUMMARY_PATH, file))
        j = json.loads(string)
        summaries.append(j)

    return summaries

def store_in_conversation(message): # Input a message in the form {'author': NAME, 'text': MESSAGE}

    most_recent = get_most_recent_file(RAW_PATH)

    generate_new = False

    d = {}

    if most_recent is None:
        generate_new = True
    else:
        print("loading most recent")
        d = json.loads(load_from_file(most_recent))
        if len(d.get('messages')) > MAX_CONVERSATION_MESSAGES or d.get('finished', False):
            generate_new = True
            if len(d.get('messages')) > MAX_CONVERSATION_MESSAGES:
                d['finished'] = True
                save_to_file(most_recent, json.dumps(d))
    
    t = int(time.time())
    if generate_new:
        d = {
            "unix": t,
            "messages": [],
        }
        most_recent = os.path.join(RAW_PATH, str(t) + ".json")

    d['messages'].append({
        "author": message.get('author'),
        "text": message.get('text'),
        "unix": t,
    })

    save_to_file(most_recent, json.dumps(d))

def summarize_previous_conversations():
    raw = []

    files = os.listdir(RAW_PATH)

    raw_files = [file for file in files if file.endswith('.json') and file[:-5].isdigit()]

    for file in raw_files:
        string = load_from_file(os.path.join(RAW_PATH, file))
        j = json.loads(string)
        if (len(j.get('messages')) > MAX_CONVERSATION_MESSAGES or j.get('finished', False)):
            summarize_conversation(j)



def get_closest_conversations(vector, n=2): # Returns summaries jsons for the closest
    closest = []
    summaries = get_all_conversations()

     # Error handling for missing vectors
    summaries = [x for x in summaries if 'vector' in x]

    if not summaries: # List is empty
        return closest
    
    summaries.sort(key=lambda x: cosine_similarity(x['vector'], vector), reverse=True)

    for i in range(min(n, len(summaries))):
        closest.append(summaries[i])

    return closest


# Returns an array of messages in the current or most recent coversation 
# in a format that can be passed directly into openai chat completion
def get_most_recent_messages(human="Thomas", bot="Niko"):
    if not get_most_recent_file(RAW_PATH): return []
    raw_json = json.loads(load_from_file(get_most_recent_file(RAW_PATH)))

    raw_messages = raw_json['messages']

    if not raw_messages: return[]


    processed_messages = []

    if raw_messages[0]['author'] == human or raw_messages[0]['author'] == bot:
        pass
    elif len(raw_messages >= 2):
        print("Error in get_most_recent_messages()! Given names do not match text files. Are you sure you loaded the right conversation?")
        human = raw_messages[0]['author']
        bot = raw_messages[1]['author']
    else:
        human = raw_messages[0]['author']
    
    for message in raw_messages:
        if message['author'] == human:
            processed_messages.append({"role": "user", "content": message['text']})
        if message['author'] == bot:
            processed_messages.append({"role": "assistant", "content": message['text']})

    return processed_messages

