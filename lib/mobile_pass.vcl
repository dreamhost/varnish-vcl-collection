# mobile_pass.vcl -- Mobile pass-through support for Varnish
#
# Copyright (C) 2013 DreamHost (New Dream Network, LLC)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This simply bypasses the cache for anything that looks like a mobile
# (or tablet) device.
# Also passes through some requests that are specifically for the WordPress
# Jetpack mobile plugin.
sub vcl_recv {
	# Rules specifically for the Jetpack Mobile module
	if (req.url ~ "\?(.*&)?(ak_action|app-download)=") {
		return(pass);
	}
	if (req.http.Cookie ~ "(^|;\s*)akm_mobile=") {
		return(pass);
	}

	# General User-Agent blacklist (anything that remotely looks like a mobile device)
	if (req.http.User-Agent ~ "(?i)ipod|android|blackberry|phone|mobile|kindle|silk|fennec|tablet|webos|palm|windows ce|nokia|philips|samsung|sanyo|sony|panasonic|ericsson|alcatel|series60|series40|opera mini|opera mobi|au-mic|audiovox|avantgo|blazer|danger|docomo|epoc|ericy|i-mode|ipaq|midp-|mot-|netfront|nitro|pocket|portalmmm|rover|sie-|symbian|cldc-|j2me|up\.browser|up\.link|vodafone|wap1\.|wap2\.") {
		return(pass);
	}
}
