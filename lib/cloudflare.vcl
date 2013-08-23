# cloudflare.vcl -- CloudFlare HTTP Headers
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

# This should generally be loaded first to make sure that the headers
# get set appropriately for all requests.

acl official_cloudflare {
	# https://www.cloudflare.com/ips-v4
	"204.93.240.0"/24;
	"204.93.177.0"/24;
	"199.27.128.0"/21;
	"173.245.48.0"/20;
	"103.21.244.0"/22;
	"103.22.200.0"/22;
	"103.31.4.0"/22;
	"141.101.64.0"/18;
	"108.162.192.0"/18;
	"190.93.240.0"/20;
	"188.114.96.0"/20;
	"197.234.240.0"/22;
	"198.41.128.0"/17;
	"162.158.0.0"/15;
	# https://www.cloudflare.com/ips-v6
	"2400:cb00::"/32;
	"2606:4700::"/32;
	"2803:f800::"/32;
	"2405:b500::"/32;
	"2405:8100::"/32;
}

sub vcl_recv {
	# Set the CF-Connecting-IP header
	# If the client.ip is trusted, we leave the header alone if present.
	if (req.http.CF-Connecting-IP) {
		if (client.ip !~ official_cloudflare && client.ip !~ cloudflare) {
			set req.http.CF-Connecting-IP = client.ip;
		}
	} else {
		set req.http.CF-Connecting-IP = client.ip;
	}
}
