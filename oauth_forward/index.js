const querystring = require('querystring');

exports.redirect = (event, context, callback) => {

    const [_, host, ...rest] = event.path.split('/');

    const redirect_location = ('https://'+host+'.dea.gadevs.ga/' +
                               rest.join('/') +
                               '?' + querystring.stringify(event.queryStringParameters));

    // redirect response
    callback(null, {
        statusCode: 302,
        headers: {
            "Location" : redirect_location
        },
        body: ''
    });
};
