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

Cro::HTTP::RouterUtils - Utilities for Cro::HTTP::Router to reference endpoints, build URLs and HTMX attributes

=head1 SYNOPSIS

=begin code :lang<raku>
use Cro::HTTP::RouterUtils;
use Cro::HTTP::Server;

my $app = route {
    # Named endpoint (preferred)
    get my sub greet-path('greet', $name) {
        content 'text/plain', "Hello, $name!";
    }

    # Using the endpoint to render links/forms
    get -> 'form' {
        my $ep = endpoints('greet-path'); # resolve by name
        content 'text/html', qq:to/HTML/;
            <form action='{ $ep.path(:name<World>) }' method='{ $ep.method }'>
                <input type='text' name='name'>
                <input type='submit' value='ok'>
            </form>
            <a href='#' { $ep.hx-attrs(:name<Bob>) }>HTMX link</a>
        HTML
    }
};

my $svc = Cro::HTTP::Server.new(:host<127.0.0.1>, :port(10000), :$app).start;
=end code

=head1 INSTALLATION

=begin code :lang<sh>
zef install Cro::HTTP::RouterUtils
=end code

Requires Rakudo 6.d+. Dependencies (Cro::HTTP, Hash::Agnostic) are installed automatically.

=head1 DESCRIPTION

Cro::HTTP::RouterUtils lets you discover and I<use> your Cro routes from code and templates.
It exports a small helper to capture the root route and a function that resolves endpoints into
objects that know how to build URLs, redirect, generate HTMX attributes, and even call the
underlying implementation.

=head1 USAGE

=head2 Exported symbols

=over 4

=item * C<route>

Same as C<Cro::HTTP::Router::route>, but also stores the created route set in C<$*ROOT-ROUTE>,
so C<endpoints> can find your handlers without extra plumbing.

=item * C<endpoints>

- C<endpoints($name, $route?)> → C<Cro::HTTP::RouterUtils::EndPoint> (throws if not found)
- C<endpoints($route = $*ROOT-ROUTE, :@prefix)> → associative map of endpoints (lazy)

=back

=head2 Referencing endpoints

- I<By explicit name> (recommended): name the implementation and use that name.

=begin code :lang<raku>
get my sub greet-path('greet', $name) { ... }
my $ep = endpoints('greet-path');
=end code

- I<Auto-named> (when you don't name it): use C<"<method>_<segments>">, where segments are
literal parts and positional params. For example:

=begin code :lang<raku>
get -> 'greet', Str :$name { ... }
my $ep = endpoints('get_greet');
=end code

- I<Included routes>: when using C<include prefix => route>, the prefix affects the built path
only; the endpoint name remains the one defined by the included route.

=head2 Building URLs (with type safety)

=begin code :lang<raku>
my $ep = endpoints('greet-path');
$ep.path(:name<alice>);  # "/greet/alice"
$ep.method;              # "GET"
=end code

Required/typed parameters are validated; a helpful exception is thrown for missing/wrong types.

=head2 Redirecting

=begin code :lang<raku>
get -> 'redir' {
    endpoints('greet-path').redirect-to: :name<ok>;
}
=end code

=head2 HTMX helpers

=begin code :lang<raku>
endpoints('greet-path').hx-attrs(:name<bob>, :trigger<click>, :target<#out>);
# -> "hx-get='/greet/bob' hx-trigger='click' hx-target='#out'"

# Override the HTTP method if needed
endpoints('greet-path').hx-attrs(:name<bob>, :method<post>);
# -> "hx-post='/greet/bob'"
=end code

You may pass most HTMX options (e.g. C<:confirm>, C<:swap>, C<:vals>, C<:headers>, C<:push-url>,
C<:replace-url>, etc.). Boolean options are rendered as C<'true'> per HTMX conventions.

=head2 Programmatic call

=begin code :lang<raku>
endpoints('sum').call(2, 3);  # -> 5
=end code

=head1 API

=head2 Class C<Cro::HTTP::RouterUtils::EndPoint>

- C<method method> → Str: the HTTP method (GET/POST/...)
- C<method path(*%values)> → Str: builds the URL, validating typed params
- C<method redirect-to(*%values)>: emits a Cro redirect to the built path
- C<method hx-attrs(..., *%pars)> → Str: returns an attribute string suitable for HTMX
- C<method call(|c)>: calls the underlying implementation (useful for tests/PL)

=head1 SEE ALSO

L<Cro::HTTP::Router>, L<Cro::HTTP>

=head1 AUTHOR

Fernando Corrêa de Oliveira <fernando.correa@payprop.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Fernando Corrêa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
