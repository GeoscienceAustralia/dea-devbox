from . import maybe_ssm, system_user_exists
import os
import sys


def create_new_user(username, admin, logger):
    from subprocess import check_call, CalledProcessError
    from pathlib import Path

    def maybe_run_hook():
        new_user_hook = os.environ.get('NEW_USER_HOOK', None)

        if new_user_hook is None:
            return
        if not Path(new_user_hook).exists():
            logger.warning("NEW_USER_HOOK is configured but doesn't exists: %s", new_user_hook)
            return

        logger.info("About to run new user hook: %s", new_user_hook)

        try:
            check_call([new_user_hook,
                        username] +
                       (['admin'] if admin else []))
        except CalledProcessError:
            return

    try:
        check_call(['adduser',
                    '-q',
                    '--disabled-password',
                    '--gecos', '""',
                    '--home', '/hub/{username}'.format(username=username),
                    username])
    except CalledProcessError:
        return False

    maybe_run_hook()

    return True


def pre_spawn_hook(spawner):
    if system_user_exists(spawner.user.name):
        return

    spawner.log.info('Creating system user: %s%s',
                     spawner.user.name,
                     '[admin]' if spawner.user.admin else "")
    create_new_user(spawner.user.name, spawner.user.admin, spawner.log)


def jhub_config(c,
                data_dir='/var/lib/jupyterhub',
                admin_access=True,
                port=8080,
                ip='127.0.0.1'):
    params = [os.environ.get(n) for n in ['OAUTH_CLIENT_ID',
                                          'OAUTH_CLIENT_SECRET',
                                          'OAUTH_CALLBACK_URL',
                                          'ADMIN_USER']]

    if None in params:
        print('Missing environment')
        sys.exit(1)

    (oauth_client_id,
     oauth_client_secret,
     oauth_callback_url,
     admin_user) = maybe_ssm(*params)

    oauth_callback_url = oauth_callback_url.rstrip('/') + '/'
    oauth_callback_url += os.environ.get('OAUTH_CALLBACK_POSTFIX', '')
    oauth_callback_url = oauth_callback_url.rstrip('/')

    if not oauth_callback_url.endswith('/hub/oauth_callback'):
        oauth_callback_url += '/hub/oauth_callback'

    # Hub
    c.JupyterHub.hub_ip = ip
    c.JupyterHub.hub_port = port
    c.JupyterHub.cookie_secret_file = data_dir + '/jupyterhub_cookie_secret'
    c.JupyterHub.db_url = data_dir + '/jupyterhub.sqlite'

    # Spawner: create system users on the fly
    c.Spawner.pre_spawn_hook = pre_spawn_hook

    # Authenticate users with GitHub OAuth
    c.JupyterHub.authenticator_class = 'oauthenticator.GitHubOAuthenticator'
    c.GitHubOAuthenticator.client_id = oauth_client_id
    c.GitHubOAuthenticator.client_secret = oauth_client_secret
    c.GitHubOAuthenticator.oauth_callback_url = oauth_callback_url

    # Whitlelist users and admins
    c.Authenticator.whitelist = {admin_user}
    c.Authenticator.admin_users = {admin_user}
    c.JupyterHub.admin_access = admin_access
