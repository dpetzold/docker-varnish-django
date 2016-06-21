vcl 4.0;

import named;
import std;

acl local {
  "localhost";
  "10"/8; 
}

# Varish will error with no backends or directors defined without this.
backend default {
  .host = "${VARNISH_BACKEND_IP}";
  .port = "${VARNISH_BACKEND_PORT}";
}

sub vcl_init {
	new www_dir = named.director(
		port = "80",
		ttl = 5m,
  );
}

sub vcl_hit {
    if (obj.ttl >= 0s) {
        # normal hit
        return (deliver);
    }
    # We have no fresh fish. Lets look at the stale ones.
    if (std.healthy(req.backend_hint)) {
        # Backend is healthy. Limit age to 10s.
        if (obj.ttl + 10s > 0s) {
            set req.http.grace = "normal(limited)";
            return (deliver);
        } else {
            # No candidate for grace. Fetch a fresh object.
            return(fetch);
        }
    } else {
        # backend is sick - use full grace
        if (obj.ttl + obj.grace > 0s) {
            set req.http.grace = "full";
            return (deliver);
        } else {
            # no graced object.
            return (fetch);
        }
    }
}

sub vcl_deliver {
    # copy to resp so we can tell from the outside.
    set resp.http.grace = req.http.grace;
}

sub vcl_recv {
	set req.backend_hint = www_dir.backend("${VARNISH_NAMED_BACKEND}");
  set req.http.grace = "none";

	# Normalize the query arguments
  set req.url = std.querysort(req.url);

	# Pass health checks.
  if (req.url == "${HEALTH_CHECK_URL}" && client.ip ~ local) {
    set req.http.host = "${NORMALIZED_HOST}";
    return (pass);
  }

  if (req.url ~ "${ADMIN_URL}") {
    return (pass);
  }

  if (req.method == "GET" || req.method == "HEAD") {
    unset req.http.Cookie;  
  } else {
		return (pass);
  }

  if (${ALLOWED_HOSTS_CHECK}) {
    # Normalize the host header
    set req.http.host = "${NORMALIZED_HOST}";
  } else {
    return (synth(400, "Bad request"));
  }

	if (req.http.Authorization) {
    # Not cacheable by default
    return (pass);
  }

	return (hash);
}  

# The data on which the hashing will take place
sub vcl_hash {
  # Called after vcl_recv to create a hash value for the request. This is used as a key
  # to look up the object in Varnish.

  hash_data(req.url);

  if (req.http.host) {
    hash_data(req.http.host);
  } else {
    hash_data(server.ip);
  }

  # hash cookies for requests that have them
  if (req.http.Cookie) {
    hash_data(req.http.Cookie);
  }
}

sub vcl_deliver {
  if (obj.hits > 0) {
    set resp.http.X-Cache = "HIT";
  } else {
    set resp.http.X-Cache = "MISS";
  }

  set resp.http.X-Cache-Hits = obj.hits;
  return (deliver);
}

sub vcl_backend_response {
  # Don't cache 50x responses
  if (beresp.status == 500 || beresp.status == 502 || beresp.status == 503 || beresp.status == 504) {
    return (abandon);
  }

  # Allow stale content, in case the backend goes down.
  # make Varnish keep all objects for 6 hours beyond their TTL
  set beresp.grace = 6h;

  if (bereq.method == "GET") {
    unset beresp.http.set-cookie;
   	set beresp.ttl = 6h;
  }
  return (deliver);
}
