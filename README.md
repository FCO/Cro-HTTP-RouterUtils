[![Actions Status](https://github.com/FCO/Cro-HTTP-RouterUtils/actions/workflows/test.yml/badge.svg)](https://github.com/FCO/Cro-HTTP-RouterUtils/actions)

NAME
====

Cro::HTTP::RouterUtils - Utilities for Cro::HTTP::Router to reference endpoints, build URLs and HTMX attributes

SYNOPSIS
========

```raku
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
```

INSTALLATION
============

```sh
zef install Cro::HTTP::RouterUtils
```

Requires Rakudo 6.d+. Dependencies (Cro::HTTP, Hash::Agnostic) are installed automatically.

DESCRIPTION
===========

Cro::HTTP::RouterUtils lets you discover and *use* your Cro routes from code and templates. It exports a small helper to capture the root route and a function that resolves endpoints into objects that know how to build URLs, redirect, generate HTMX attributes, and even call the underlying implementation.

USAGE
=====

Exported symbols
----------------

over
====

4

  * * `route`

Same as `Cro::HTTP::Router::route`, but also stores the created route set in `$*ROOT-ROUTE`, so `endpoints` can find your handlers without extra plumbing.

  * * `endpoints`

- `endpoints($name, $route?)` → `Cro::HTTP::RouterUtils::EndPoint` (throws if not found) - `endpoints($route = $*ROOT-ROUTE, :@prefix)` → associative map of endpoints (lazy)

back
====



Referencing endpoints
---------------------

- *By explicit name* (recommended): name the implementation and use that name.

```raku
get my sub greet-path('greet', $name) { ... }
my $ep = endpoints('greet-path');
```

- *Auto-named* (when you don't name it): use `"<method>_<segments>"`, where segments are literal parts and positional params. For example:

```raku
get -> 'greet', Str :$name { ... }
my $ep = endpoints('get_greet');
```

- *Included routes*: when using `include prefix =` route>, the prefix affects the built path only; the endpoint name remains the one defined by the included route.

Building URLs (with type safety)
--------------------------------

```raku
my $ep = endpoints('greet-path');
$ep.path(:name<alice>);  # "/greet/alice"
$ep.method;              # "GET"
```

Required/typed parameters are validated; a helpful exception is thrown for missing/wrong types.

Redirecting
-----------

```raku
get -> 'redir' {
    endpoints('greet-path').redirect-to: :name<ok>;
}
```

HTMX helpers
------------

```raku
endpoints('greet-path').hx-attrs(:name<bob>, :trigger<click>, :target<#out>);
# -> "hx-get='/greet/bob' hx-trigger='click' hx-target='#out'"

# Override the HTTP method if needed
endpoints('greet-path').hx-attrs(:name<bob>, :method<post>);
# -> "hx-post='/greet/bob'"
```

You may pass most HTMX options (e.g. `:confirm`, `:swap`, `:vals`, `:headers`, `:push-url`, `:replace-url`, etc.). Boolean options are rendered as `'true'` per HTMX conventions.

Programmatic call
-----------------

```raku
endpoints('sum').call(2, 3);  # -> 5
```

API
===

Class `Cro::HTTP::RouterUtils::EndPoint`
----------------------------------------

- `method method` → Str: the HTTP method (GET/POST/...) - `method path(*%values)` → Str: builds the URL, validating typed params - `method redirect-to(*%values)`: emits a Cro redirect to the built path - `method hx-attrs(..., *%pars)` → Str: returns an attribute string suitable for HTMX - `method call(|c)`: calls the underlying implementation (useful for tests/PL)

SEE ALSO
========

[Cro::HTTP::Router](Cro::HTTP::Router), [Cro::HTTP](Cro::HTTP)

AUTHOR
======

Fernando Corrêa de Oliveira <fco@cpan.org>

COPYRIGHT AND LICENSE
=====================

Copyright 2025 Fernando Corrêa de Oliveira

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

