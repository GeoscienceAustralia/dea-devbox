import os
import sys

def system_user_exists(username):
    import pwd
    try:
        pwd.getpwnam(username)
    except KeyError:
        return False

    return True

def create_new_user(username, admin=False):
    from subprocess import check_call, CalledProcessError

    try:
        check_call(['adduser',
                    '-q',
                    '--disabled-password',
                    '--gecos', '""',
                    '--home', '/hub/{username}'.format(username=username),
                    username])
    except CalledProcessError:
        return False

    #TODO: database account set up for the user
    return True


def pre_spawn_hook(spawner):
    if system_user_exists(spawner.user.name):
        return

    spawner.log.info('Creating system user: %s%s',
                     spawner.user.name,
                     '[admin]' if spawner.user.admin else "")
    create_new_user(spawner.user.name, spawner.user.admin)

c = get_config()

oauth_callback = os.environ.get('OAUTH_CALLBACK_URL')
admin_user = os.environ.get('ADMIN_USER')

if oauth_callback is None or admin_user is None:
    print('Missing environment')
    sys.exit(1)

if not oauth_callback.endswith('/hub/oauth_callback'):
    oauth_callback += '/hub/oauth_callback'

data_dir = '/var/lib/jupyterhub'

# Hub
c.JupyterHub.hub_ip = '127.0.0.1'
c.JupyterHub.hub_port = 8080
c.JupyterHub.cookie_secret_file = data_dir + '/jupyterhub_cookie_secret'
c.JupyterHub.db_url = data_dir + '/jupyterhub.sqlite'

# Spawner: create system users on the fly
c.Spawner.pre_spawn_hook = pre_spawn_hook

# Authenticate users with GitHub OAuth
c.JupyterHub.authenticator_class = 'oauthenticator.GitHubOAuthenticator'
c.GitHubOAuthenticator.oauth_callback_url = oauth_callback

# Whitlelist users and admins
c.Authenticator.whitelist = {admin_user}
c.Authenticator.admin_users = {admin_user}
c.JupyterHub.admin_access = True
