variable "application_gateway" {
  type = object({
    name = optional(string)

    backend_address_pool = list(object({
      name         = string
      fqdns        = optional(list(string))
      ip_addresses = optional(list(string))
    }))

    backend_http_settings = list(object({
      name                                = string
      cookie_based_affinity               = optional(string) # Enabled or Disabled
      affinity_cookie_name                = optional(string)
      path                                = optional(string)
      port                                = number
      probe_name                          = optional(string)
      protocol                            = string # Http or Https
      request_timeout                     = number
      host_name                           = optional(string) # Cannot be set if pick_host_name_from_backend_address is set to true
      pick_host_name_from_backend_address = optional(bool)   # Defaults to false

      authentication_certificate = optional(list(object({
        name = string
        data = string
      })))

      trusted_root_certificate_names = optional(list(string))

      connection_draining = optional(object({
        enabled           = bool
        drain_timeout_sec = number
      }))
    }))

    frontend_ip_configuration = list(object({
      name                          = string
      subnet_id                     = optional(string)
      private_ip_address            = optional(string)
      public_ip_address_id          = optional(string)
      private_ip_address_allocation = optional(string) # Dynamic or Static
    }))

    frontend_port = list(object({
      name = optional(string)
      port = number
    }))

    gateway_ip_configuration = list(object({
      name      = optional(string)
      subnet_id = string
    }))

    http_listener = list(object({
      name                           = string
      frontend_ip_configuration_name = string
      frontend_port_name             = string

      host_name  = optional(string)       # changes Listener Type to 'Multi site'
      host_names = optional(list(string)) # The host_names and host_name are mutually exclusive and cannot both be set.
      protocol   = string                 # Http or Https

      require_sni          = optional(bool) # Defaults to false.
      ssl_certificate_name = optional(string)

      custom_error_configuration = optional(list(object({
        status_code           = string # HttpStatus403 or HttpStatus502
        custom_error_page_url = string
      })))

      firewall_policy_id = optional(string)
    }))

    identity = optional(object({
      type         = optional(string) # UserAssigned
      identity_ids = list(string)
    }))

    request_routing_rule = list(object({
      name                        = optional(string)
      rule_type                   = string # Basic or PathBasedRouting
      http_listener_name          = string
      backend_address_pool_name   = optional(string) # Cannot be set if redirect_configuration_name is set.
      backend_http_settings_name  = optional(string) # Cannot be set if redirect_configuration_name is set.
      redirect_configuration_name = optional(string) # Cannot be set if either backend_address_pool_name or backend_http_settings_name is set.
      rewrite_rule_set_name       = optional(string) # Only valid for v2 SKUs.
      url_path_map_name           = optional(string)
    }))

    sku = object({
      name     = string # Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2
      tier     = string # Standard, Standard_v2, WAF and WAF_v2.
      capacity = optional(number)
    })

    zones = optional(list(string))

    authentication_certificate = optional(list(object({
      name = string
      data = string
    })))

    trusted_root_certificate = optional(list(object({
      name = string
      data = string
    })))

    ssl_policy = optional(object({
      disabled_protocols   = optional(list(string)) # TLSv1_0, TLSv1_1, TLSv1_2
      policy_type          = optional(string)       # Predefined or Custom
      policy_name          = optional(string)       #
      cipher_suites        = optional(list(string)) #
      min_protocol_version = optional(string)       # TLSv1_0, TLSv1_1, TLSv1_2
    }))

    enable_http2 = optional(bool) # Defaults to false.

    probe = optional(list(object({
      name                                      = string
      host                                      = optional(string) # Cannot be set if pick_host_name_from_backend_http_settings is set to true
      interval                                  = number           # 1-86400
      protocol                                  = string           # Http or Https
      path                                      = optional(string)
      timeout                                   = number           # 1-86400
      unhealthy_threshold                       = number           # 1-86400
      port                                      = optional(number) # 1-65535
      pick_host_name_from_backend_http_settings = optional(bool)   # Defaults to false
      match = optional(object({
        body        = optional(string)
        status_code = optional(list(string))
      }))
      minimum_servers = optional(number) # Defaults to 0
    })))

    ssl_certificate = optional(list(object({
      name                = string
      data                = optional(string)
      password            = optional(string) # Required if data is set
      key_vault_secret_id = optional(string) # Secret or Certificate object stored in Azure KeyVault
    })))

    url_path_map = optional(list(object({
      name                                = string
      default_backend_address_pool_name   = optional(string) # Cannot be set if default_redirect_configuration_name is set.
      default_backend_http_settings_name  = optional(string) # Cannot be set if default_redirect_configuration_name is set.
      default_redirect_configuration_name = optional(string) #
      default_rewrite_rule_set_name       = optional(string) #
      path_rule = list(object({
        name                        = string
        paths                       = list(string)
        backend_address_pool_name   = optional(string) # Cannot be set if redirect_configuration_name is set.
        backend_http_settings_name  = optional(string) # Cannot be set if redirect_configuration_name is set.
        redirect_configuration_name = optional(string) #
        rewrite_rule_set_name       = optional(string)
        firewall_policy_id          = optional(string)
      }))
    })))

    waf_configuration = optional(list(object({
      enabled          = bool
      firewall_mode    = string           # Detection or Prevention.
      rule_set_type    = optional(string) # only OWASP is supported.
      rule_set_version = string           # Possible values are 2.2.9, 3.0, and 3.1.

      disabled_rule_group = optional(list(object({
        rule_group_name = string                 #
        rules           = optional(list(number)) # Disables all rules in the specified group if rules is not specified.
      })))

      file_upload_limit_mb     = optional(number) # 1-750 MB. Defaults to 100MB.
      request_body_check       = optional(bool)
      max_request_body_size_kb = optional(number) # 1-128 KB. Defaults to 128KB.

      exclusion = optional(list(object({
        match_variable          = string           # RequestHeaderNames, RequestArgNames, RequestCookieNames
        selector_match_operator = optional(string) # Equals, StartsWith, EndsWith, Contains
        selector                = optional(string)
      })))
    })))

    custom_error_configuration = optional(list(object({
      status_code           = string # HttpStatus403 or HttpStatus502
      custom_error_page_url = string
    })))

    firewall_policy_id = optional(string)

    redirect_configuration = optional(list(object({
      name                 = string
      redirect_type        = string           # Permanent, Temporary, Found and SeeOther
      target_listener_name = optional(string) # Cannot be set if target_url is set.
      target_url           = optional(string) # Cannot be set if target_listener_name is set.
      include_path         = optional(bool)   # Defaults to false
      include_query_string = optional(bool)   # Default to false
    })))

    autoscale_configuration = optional(list(object({
      min_capacity = number           # 0-100
      max_capacity = optional(number) # 2-125
    })))

    rewrite_rule_set = optional(list(object({
      name = string
      rewrite_rule = list(object({
        name          = string
        rule_sequence = number # 1-1000
        condition = optional(list(object({
          variable    = string
          pattern     = string
          ignore_case = optional(bool) # Defaults to false
          negate      = optional(bool) # Defaults to false
        })))
        request_header_configuration = optional(list(object({
          header_name  = string
          header_value = string
        })))
        response_header_configuration = optional(list(object({
          header_name  = string
          header_value = string
        })))
        url = optional(list(object({
          path         = optional(string) # One or both of path and query_string
          query_string = optional(string)
          reroute      = optional(string) # https://docs.microsoft.com/en-us/azure/application-gateway/rewrite-http-headers-url#rewrite-configuration
        })))
      }))
    })))

    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      read   = optional(string)
      delete = optional(string)
    }))
  })

  #   validation {
  #     condition = var.linux_vm != null ? lookup(
  #       var.linux_vm, "diff_disk_settings", null
  #       ) != null ? lookup(
  #       var.linux_vm.diff_disk_settings, "option", null
  #     ) != null ? lower(var.linux_vm.diff_disk_settings.option) == "local" : true : true : true
  #     error_message = "As of 20210621 the only supported value is \"Local\"."
  #   }

  default = null
}
