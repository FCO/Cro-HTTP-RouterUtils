use Cro::HTTP::RouterUtils;
use Cro::HTTP::Server;
use lib ".";
use ExampleRoute;
my $application = route {
    include external => other-routes;
    get -> 'greet', Str :$name {
        content 'text/plain', "Hello, $name!";
    }
    get -> "form" {
        my $ep = endpoints("get_greet"); # Endpoint has no explicit name, use method ans parameters
        content 'text/html', qq:to/END/
            <form action='{ $ep.path }' method='{ $ep.method }'>
                <input type='text' name='name'>
                <input type='submit' value='ok'>
            </form>
        END
    }
    get my sub greet-path('greet', $name) {
        content 'text/plain', "Hello, $name!";
    }
    get -> 'redirect' {
        endpoints("greet-path").redirect-to: :name<fernando> # Use Endpoint by name
    }
    get -> "links" {
        my $ep = endpoints("greet-path"); # Use Endpoint by name
        content 'text/html', qq:to/END/
            <a href='{ $ep.path: :name<test1> }'>test1</a><br>
            <a href='{ $ep.path: :name<test2> }'>test2</a><br>
            <a href='{ $ep.path: :name<test3> }'>test3</a><br>
            <a href='{ $ep.path: :name<test4> }'>test4</a><br>
        END
    }
    get -> "links-htmx" {
        my $ep = endpoints("greet-path"); # Use Endpoint by name
        content 'text/html', qq:to/END/
            <script src="https://cdn.jsdelivr.net/npm/htmx.org@2.0.7/dist/htmx.min.js"></script>
            <a href='#' { $ep.hx-attrs: :name<test1> }>test1</a><br>
            <a href='#' { $ep.hx-attrs: :name<test2> }>test2</a><br>
            <a href='#' { $ep.hx-attrs: :name<test3> }>test3</a><br>
            <a href='#' { $ep.hx-attrs: :name<test4> }>test4</a><br>
            <a href='#' { endpoints("external-ep1").hx-attrs }>external-ep1</a><br>
            <a href='#' { endpoints("external-ep2").hx-attrs }>external-ep2</a><br>
        END
    }
}
my Cro::Service $hello = Cro::HTTP::Server.new:
    :host<localhost>, :port<10000>, :$application;
$hello.start;
react whenever signal(SIGINT) { $hello.stop; exit; }



