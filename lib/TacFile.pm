package TacFile;

use Dancer ':syntax';
use File::ReadBackwards;
use File::Slurp;

our $VERSION = '0.1';

sub get_files {
        my @files = sort(read_dir( config->{data_dir} ));

        return { files => \@files };
}

sub send_file_backwards {
        my ( $respond, $resp ) = @_;

        my $fh = File::ReadBackwards->new( vars->{filepath} ) or
                send_error "unable to open file for read: $!";

        my $writer = $respond->( [ 200, $resp->headers_to_array ] );
        until ( $fh->eof ) {
                $writer->write( $fh->readline );
        }
}

get '/files/:filename' => sub {
        my $fn = params->{filename};

        if ( ! grep /^$fn$/, @{ get_files->{files} } ) {
                status 'not_found';
                return { error => 'Invalid file: '.params->{filename} };
        }
        vars->{filepath} = path(config->{data_dir}, $fn);

        my $opts = {
                system_path => 1,
                streaming => 1,
        };

        if ( exists(params->{output_direction}) && params->{output_direction} eq 'reverse' ) {
                $opts->{callbacks} = { override => \&send_file_backwards };
        } 
        return send_file( vars->{filepath}, %{ $opts } );
};

get '/files' => \&get_files;

any qr{.*} => sub {
        status 'not_found';
        return { error => 'Invalid request' };
};

true;
