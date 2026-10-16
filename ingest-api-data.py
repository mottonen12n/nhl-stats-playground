import requests
import json
from datetime import datetime, timedelta
from snowflake.snowpark import Session
import sys
import pytz
import logging
import os

# initiate logging at info level
logging.basicConfig(stream=sys.stdout, level=logging.INFO, format='%(levelname)s - %(message)s')

# Set the time zone
timezone = pytz.timezone('America/Phoenix')

# Get the current time in IST
current_time = datetime.now(timezone)

# Format the timestamp
timestamp = current_time.strftime('%Y_%m_%d_%H_%M_%S')
yesterday_string = (current_time - timedelta(days=1)).strftime('%Y-%m-%d')

# Create the file name
file_name = f'nhl_standings_data_{yesterday_string}.json'



# Following credential has to come using secret whie running in automated way
def snowpark_basic_auth() -> Session:
    connection_parameters = {
       "ACCOUNT":os.getenv('SNOWFLAKE_ACCOUNT'),
       #"region":os.getenv('SNOWFLAKE_REGION'),
        "USER":os.getenv('SNOWFLAKE_USER'),
        "PASSWORD":os.getenv('SNOWFLAKE_PASSWORD'),
        "ROLE":"SYSADMIN",
        "DATABASE":"dev_db_us",
        "SCHEMA":"stage_sch",
        "WAREHOUSE":"load_wh"
    }
    # creating snowflake session object
    return Session.builder.configs(connection_parameters).create()


def get_daily_nhl_standings_data():
    api_url = f'https://api-web.nhle.com/v1/standings/{yesterday_string}'
    
    # Parameters for the API request
    #params = {
    #    'api-key': api_key,
    #    'format': 'json',
    #    'limit': limit
    #}

    # Headers for the API request
    headers = {
        'accept': 'application/json'
    }

    try:
        # Make the GET request
        response = requests.get(api_url, headers=headers)

        logging.info('Got the response, check if 200 or not')
        # Check if the request was successful (status code 200)
        if response.status_code == 200:

            logging.info('Got the JSON Data')
            # Parse the JSON data from the response
            json_data = response.json()


            logging.info('Writing the JSON file into local location before it moved to snowflake stage')
            # Save the JSON data to a file
            with open(file_name, 'w') as json_file:
                json.dump(json_data, json_file, indent=2)

            logging.info(f'File Written to local disk with name: {file_name}')
            
            stg_location = '@dev_db_us.stage_sch.raw_stg/standings/'+yesterday_string+'/'
            sf_session = snowpark_basic_auth()
            
            logging.info(f'Placing the file, the file name is {file_name} and stage location is {stg_location}')
            sf_session.file.put(file_name, stg_location)
            
            logging.info('JSON File placed successfully in stage location in snowflake')
            lst_query = f'list {stg_location}{file_name}.gz'
            
            logging.info(f'list query to fetch the stage file to check if they exist there or not = {lst_query}')
            result_lst = sf_session.sql(lst_query).collect()
            
            logging.info(f'File is placed in snowflake stage location= {result_lst}')
            logging.info('The job over successfully...')
            
            # Return the retrieved data
            return json_data

        else:
            # Print an error message if the request was unsuccessful
            logging.error(f"Error: {response.status_code} - {response.text}")
            sys.exit(1)
            #return None

    except Exception as e:
        # Handle exceptions, if any
        logging.error(f"An error occurred: {e}")
        sys.exit(1)
        #return None
    #if comes to this line.. it will return nothing
    return None

# Replace 'YOUR_API_KEY' with your actual API key
#api_key = '<add-app-api-key>'


#limit_value = 4000
air_quality_data = get_daily_nhl_standings_data()