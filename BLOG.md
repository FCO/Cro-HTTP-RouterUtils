# Typed, Named Endpoints for Cro (with HTMX Helpers)

Cro’s HTTP router is great at declaring routes, but it doesn’t provide a first‑class way to reference those routes elsewhere in your app. Cro::HTTP::RouterUtils fills that gap: it lets you reference endpoints by name, build typed-safe paths, generate HTMX attributes, redirect to routes, and even call the underlying implementation.

- Stable references to routes by name (or auto‑named fallback)
- Typed `path()` builder validates parameter types
- `hx-attrs()` renders HTMX attributes with the correct method and URL
- `redirect-to()` returns a Cro redirect to the endpoint
- `call()` invokes the route implementation directly (handy for tests)
- Supports `include` with prefixes seamlessly

Repo: https://github.com/FCO/Cro-HTTP-RouterUtils

## Install

```bash
zef install --depsonly .
```

## Quick Start

```raku
use Cro::HTTP::RouterUtils;

my $app = route {
    # Name a route via a named sub
    get my sub greet-path('greet', $name) {
        content 'text/plain', "Hello, $name!"
    }

    # Use the endpoint by name
    get -> 'links' {
        my $ep = endpoints('greet-path');
        content 'text/html', qq:to/END/
            <a href="{ $ep.path(:name<alice>) }">alice</a>
            <a href="#" { $ep.hx-attrs(:name<bob>, :trigger<click>) }>bob</a>
        END
    }
}
```

## Naming and Discovering Endpoints

- Named endpoints: give your route a function name and reference it with `endpoints('your-name')`.
- Auto‑named endpoints: when no name is provided, keys are generated from method and path signature, e.g. `get_greet`.

```raku
# Auto-named
get -> 'greet', Str :$name { 200 }
endpoints('get_greet').path;  # => "/greet"

# Named
get my sub greet-path('greet', $name) { "Hello, $name!" }
endpoints('greet-path').path(:name<alice>);  # => "/greet/alice"
```

Includes with prefixes are supported transparently:

```raku
include external => other-routes;   # /external prefix applied

endpoints('external-ep1').method;   # "GET"
endpoints('external-ep1').path;     # "/external/returns-ok"
```

## Typed Path Building

`path(*%values)` enforces your route’s typed parameters; missing or invalid values throw.

```raku
get my sub sum('sum', Int $a, Int $b) { $a + $b }

my $ep = endpoints('sum');
$ep.path(:a(1), :b(2));          # "/sum/1/2"
$ep.path(:a("x"), :b(2));        # throws (type mismatch)
$ep.path(:a(1));                 # throws (missing parameter)
```

## HTMX Helpers

`hx-attrs(:args…)` returns a space-separated string of HTMX attributes. It uses the endpoint’s HTTP method by default (e.g., `hx-get`) and the built URL.

```raku
<a href="#"
   { endpoints('greet-path').hx-attrs(
       :name<alice>,
       :trigger<click>,
       :target<#out>,
       :swap<'outerHTML settle:200ms'>,
       :push-url<true>,
       :on{ click => "console.log(\"clicked\")" }
     )
   }>
  Load Alice
</a>
```

Highlights supported:
- Request URL/method: `method` override; parameters via `:name<...>` etc.
- Core: `trigger`, `target`, `confirm`, `indicator`, `swap`, `oob` (as `hx-swap-oob`), `boost`
- Navigation: `push-url` (Bool|Str), `replace-url` (Bool|Str)
- Selection: `select`, `select-oob`
- JSON: `vals`, `headers`, `request`
- Flags: `disable`, `validate`
- Misc: `disabled-elt`, `disinherit`, `encoding`, `ext`, `history`, `history-elt`, `include`, `inherit`, `params`, `prompt`, `sync`, `vars` (deprecated)
- Events: `:on{ event => "code" }` emits `hx-on:event='code'`

Example minimal output:
```
hx-get='/greet/alice' hx-trigger='click' hx-target='#out'
```

## Redirects

```raku
get -> 'redir' {
    endpoints('greet-path').redirect-to: :name<ok>
}
```

## Calling the Implementation

`call(|args)` invokes the underlying route implementation. Literal path segments are auto-injected; you pass only the non-literal parameters.

```raku
get my sub ret('ret') { 42 }
get my sub sum('sum', Int $a, Int $b) { $a + $b }

endpoints('ret').call;        # 42
endpoints('sum').call(2, 3);  # 5
```

Great for unit tests of pure route logic. If you depend on Cro’s pipeline, prefer `Cro::HTTP::Test`.

## Full Example

See `examples/example.raku` and `examples/ExampleRoute.rakumod` in the repo. Run:

```bash
raku examples/example.raku
```

Then visit:
- `/form` for a classic form
- `/links` for `<a href>` links built from endpoints
- `/links-htmx` for HTMX-driven links

## Errors and Guarantees

- Unknown endpoint name: throws.
- Missing/invalid path params: throws with a clear message.
- `call()` auto-injects literal path segments; you provide the rest.

## Why This Isn’t in Cro

Cro focuses on routing and request handling. This utility adds “endpoint as a value” ergonomics—stable references, typed path building, HTMX helpers, and redirect/call helpers—while staying a thin layer on top of `Cro::HTTP::Router`.

## Appendix: Include With Prefix Example

```raku
# examples/ExampleRoute.rakumod
use Cro::HTTP::RouterUtils;

sub other-routes is export {
  route {
    get  my sub external-ep1("returns-ok")  { content "text/plain", "OK" }
    post my sub external-ep2("using-post")  { content "text/plain", "OK" }
  }
}

# elsewhere
include external => other-routes;
endpoints('external-ep1').path;  # "/external/returns-ok"
endpoints('external-ep2').path;  # "/external/using-post"
```

—
Made with Cro::HTTP::RouterUtils (Raku).
