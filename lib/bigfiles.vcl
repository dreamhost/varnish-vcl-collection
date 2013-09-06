# bigfiles.vcl -- Bypass Cache for Large Files
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

sub vcl_fetch {
	# Bypass cache for files > 10 MB
	if (std.integer(beresp.http.Content-Length, 0) > 10485760) {
		return (hit_for_pass);
	}
}
