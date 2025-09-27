use Hash::Agnostic;
use Cro::HTTP::RouterUtils::EndPoint;
unit class Cro::HTTP::RouterUtils::Associative does Associative;

has %!data;
has %.routes is required;

method new($routes, :@prefix) {
	self.bless: :routes(_endpoints $routes, :@prefix)
}

method AT-KEY($key) {
	return Nil unless %!routes{$key}:exists;
	%!data{$key} //= Cro::HTTP::RouterUtils::EndPoint.new: %!routes{$key}
}

method keys   { %!routes.keys }
method values { $.keys.map: { $.AT-KEY: $_ if $_ } }

method kv {
	gather for @.keys { .take; take self.AT-KEY: $_ }
}

sub _endpoints(Cro::HTTP::Router::RouteSet $route = $*ROOT-ROUTE, :@prefix --> Map()) {
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
		do for _endpoints($includee, :prefix[|@prefix, |@p]).kv -> Str $name, % ( :$handler, :@path ) {
			$name => %( :$handler, :path[|@prefix, |@path] )
		}
	},
}
