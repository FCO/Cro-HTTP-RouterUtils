sub EXPORT(--> Map()) {
	use Cro::HTTP::Router;
	use experimental :cached;
	multi endpoints(Cro::HTTP::Router::RouteSet $route = $*ROOT-ROUTE, :@prefix --> Map()) is cached {
		|do for $route.handlers[] -> $handler (:implementation(&impl), |) {
			my %hash =
				:$handler,
				:path[
					|@prefix,
					|&impl.signature.params.grep({ !.named })
					.duckmap(-> $p where { .constraint_list } {
						$p.constraint_list.head
					})
					.duckmap(-> Parameter $p {
						$p.name.substr(1) => $p.type
					})
				]
			;
			|($_ => %hash with &impl.?name),
			(
				$handler.method.lc,
				|@prefix,
				|$handler.signature.params.grep({ !.named }).map({ .constraint_list.head // .name }),
			).join("_") => %hash

		},
		|do for $route.includes[] -> % ( :$includee, :prefix(@p) ) {
			do for endpoints($includee, :prefix[|@prefix, |@p]).kv -> Str $name, % ( :$handler, :@path ) {
				$name => %( :$handler, :path[|@prefix, |@path] )
			}
		},
	}

	multi endpoints(Str $name, $route?) is cached {
		class EndPoint {
			has $.data is required;
			method method {
				$.data.<handler>.method
			}
			method call(|c) {
				$.data.<handler>.implementation.(|c)
			}
			method path(*%values) {
				my @path = $.data.<path>[];
				"/" ~ (
					@path.map({
						do if $_ ~~ Str {
							.Str
						} else {
							my (:$key, :value($type)) := .<>;
							die "Parameter '$key' is required" unless %values{$key}:exists;
							die "Expected $type.^name() for param $key but received {%values{$key}.^name}" unless %values{$key} ~~ $type;
							%values{$key}
						}
					}).join: "/"
				)
			}
			method redirect-to(*%values) {
				redirect $.path: |%values
			}
			method hx-attrs(
				Str  :$trigger,
				Str  :$target,
				Str  :$confirm,
				Str  :$indicator,
				Bool :$oob   = False,
				Bool :$boost = False,
				*%pars,
			) {
				[
					"hx-{ $.method.lc }='{$.path: |%pars}'",
					|("hx-trigger='$_'"    with $trigger  ),
					|("hx-target='$_'"     with $target   ),
					|("hx-confirm='$_'"    with $confirm  ),
					|("hx-indicator='$_'"  with $indicator),
					|("hx-swap-oob='true'" if $oob        ),
					|("hx-boost='true'"    if $boost      ),
				].join: " "
			}
		}.new: :data( endpoints(|($_ with $route)){ $name } // die "EndPoint '$name' not found" )
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
