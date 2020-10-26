from peewee import *

# todo this sucks having this here and in setup_db
db = SqliteDatabase('./data/empire.db')
db.connect()


class BaseModel(Model):
    class Meta:
        database = db

# todo apparently we need to define our own __str__ methods


class Config(BaseModel):
    staging_key = TextField()
    install_path = TextField()
    ip_whitelist = TextField()
    ip_blacklist = TextField()
    autorun_command = TextField()
    autorun_data = TextField()
    rootuser = BooleanField()
    obfuscate = IntegerField()
    obfuscate_command = TextField()

    def __str__(self):
        return "%s"*9 % (
            self.staging_key,
            self.install_path,
            self.ip_whitelist,
            self.ip_blacklist,
            self.autorun_command,
            self.autorun_data,
            self.rootuser,
            self.obfuscate,
            self.obfuscate_command
        )

# try to prevent some of the weird sqlite I/O errors
# todo c.execute('PRAGMA journal_mode = OFF')


class Agents(BaseModel):
    id = PrimaryKeyField()
    session_id = TextField()
    listener = TextField()
    name = TextField()
    language = TextField()
    language_version = TextField()
    delay = IntegerField()
    jitter = FloatField()
    external_ip = TextField()
    internal_ip = TextField()
    username = TextField()
    high_integrity = IntegerField()
    process_name = TextField()
    process_id = TextField()
    hostname = TextField()
    os_details = TextField()
    session_key = TextField()
    nonce = TextField()
    checkin_time = TimestampField()
    lastseen_time = TimestampField()
    parent = TextField()
    children = TextField()
    servers = TextField()
    profile = TextField()
    functions = TextField()
    kill_date = TextField()
    working_hours = TextField()
    lost_limit = IntegerField()
    taskings = TextField()
    results = TextField()


# the 'options' field contains a pickled version of all
#   currently set listener options
class Listeners(BaseModel):
    id = PrimaryKeyField()
    name = TextField()
    module = TextField()
    listener_type = TextField(null=True)
    listener_category = TextField()
    enabled = BooleanField()
    options = BlobField()
    created_at = TimestampField()


# type = hash, plaintext, token
#   for krbtgt, the domain SID is stored in misc
#   for tokens, the data is base64'ed and stored in pass
class Credentials(BaseModel):
    id = PrimaryKeyField()
    credtype = TextField()
    domain = TextField()
    username = TextField()
    password = TextField()
    host = TextField()
    os = TextField()
    notes = TextField
    sid = TextField()


class Taskings(BaseModel):
    id = IntegerField()
    data = TextField()
    agent = TextField()
    user_id = TextField()
    timestamp = TimestampField()
    module_name = TextField()

    class Meta:
        # todo test PRIMARY KEY(id, agent)
        database = db
        primary_key = CompositeKey('id', 'agent')


class Results(BaseModel):
    id = IntegerField()
    data = TextField()
    agent = TextField()
    user_id = TextField()
    class Meta:
        # todo test PRIMARY KEY(id, agent)
        database = db
        primary_key = CompositeKey('id', 'agent')


# event_types -> checkin, task, result, rename
class Reporting(BaseModel):
    id = PrimaryKeyField()
    name = TextField()
    event_type = TextField()
    message = TextField()
    timestamp = TimestampField()
    taskID = IntegerField(null=True)
    # todo test FOREIGN KEY(taskID) REFERENCES results(id)
    results = ForeignKeyField(Results, field='id', null=True)


class Users(BaseModel):
    id = PrimaryKeyField
    username = TextField(unique=True)  # todo test unique flag
    password = TextField()
    api_token = TextField()
    last_logon_time = TimestampField()
    enabled = BooleanField()
    admin = BooleanField()


class Functions(BaseModel):
    # todo is there a reason these are capitals? Can they be lowercased?
    Keyword = TextField()
    Replacement = TextField()


class FileDirectory(BaseModel):
    class Meta:
        legacy_table_names = False

    id = PrimaryKeyField()
    session_id = TextField()
    name = TextField()
    path = TextField()
    parent_id = IntegerField(null=True)
    is_file = BooleanField()
    # todo test FOREIGN KEY (parent_id) REFERENCES file_directory(id) ON DELETE CASCADE
    file_directory = ForeignKeyField('self', null=True, backref='children', on_delete='CASCADE')