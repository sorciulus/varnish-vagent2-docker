#
# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and http://varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;

import std;
import directors;

# Default backend definition. Set this to point to your content server.
backend ap1 {
  .host = "web";
  .port = "80";
}

acl purge_ip {
    "localhost";
    "127.0.0.1";
    "172.18.0.1";
}

sub vcl_init{
    new ws = directors.random();
    ws.add_backend(ap1, 1.0);
}


sub vcl_recv {
    # Happens before we check if we have this in cache already.
    #
    # Typically you clean up the request here, removing cookies you don't need,
    # rewriting the request, etc.

    # std.log("vcl recv: "+req.request);

    if (req.restarts == 0) {
      if (req.http.x-forwarded-for) {
          set req.http.X-Forwarded-For =
          req.http.X-Forwarded-For + ", " + client.ip;
      } else {
          set req.http.X-Forwarded-For = client.ip;
      }
    }
    set req.backend_hint = ws.backend();
    if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method != "PURGE" &&
      req.method != "BAN" &&
      req.method != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }
    if (req.method == "PURGE") {
         if (!client.ip ~ purge_ip) {             
            return(synth(403, "Not allowed"));
         }
         return (purge);
    }

    if (req.method == "BAN") {
        if (!client.ip ~ purge_ip) {             
            return(synth(403, "Not allowed"));
        }

        ban("req.http.host == " + req.http.host + " && req.url ~ " + req.url);
        return(synth(200, "Ban added"));
    }

    if (req.method != "GET" && req.method != "HEAD") {
        /* We only deal with GET and HEAD by default */
        return (pipe);
    }
    if (req.url ~ "\.(jpe?g|png|gif|pdf|gz|tgz|bz2|tbz|tar|zip|tiff|tif)$" || req.url ~ "/(image|(image_(?:[^/]|(?!view.*).+)))$") {
        return (hash);
    }
    if (req.url ~ "\.(svg|swf|ico|mp3|mp4|m4a|ogg|mov|avi|wmv|flv)$") {
        return (hash);
    }
    if (req.url ~ "\.(xls|vsd|doc|ppt|pps|vsd|doc|ppt|pps|xls|pdf|sxw|rar|odc|odb|odf|odg|odi|odp|ods|odt|sxc|sxd|sxi|sxw|dmg|torrent|deb|msi|iso|rpm)$") {
        return (hash);
    }
    if (req.url ~ "\.(css|js)$") {
        return (hash);
    }
    if (req.http.Authorization || req.http.Cookie ~ "(^|; )(__ac=|_ZopeId=)") {
        /* Not cacheable by default */
        return (pipe);
    }
    return (hash);
}


sub vcl_hash {
    hash_data(req.url);
    #if (req.http.host) {
    #    hash_data(req.http.host);
    #} else {
    #    hash_data(server.ip);
    #}
    return (lookup);
}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.
    if (bereq.url ~ "\.(jpe?g|png|gif|pdf|gz|tgz|bz2|tbz|tar|zip|tiff|tif)$" || bereq.url ~ "/(image|(image_(?:[^/]|(?!view.*).+)))$") {
        set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 6h;
    } elseif (bereq.url ~ "\.(svg|swf|ico|mp3|mp4|m4a|ogg|mov|avi|wmv|flv)$") {
        set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 6h;
    } elseif (bereq.url ~ "\.(xls|vsd|doc|ppt|pps|vsd|doc|ppt|pps|xls|pdf|sxw|rar|odc|odb|odf|odg|odi|odp|ods|odt|sxc|sxd|sxi|sxw|dmg|torrent|deb|msi|iso|rpm)$") {
        set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 6h;
    } elseif (bereq.url ~ "\.(css|js)$") {
        set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 24h;
    } else {
        set beresp.ttl = std.duration(beresp.http.age+"s",0s) + 1h;
    }

    return (deliver);
}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #
    # You can do accounting or modifying the final object here.
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
    } else {
        set resp.http.X-Cache = "MISS";
    }
}

sub vcl_synth {
    set resp.http.Content-Type = "text/html; charset=utf-8";
    set resp.http.Retry-After = "5";
    return (deliver);
}

sub vcl_purge {
    return (synth(200, "Purged"));
}