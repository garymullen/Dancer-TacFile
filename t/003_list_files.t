use Test::More tests => 3, import => ['!set'];
use strict;
use warnings;

# the order is important
use TacFile;
use Dancer qw/:syntax !pass/;
use Dancer::Test;

set data_dir => 't/data';
set serialization => 'JSON';

route_exists [GET => '/files'], 'a route handler is defined for /files';
response_status_is ['GET' => '/files'], 200, 'response status is 200 for /files';

response_content_is [GET => '/files'], 
    to_json({ files => [ 'file1.txt', 'file2.txt' ] }), 
    "got expected response structure for GET /files";
