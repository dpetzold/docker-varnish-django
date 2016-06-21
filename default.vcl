vcl 4.0;

backend default {
    .host = "${VARNISH_BACKEND_IP}";
    .port = "${VARNISH_BACKEND_PORT}";
}

sub vcl_recv {  
    if (!(req.url ~ "^/admin/")) {
        unset req.http.Cookie;  
    }  
}  
