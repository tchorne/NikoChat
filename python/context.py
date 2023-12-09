import requests
import json
from os import getenv
from os.path import exists as path_exists
from os.path import getmtime as get_modified_time
from datetime import datetime

WEATHER_PATH = "weather.json"
LOCATION = "Ottawa"

def save_to_file(filename, data):
    with open(filename, 'w') as file:
        file.write(data)

def load_from_file(filename):
    with open(filename, 'r') as file:
        return file.read()
    
def get_datetime():
    current = datetime.now()
    string = current.strftime("%Y-%m-%d %H:%M")
    return f"(DATE AND TIME: {string})"

def get_weather():
    get_new = True
    weather_data = {}
    if path_exists(WEATHER_PATH):
        last_modified_time = get_modified_time(WEATHER_PATH)
        last_modified_date = datetime.utcfromtimestamp(last_modified_time).date()
        today_date = datetime.utcnow().date()

        if last_modified_date == today_date:
            print("Loading todays weather from file...")
            weather_data = json.loads(load_from_file(WEATHER_PATH))
            get_new = False

    if get_new:
        api_key = getenv("WEATHERAPI_API_KEY")
        url = f"http://api.weatherapi.com/v1/forecast.json?key={api_key}&q={LOCATION}&days=1&aqi=no&alerts=no"

        response = requests.get(url)

        if response.status_code == 200:
            weather_data = response.json()
            save_to_file(WEATHER_PATH, json.dumps(weather_data))
    
    forecast_day = weather_data['forecast']['forecastday'][0]['day']
    condition = forecast_day['condition']['text']
    high = forecast_day['maxtemp_c']
    low = forecast_day['mintemp_c']
    rain = forecast_day['daily_will_it_rain'] == 1
    snow = forecast_day['daily_will_it_snow'] == 1

    rain_text = "Rain is likely, " if rain else ""
    snow_text = "Snow is likely, " if snow else ""

    weather_text = f"(Weather: {condition}, high of {high}C, low of {low}C, {rain_text}{snow_text})"

    return weather_text


    

def get_context():

    context = "(CONTEXT: "

    context_array = []
    context_array.append(get_datetime())
    context_array.append(get_weather())

    context += ", ".join(context_array)

    return context

