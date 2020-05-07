vcl 4.0;

include "hit-miss.vcl";

import directors;
import std;

probe health_probe {
    .url = “/elb-status”;
    .timeout = 1s;
    .interval = 5s;
    .window = 5;
    .threshold = 3;
}

backend one {
    .host = “-”;
    .port = “8080”;
    .probe = health_probe;
}

backend two {
    .host = “-”;
    .port = “8080”;
    .probe = health_probe;
}

sub vcl_init {
    new www = directors.round_robin();
    www.add_backend(one);
    www.add_backend(two);
}

sub vcl_recv {
    # Happens before we check if we have this in cache already.
    #
    # Typically you clean up the request here, removing cookies you don’t need,
    # rewriting the request, etc.
    # unless sessionid/csrftoken is in the request, don’t the request   
    if (req.method == “GET” && (req.url ~ “^/static” || (req.http.cookie !~ “sessionid” && req.http.cookie !~ “csrftoken”))) {
      unset req.http.Cookie;
    }
}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.
    set beresp.ttl = 10m;
    set beresp.grace = 2h;
}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #set resp.http.X-Age = resp.http.Age;
    unset resp.http.Age;
    unset resp.http.X-Varnish;
}
