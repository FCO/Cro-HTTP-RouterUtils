use Cro::HTTP::RouterUtils;

sub other-routes is export {
  route {
    get my sub external-ep1("returns-ok") {
      content "text/plain", "OK"
    }
    post my sub external-ep2("using-post") {
      content "text/plain", "OK"
    }
  }
}
