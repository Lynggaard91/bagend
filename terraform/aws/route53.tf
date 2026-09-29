data "aws_ssm_parameter" "domain_contact_first_name" {
  name            = "/bagend/domain-contact/first_name"
  with_decryption = true
}

data "aws_ssm_parameter" "domain_contact_last_name" {
  name            = "/bagend/domain-contact/last_name"
  with_decryption = true
}

data "aws_ssm_parameter" "domain_contact_email" {
  name            = "/bagend/domain-contact/email"
  with_decryption = true
}

data "aws_ssm_parameter" "domain_contact_phone_number" {
  name            = "/bagend/domain-contact/phone_number"
  with_decryption = true
}

data "aws_ssm_parameter" "domain_contact_address_line_1" {
  name            = "/bagend/domain-contact/address_line_1"
  with_decryption = true
}

data "aws_ssm_parameter" "domain_contact_city" {
  name            = "/bagend/domain-contact/city"
  with_decryption = true
}

data "aws_ssm_parameter" "domain_contact_zip_code" {
  name            = "/bagend/domain-contact/zip_code"
  with_decryption = true
}

resource "aws_route53domains_registered_domain" "lynggaardjensen_com" {
  domain_name        = "lynggaardjensen.com"
  admin_privacy      = true
  billing_privacy    = true
  registrant_privacy = true
  tech_privacy       = true

  name_server {
    name = "marissa.ns.cloudflare.com"
  }

  name_server {
    name = "mike.ns.cloudflare.com"
  }

  admin_contact {
    contact_type   = "PERSON"
    first_name     = data.aws_ssm_parameter.domain_contact_first_name.value
    last_name      = data.aws_ssm_parameter.domain_contact_last_name.value
    email          = data.aws_ssm_parameter.domain_contact_email.value
    phone_number   = data.aws_ssm_parameter.domain_contact_phone_number.value
    address_line_1 = data.aws_ssm_parameter.domain_contact_address_line_1.value
    city           = data.aws_ssm_parameter.domain_contact_city.value
    zip_code       = data.aws_ssm_parameter.domain_contact_zip_code.value
    country_code   = "DK"
  }

  registrant_contact {
    contact_type   = "PERSON"
    first_name     = data.aws_ssm_parameter.domain_contact_first_name.value
    last_name      = data.aws_ssm_parameter.domain_contact_last_name.value
    email          = data.aws_ssm_parameter.domain_contact_email.value
    phone_number   = data.aws_ssm_parameter.domain_contact_phone_number.value
    address_line_1 = data.aws_ssm_parameter.domain_contact_address_line_1.value
    city           = data.aws_ssm_parameter.domain_contact_city.value
    zip_code       = data.aws_ssm_parameter.domain_contact_zip_code.value
    country_code   = "DK"
  }

  tech_contact {
    contact_type   = "PERSON"
    first_name     = data.aws_ssm_parameter.domain_contact_first_name.value
    last_name      = data.aws_ssm_parameter.domain_contact_last_name.value
    email          = data.aws_ssm_parameter.domain_contact_email.value
    phone_number   = data.aws_ssm_parameter.domain_contact_phone_number.value
    address_line_1 = data.aws_ssm_parameter.domain_contact_address_line_1.value
    city           = data.aws_ssm_parameter.domain_contact_city.value
    zip_code       = data.aws_ssm_parameter.domain_contact_zip_code.value
    country_code   = "DK"
  }

  billing_contact {
    contact_type   = "PERSON"
    first_name     = data.aws_ssm_parameter.domain_contact_first_name.value
    last_name      = data.aws_ssm_parameter.domain_contact_last_name.value
    email          = data.aws_ssm_parameter.domain_contact_email.value
    phone_number   = data.aws_ssm_parameter.domain_contact_phone_number.value
    address_line_1 = data.aws_ssm_parameter.domain_contact_address_line_1.value
    city           = data.aws_ssm_parameter.domain_contact_city.value
    zip_code       = data.aws_ssm_parameter.domain_contact_zip_code.value
    country_code   = "DK"
  }
}

import {
  to = aws_route53domains_registered_domain.lynggaardjensen_com
  id = "lynggaardjensen.com"
}
