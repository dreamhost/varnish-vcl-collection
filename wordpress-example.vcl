vcl 4.0;

backend default {
	.host = "127.0.0.1";
	.port = "8080";
}

import std;

include "lib/xforward.vcl";
include "lib/cloudflare.vcl";
include "lib/purge.vcl";
include "lib/bigfiles.vcl";        # Varnish 3.0.3+
#include "lib/bigfiles_pipe.vcl";  # Varnish 3.0.2
include "lib/static.vcl";

acl cloudflare {
	# set this ip to your Railgun IP (if applicable)
	# "1.2.3.4";
}

acl purge {
	"localhost";
	"127.0.0.1";
}

# Pick just one of the following:
# (or don't use either of these if your application is "adaptive")
# include "lib/mobile_cache.vcl";
# include "lib/mobile_pass.vcl";

### WordPress-specific config ###
# This config was initially derived from the work of Donncha Ó Caoimh:
# http://ocaoimh.ie/2011/08/09/speed-up-wordpress-with-apache-and-varnish/
sub vcl_recv {
	# pipe on weird http methods
	if (req.method !~ "^GET|HEAD|PUT|POST|TRACE|OPTIONS|DELETE$") {
		return(pipe);
	}

	### Check for reasons to bypass the cache!
	# never cache anything except GET/HEAD
	if (req.method != "GET" && req.method != "HEAD") {
		return(pass);
	}
	# don't cache logged-in users or authors
	if (req.http.Cookie ~ "wp-postpass_|wordpress_logged_in_|comment_author|PHPSESSID") {
		return(pass);
	}
	# don't cache ajax requests
	if (req.http.X-Requested-With == "XMLHttpRequest") {
		return(pass);
	}
	# don't cache these special pages
	if (req.url ~ "nocache|wp-admin|wp-(comments-post|login|activate|mail)\.php|bb-admin|server-status|control\.php|bb-login\.php|bb-reset-password\.php|register\.php") {
		return(pass);
	}

	### looks like we might actually cache it!
	# fix up the request
	set req.grace = 2m;
	set req.url = regsub(req.url, "\?replytocom=.*$", "");

	# Remove has_js, Google Analytics __*, and wooTracker cookies.
	set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(__[a-z]+|has_js|wooTracker)=[^;]*", "");
	set req.http.Cookie = regsub(req.http.Cookie, "^;\s*", "");
	if (req.http.Cookie ~ "^\s*$") {
		unset req.http.Cookie;
	}

	return(hash);
}

sub vcl_hash {
	# Add the browser cookie only if a WordPress cookie found.
	if (req.http.Cookie ~ "wp-postpass_|wordpress_logged_in_|comment_author|PHPSESSID") {
		hash_data(req.http.Cookie);
	}
}

sub vcl_backend_response {
	# make sure grace is at least 2 minutes
	if (beresp.grace < 2m) {
		set beresp.grace = 2m;
	}

	# catch obvious reasons we can't cache
	if (beresp.http.Set-Cookie) {
		set beresp.ttl = 0s;
	}

	# Varnish determined the object was not cacheable
	if (beresp.ttl <= 0s) {
		set beresp.http.X-Cacheable = "NO:Not Cacheable";
		set beresp.uncacheable = true;
		return (deliver);

	# You don't wish to cache content for logged in users
	} else if (bereq.http.Cookie ~ "wp-postpass_|wordpress_logged_in_|comment_author|PHPSESSID") {
		set beresp.http.X-Cacheable = "NO:Got Session";
		set beresp.uncacheable = true;
		return (deliver);

	# You are respecting the Cache-Control=private header from the backend
	} else if (beresp.http.Cache-Control ~ "private") {
		set beresp.http.X-Cacheable = "NO:Cache-Control=private";
		set beresp.uncacheable = true;
		return (deliver);

	# You are extending the lifetime of the object artificially
	} else if (beresp.ttl < 300s) {
		set beresp.ttl   = 300s;
		set beresp.grace = 300s;
		set beresp.http.X-Cacheable = "YES:Forced";

	# Varnish determined the object was cacheable
	} else {
		set beresp.http.X-Cacheable = "YES";
	}

	# Avoid caching error responses
	if (beresp.status == 404 || beresp.status >= 500) {
		set beresp.ttl   = 0s;
		set beresp.grace = 15s;
	}

	# Deliver the content
	return(deliver);
}
