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

full_domain_name = os.environ.get('DOMAIN')
admin_user = os.environ.get('ADMIN_USER')

if full_domain_name is None or admin_user is None:
    print('Missing environment')
    sys.exit(1)

check_user(admin_user)

data_dir = '/var/lib/jupyterhub'
hostname = full_domain_name.split('.')[0]
oauth_base = 'https://8ova40okdl.execute-api.ap-southeast-2.amazonaws.com/oauth'

# Hub
c.JupyterHub.hub_ip = '127.0.0.1'
c.JupyterHub.hub_port = 8080
c.JupyterHub.cookie_secret_file = data_dir + '/jupyterhub_cookie_secret'
c.JupyterHub.db_url = data_dir + '/jupyterhub.sqlite'

# Authenticate users with GitHub OAuth
c.JupyterHub.authenticator_class = 'oauthenticator.GitHubOAuthenticator'
c.GitHubOAuthenticator.oauth_callback_url = (oauth_base +
                                             '/' + hostname +
                                             '/hub/oauth_callback')

# Whitlelist users and admins
c.Authenticator.whitelist = set([admin_user])
c.Authenticator.admin_users = set([admin_user])
c.JupyterHub.admin_access = True
