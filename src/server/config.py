import pytz

class Config:
    SQLALCHEMY_DATABASE_URI = 'sqlite:///blacklist.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    DEFAULT_TIMEZONE = pytz.timezone("Europe/Berlin")
    DEFAULT_EXPIRY = 3600*12  # 12 hours
    API_KEY = "your_custom_API_KEY"
    LOG_FILE = './logs/f2b-network.log'
    SERVER_IP = '127.0.0.1'
    SERVER_PORT = 6000