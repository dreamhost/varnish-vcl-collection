# bigfiles_pipe.vcl -- Pipe for Large Files
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

# You must have "import std;" in your main vcl:
# import std;

# NOTE: Using restart and pipe is a workaround for a bug in varnish prior to
# 3.0.3.  In 3.0.3+, hit_for_pass in vcl_fetch is all that is necessary.
sub vcl_recv {
	if (req.http.X-Pipe-Big-File && req.restarts > 0) {
		unset req.http.X-Pipe-Big-File;
		return (pipe);
	}
}

sub vcl_fetch {
	# Bypass cache for files > 10 MB
	if (std.integer(beresp.http.Content-Length, 0) > 10485760) {
		set req.http.X-Pipe-Big-File = "Yes";
		return (restart);
	}
}
