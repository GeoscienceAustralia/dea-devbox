# oauth_forward

Source code for lambda functions `oauth_forward`. This is needed to share single
GitHub authentication app across multiple jupyterhub instances. GitHub allows
customization of oauth callback url, but it can not point to a different domain.

This function returns a redirect (302). A call to this lambda like this:

`https://{amazon-allocated-id}.execute-api.ap-southeast-2.amazonaws.com/oauth/{subdomain}/rest/of/callback`

Will produce a redirect to:

`https://{subdomain}.devbox.gadevs.ga/rest/of/callback`

This way multiple jupyterhubs can use the same oauth app and still get callback
delivered to them at different address.
