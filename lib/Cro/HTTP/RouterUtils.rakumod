sub EXPORT(--> Map()) {
	use Cro::HTTP::Router;
	use experimental :cached;
	use Cro::HTTP::RouterUtils::Associative;

	multi endpoints(Cro::HTTP::Router::RouteSet $route = $*ROOT-ROUTE, :@prefix) is cached {
		Cro::HTTP::RouterUtils::Associative.new: $route, :@prefix
	}

	multi endpoints(Str $name, $route?) is cached {
		endpoints(|($_ with $route)){ $name } // die "EndPoint '$name' not found"
	}

	Cro::HTTP::Router::EXPORT::ALL::,
	'&route' => sub (|c) {
		my $route = route |c;
		PROCESS::<$ROOT-ROUTE> = $route;
		$route
	},
	'&endpoints' => &endpoints,
}

=begin pod

=head1 NAME

Cro::HTTP::RouterUtils - blah blah blah

=head1 SYNOPSIS

=begin code :lang<raku>

use Cro::HTTP::RouterUtils;

=end code

=head1 DESCRIPTION

Cro::HTTP::RouterUtils is ...

=head1 AUTHOR

Fernando Corrêa de Oliveira <fernando.correa@payprop.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Fernando Corrêa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
