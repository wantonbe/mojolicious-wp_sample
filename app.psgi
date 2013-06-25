#!/usr/bin/env perl

use File::Spec;
use Mojo::Server::PSGI;
use Plack::Builder;

builder {
	enable 'Head';
	enable 'StackTrace';
	enable "ConditionalGET";
	enable 'Expires',
		content_type => [ 'text/css', 'application/javascript', qr!^image/!],
		expires => 'access plus 3 days';
	enable 'Static',
		path => qr!favicon\.ico$|static/!,
		root => File::Spec->rel2abs("./public");
	mount '/' => Mojo::Server::PSGI->new->load_app( File::Spec->rel2abs("./public/index.pl") )->start;
};
__END__
