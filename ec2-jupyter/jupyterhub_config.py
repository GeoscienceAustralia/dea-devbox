import os
import sys

def check_user(username):
    import pwd
    from subprocess import check_call, CalledProcessError

    try:
        pwd.getpwnam(username)
        return True
    except KeyError:
        pass

    try:
        check_call(['adduser',
                    '-q',
                    '--disabled-password',
                    '--gecos', '""',
                    '--home', '/hub/{username}'.format(username=username),
                    username])
    except CalledProcessError:
        return False


c = get_config()

oauth_callback = os.environ.get('OAUTH_CALLBACK_URL')
admin_user = os.environ.get('ADMIN_USER')

if oauth_callback is None or admin_user is None:
    print('Missing environment')
    sys.exit(1)

if not oauth_callback.endswith('/hub/oauth_callback'):
    oauth_callback += '/hub/oauth_callback'

check_user(admin_user)

data_dir = '/var/lib/jupyterhub'

# Hub
c.JupyterHub.hub_ip = '127.0.0.1'
c.JupyterHub.hub_port = 8080
c.JupyterHub.cookie_secret_file = data_dir + '/jupyterhub_cookie_secret'
c.JupyterHub.db_url = data_dir + '/jupyterhub.sqlite'

# Authenticate users with GitHub OAuth
c.JupyterHub.authenticator_class = 'oauthenticator.GitHubOAuthenticator'
c.GitHubOAuthenticator.oauth_callback_url = oauth_callback

# Whitlelist users and admins
c.Authenticator.whitelist = set([admin_user])
c.Authenticator.admin_users = set([admin_user])
c.JupyterHub.admin_access = True
