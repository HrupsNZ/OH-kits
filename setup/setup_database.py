#!/usr/bin/env python3

from __future__ import print_function

import hashlib
import os
import random
import string
from builtins import input
from builtins import range
from datetime import datetime

import bcrypt
from peewee import SqliteDatabase

from data.models import Config, Agents, Listeners, Credentials, Taskings, Results, Reporting, Users, Functions, FileDirectory

###################################################
#
# Default values for the config
#
###################################################

# Staging Key is set up via environmental variable
# or via command line. By setting RANDOM a randomly
# selected password will automatically be selected
# or it can be set to any bash acceptable character
# set for a password.

STAGING_KEY = os.getenv('STAGING_KEY', "BLANK")
punctuation = '!#%&()*+,-./:;<=>?@[]^_{|}~'

# otherwise prompt the user for a set value to hash for the negotiation password
if STAGING_KEY == "BLANK":
    choice = input("\n [>] Enter server negotiation password, enter for random generation: ")
    if choice == "":
        # if no password is entered, generation something random
        STAGING_KEY = ''.join(random.sample(string.ascii_letters + string.digits + punctuation, 32))
    else:
        STAGING_KEY = hashlib.md5(choice.encode('utf-8')).hexdigest()
elif STAGING_KEY == "RANDOM":
    STAGING_KEY = ''.join(random.sample(string.ascii_letters + string.digits + punctuation, 32))

# Calculate the install path. We know the project directory will always be the parent of the current directory. Any modifications of the folder structure will
# need to be applied here.
INSTALL_PATH = os.path.dirname(os.path.dirname(os.path.realpath(__file__))) + "/"

# an IP white list to ONLY accept clients from
#   format is "192.168.1.1,192.168.1.10-192.168.1.100,10.0.0.0/8"
IP_WHITELIST = ""

# an IP black list to reject accept clients from
#   format is "192.168.1.1,192.168.1.10-192.168.1.100,10.0.0.0/8"
IP_BLACKLIST = ""

# default credentials used to log into the RESTful API
API_USERNAME = "empireadmin"
API_PASSWORD = bcrypt.hashpw(b"password123", bcrypt.gensalt())

# default obfuscation setting
OBFUSCATE = 0

# default obfuscation command
OBFUSCATE_COMMAND = r'Token\All\1'

db = SqliteDatabase('%s/data/empire.db' % INSTALL_PATH)
db.connect()


db.create_tables([Config, Agents, Listeners, Credentials, Taskings, Results, Reporting, Users, Functions, FileDirectory])


# todo remove debug prints
from playhouse.reflection import print_table_sql
print_table_sql(Users)
print_table_sql(Config)
print_table_sql(Agents)
print_table_sql(Listeners)
print_table_sql(Credentials)
print_table_sql(Taskings)
print_table_sql(Results)
print_table_sql(Reporting)
print_table_sql(Users)
print_table_sql(Functions)
print_table_sql(FileDirectory)


Config.create(
    staging_key=STAGING_KEY,
    install_path=INSTALL_PATH,
    ip_whitelist=IP_WHITELIST,
    ip_blacklist=IP_BLACKLIST,
    autorun_command='',
    autorun_data='',
    rootuser=False,
    obfuscate=OBFUSCATE,
    obfuscate_command=OBFUSCATE_COMMAND
)


Users.create(
    id="1",
    username=API_USERNAME,
    password=API_PASSWORD,
    api_token="",
    last_logon_time=datetime.today(),
    enabled=True,
    admin=True
)


rand1 = random.choice(string.ascii_uppercase) + ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(4))
rand2 = random.choice(string.ascii_uppercase) + ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(4))
Functions.create(Keyword='Invoke-Mimikatz', Replacement=rand1)
Functions.create(Keyword='Invoke-Empire', Replacement=rand2)


# commit the changes and close everything off
db.commit()
db.close()

print("\n [*] Database setup completed!\n")
