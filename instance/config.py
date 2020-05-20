"""App instance configs"""

import os

basedir = os.path.abspath(os.path.dirname(__file__))
database_url = os.environ.get('DATABASE_URL', 'postgresql://localhost/')
database_name = os.environ.get('DATABASE_NAME', 'doubledigit_db')
dynamodb_table = os.environ.get('DYNAMODB_TABLE', 'productManuals')
dynamodb_gl_index = os.environ.get('GLOBAL_INDEX', 'pfamily-contenttype-index')
running_in_local = os.environ.get('IS_RUNNING_LOCAL', False)


class BaseConfig:
    """Base configuration."""
    # Flask APP configs
    SECRET_KEY = os.environ.get("SECRET_KEY", "\xe6.]`\x99\x07\x1ap\xff\xb7c\xf0\xea*\xba{")
    DEBUG = False
    # SQLAlchemy configs
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    # Flask-RESTPlus Configs
    ERROR_404_HELP = False


class DevelopmentConfig(BaseConfig):
    """Development configuration."""
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = database_url + database_name
    IS_RUNNING_LOCAL = True


class TestingConfig(BaseConfig):
    """Testing configuration."""
    DEBUG = True
    TESTING = True
    SQLALCHEMY_DATABASE_URI = database_url + database_name + '_test'
    PRESERVE_CONTEXT_ON_EXCEPTION = False
    IS_RUNNING_LOCAL = True


class ProductionConfig(BaseConfig):
    """Production configuration."""
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = database_url
    DYNAMODB_TABLE = dynamodb_table
    IS_RUNNING_LOCAL = running_in_local


app_config = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'production': ProductionConfig,
}
