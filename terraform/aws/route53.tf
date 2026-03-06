resource "aws_route53domains_registered_domain" "lynggaardjensen_com" {
  domain_name = "lynggaardjensen.com"

  name_server {
    name = "marissa.ns.cloudflare.com"
  }

  name_server {
    name = "mike.ns.cloudflare.com"
  }
}

import {
  to = aws_route53domains_registered_domain.lynggaardjensen_com
  id = "lynggaardjensen.com"
}
