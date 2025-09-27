use Cro::HTTP::Router;
unit class Cro::HTTP::RouterUtils::EndPoint;

has $.data is required;

method new($data) {
	self.bless: :$data
}

method method {
	$!data.<handler>.method
}

method call(|c) {
	my &impl = $.data.<handler>.implementation;
	my @sup   = c.list;
	my $idx   = 0;
	my @args;
	for &impl.signature.params.grep({ !.named }) -> $p {
		my $lit = $p.constraint_list.head;
		if $lit.defined {
			@args.push: $lit;
		} else {
			@args.push: @sup[$idx++];
		}
	}
	&impl.(|@args, |c.hash)
}

method gist { "{ $.method.uc }\t{ $.path-template }" }

method path-template {
	my @path = $.data.<path>[];
	"/" ~ (
		@path.map({
			do if $_ ~~ Str {
				.Str
			} else {
				my (:$key, :$value) := .<>;
				"\{ { $value.^name } { $key.Str } }"
			}
		}).join: "/"
	)
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
	Bool :$oob         = False,   # hx-swap-oob
	Bool :$boost       = False,   # hx-boost
	Any  :$push-url,              # hx-push-url (Bool|Str)
	Any  :$replace-url,           # hx-replace-url (Bool|Str)
	Str  :$select,                # hx-select
	Str  :$select-oob,            # hx-select-oob
	Str  :$swap,                  # hx-swap
	Str  :$vals,                  # hx-vals (JSON string)
	Str  :$headers,               # hx-headers (JSON string)
	Bool :$disable     = False,   # hx-disable (presence)
	Str  :$disabled-elt,          # hx-disabled-elt
	Str  :$disinherit,            # hx-disinherit
	Str  :$encoding,              # hx-encoding
	Str  :$ext,                   # hx-ext
	Str  :$history,               # hx-history
	Str  :$history-elt,           # hx-history-elt
	Str  :$include,               # hx-include
	Str  :$inherit,               # hx-inherit
	Str  :$params,                # hx-params
	Str  :$prompt,                # hx-prompt
	Str  :$request,               # hx-request (JSON string)
	Str  :$sync,                  # hx-sync
	Bool :$validate    = False,   # hx-validate (presence)
	Str  :$vars,                  # hx-vars (deprecated)
	Str  :$method,                # override method: get|post|put|delete|patch
	:%on,                         # hx-on:EVENT='...'
	*%pars,
) {
	my $m = ($method // $.method).lc;
	my sub fmt($v) { $v ~~ Bool ?? ($v ?? 'true' !! 'false') !! $v }
	[
		"hx-{$m}='{$.path: |%pars}'",
		|("hx-trigger='$_'"            with $trigger      ),
		|("hx-target='$_'"             with $target       ),
		|("hx-confirm='$_'"            with $confirm      ),
		|("hx-indicator='$_'"          with $indicator    ),
		|("hx-swap-oob='true'"         if   $oob          ),
		|("hx-boost='true'"            if   $boost        ),
		|("hx-push-url='{ .&fmt }'"    with $push-url     ),
		|("hx-replace-url='{ .&fmt }'" with $replace-url  ),
		|("hx-select='$_'"             with $select       ),
		|("hx-select-oob='$_'"         with $select-oob   ),
		|("hx-swap='$_'"               with $swap         ),
		|("hx-vals='$_'"               with $vals         ),
		|("hx-headers='$_'"            with $headers      ),
		|("hx-disable='true'"          if   $disable      ),
		|("hx-disabled-elt='$_'"       with $disabled-elt ),
		|("hx-disinherit='$_'"         with $disinherit   ),
		|("hx-encoding='$_'"           with $encoding     ),
		|("hx-ext='$_'"                with $ext          ),
		|("hx-history='$_'"            with $history      ),
		|("hx-history-elt='$_'"        with $history-elt  ),
		|("hx-include='$_'"            with $include      ),
		|("hx-inherit='$_'"            with $inherit      ),
		|("hx-params='$_'"             with $params       ),
		|("hx-prompt='$_'"             with $prompt       ),
		|("hx-request='$_'"            with $request      ),
		|("hx-sync='$_'"               with $sync         ),
		|("hx-validate='true'"         if   $validate     ),
		|("hx-vars='$_'"               with $vars         ),
		|do for %on.kv -> $evt, $code { "hx-on:{$evt}='$code'" },
	].join: " "
}
