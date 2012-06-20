use Test::More import => ['!set'];
use strict;
use warnings;

# the order is important
use TacFile;
use Dancer qw/:syntax !pass/;
use Dancer::Test;

set data_dir => 't/data';
set serialization => 'JSON';

plan skip_all => "Test::TCP is required"
  unless Dancer::ModuleLoader->load('Test::TCP');

plan skip_all => "Plack is required"
  unless Dancer::ModuleLoader->load('Plack::Loader');

plan tests => 7;

route_exists [GET => '/files/file1.txt'], 'a route handler is defined for /files';

require HTTP::Request;
require LWP::UserAgent;
 
Test::TCP::test_tcp(
    client => sub {
        my $port = shift;
        my $req =
          HTTP::Request->new(
            GET => "http://127.0.0.1:$port/files/file1.txt" );
        my $ua  = LWP::UserAgent->new();
        my $res = $ua->request($req);
        ok $res->is_success;
        is $res->code, 200;
        is $res->content, "1\n2\n3\n4\n5\n";

	# Try getting the file in reverse.
        $req =
          HTTP::Request->new(
            GET => "http://127.0.0.1:$port/files/file1.txt?output_direction=reverse" );
        $ua  = LWP::UserAgent->new();
        $res = $ua->request($req);
        ok $res->is_success;
        is $res->code, 200;
        is $res->content, "5\n4\n3\n2\n1\n";
    },
    server => sub {
        my $port = shift;
        setting apphandler => 'PSGI';
        Dancer::Config->load;
        my $app = Dancer::Handler->psgi_app;
        Plack::Loader->auto( port => $port )->run($app);
        Dancer->dance();
    }
);
