locals {
  application_gateway_name = var.application_gateway != null ? lookup(
    var.application_gateway, "name", null
    ) != null ? var.application_gateway.name : join(module.const.delimiter, compact([
      module.const.az_prefix,
      var.env,
      var.name,
      module.const.application_gateway_suffix
  ])) : null
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway
resource "azurerm_application_gateway" "this" {
  #############################################
  count = local.enable_application_gateway

  name                = local.application_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "backend_address_pool" {
    # for_each = lookup(var.application_gateway, "backend_address_pool", null) == null ? [] : var.application_gateway.backend_address_pool
    for_each = var.application_gateway.backend_address_pool
    content {
      name = lookup(backend_address_pool.value, "name", null) != null ? backend_address_pool.value.name : join(module.const.delimiter, compact([
        local.application_gateway_name,
        backend_address_pool.key,
        "backend_address_pool"
      ]))
      fqdns        = lookup(backend_address_pool.value, "fqdns", null)
      ip_addresses = lookup(backend_address_pool.value, "ip_addresses", null)
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.application_gateway.backend_http_settings
    content {
      name = lookup(backend_http_settings.value, "name", null) != null ? backend_http_settings.value.name : join(module.const.delimiter, compact([
        local.application_gateway_name,
        backend_http_settings.key,
        "backend_http_settings"
      ]))
      cookie_based_affinity               = lookup(backend_http_settings.value, "cookie_based_affinity", "Disabled")
      affinity_cookie_name                = lookup(backend_http_settings.value, "affinity_cookie_name", null)
      path                                = lookup(backend_http_settings.value, "path", null)
      port                                = lookup(backend_http_settings.value, "port", null)
      probe_name                          = lookup(backend_http_settings.value, "probe_name", null)
      protocol                            = lookup(backend_http_settings.value, "protocol", null)
      request_timeout                     = lookup(backend_http_settings.value, "request_timeout", null)
      host_name                           = lookup(backend_http_settings.value, "host_name", null)
      pick_host_name_from_backend_address = lookup(backend_http_settings.value, "pick_host_name_from_backend_address", null)

      dynamic "authentication_certificate" {
        for_each = lookup(backend_http_settings.value, "authentication_certificate", null) == null ? [
        ] : backend_http_settings.value.authentication_certificate
        content {
          name = lookup(
            authentication_certificate.value, "name", null
            ) != null ? authentication_certificate.value.name : join(module.const.delimiter, compact([
              local.application_gateway_name,
              backend_http_settings.key,
              "backend_http_settings",
              authentication_certificate.key,
              "authentication_certificate"
          ]))

          # data = authentication_certificate.value.data
        }
      }

      trusted_root_certificate_names = lookup(backend_http_settings.value, "trusted_root_certificate_names", null)

      dynamic "connection_draining" {
        for_each = lookup(backend_http_settings.value, "connection_draining", null) == null ? [] : [backend_http_settings.value.connection_draining]
        content {
          enabled           = connection_draining.value.enabled
          drain_timeout_sec = connection_draining.value.drain_timeout_sec
        }
      }
    }
  }

  dynamic "frontend_ip_configuration" {
    for_each = var.application_gateway.frontend_ip_configuration
    content {
      name = lookup(
        frontend_ip_configuration.value, "name", null
        ) != null ? frontend_ip_configuration.value.name : join(module.const.delimiter, compact([
          local.application_gateway_name,
          frontend_ip_configuration.key,
          "frontend_ip_configuration"
      ]))

      subnet_id          = lookup(frontend_ip_configuration.value, "subnet_id", null)
      private_ip_address = lookup(frontend_ip_configuration.value, "private_ip_address", null)
      public_ip_address_id = lookup(frontend_ip_configuration.value, "public_ip_address_id", null) != null ? (
        frontend_ip_configuration.value.public_ip_address_id == "" && local.enable_public_ip > 0 ? azurerm_public_ip.this[0].id : frontend_ip_configuration.value.public_ip_address_id
      ) : null
      private_ip_address_allocation = lookup(frontend_ip_configuration.value, "private_ip_address_allocation", null)
    }
  }

  dynamic "frontend_port" {
    # for_each = lookup(var.application_gateway, "frontend_port", null) == null ? [] : [var.application_gateway.frontend_port]
    for_each = var.application_gateway.frontend_port
    content {
      #! Error: Missing required argument
      # The argument "frontend_port.5.name" is required, but no definition was found.
      # name = lookup(frontend_port.value, "name", join(module.const.delimiter, compact([
      #   "port",
      #   frontend_port.value.port
      # ])))
      name = lookup(frontend_port.value, "name", null) != null ? frontend_port.value.name : join(module.const.delimiter, compact([
        "port",
        frontend_port.value.port
      ]))
      port = frontend_port.value.port
    }
  }

  dynamic "gateway_ip_configuration" {
    for_each = var.application_gateway.gateway_ip_configuration
    content {
      #!name = lookup(gateway_ip_configuration.value, "name", join(module.const.delimiter, compact([
      #   local.application_gateway_name,
      #   gateway_ip_configuration.key,
      #   "gateway_ip_configuration"
      # ])))
      name = lookup(gateway_ip_configuration.value, "name", null) != null ? gateway_ip_configuration.value.name : join(module.const.delimiter, compact([
        local.application_gateway_name,
        gateway_ip_configuration.key,
        "gateway_ip_configuration"
      ]))

      subnet_id = gateway_ip_configuration.value.subnet_id
    }
  }

  dynamic "http_listener" {
    for_each = var.application_gateway.http_listener
    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = http_listener.value.frontend_ip_configuration_name
      frontend_port_name             = http_listener.value.frontend_port_name

      host_name            = lookup(http_listener.value, "host_name", null)
      host_names           = lookup(http_listener.value, "host_names", null)
      protocol             = http_listener.value.protocol
      require_sni          = lookup(http_listener.value, "require_sni", null)
      ssl_certificate_name = lookup(http_listener.value, "ssl_certificate_name", null)

      dynamic "custom_error_configuration" {
        for_each = lookup(http_listener.value, "custom_error_configuration", null) == null ? [] : [http_listener.value.custom_error_configuration]
        content {
          status_code           = custom_error_configuration.value.status_code
          custom_error_page_url = custom_error_configuration.value.custom_error_page_url
        }
      }
      firewall_policy_id = lookup(http_listener.value, "firewall_policy_id", null)
    }
  }

  dynamic "identity" {
    for_each = lookup(var.application_gateway, "identity", null) == null ? [] : [var.application_gateway.identity]
    content {
      type         = lookup(identity.value, "type", null) != null ? identity.value.type : "UserAssigned"
      identity_ids = lookup(identity.value, "identity_ids", null)
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.application_gateway.request_routing_rule
    content {
      name = lookup(request_routing_rule.value, "name", null) != null ? request_routing_rule.value.name : join(module.const.delimiter, compact([
        local.application_gateway_name,
        request_routing_rule.key,
        "request_routing_rule"
      ]))
      rule_type          = request_routing_rule.value.rule_type
      http_listener_name = request_routing_rule.value.http_listener_name

      backend_address_pool_name   = lookup(request_routing_rule.value, "backend_address_pool_name", null)
      backend_http_settings_name  = lookup(request_routing_rule.value, "backend_http_settings_name", null)
      redirect_configuration_name = lookup(request_routing_rule.value, "redirect_configuration_name", null)
      rewrite_rule_set_name       = lookup(request_routing_rule.value, "rewrite_rule_set_name", null)
      url_path_map_name           = lookup(request_routing_rule.value, "url_path_map_name", null)
    }
  }

  dynamic "sku" {
    for_each = [var.application_gateway.sku]
    content {
      name     = sku.value.name
      tier     = sku.value.tier
      capacity = lookup(sku.value, "capacity", null)
    }
  }

  zones = lookup(var.application_gateway, "zones", null)

  dynamic "authentication_certificate" {
    for_each = lookup(var.application_gateway, "authentication_certificate", null) == null ? [] : var.application_gateway.authentication_certificate
    content {
      name = authentication_certificate.value.name
      data = authentication_certificate.value.data
    }
  }

  dynamic "trusted_root_certificate" {
    for_each = lookup(var.application_gateway, "trusted_root_certificate", null) == null ? [] : var.application_gateway.trusted_root_certificate
    content {
      name = trusted_root_certificate.value.name
      data = trusted_root_certificate.value.data
    }
  }

  dynamic "ssl_policy" {
    for_each = lookup(var.application_gateway, "ssl_policy", null) == null ? [] : [var.application_gateway.ssl_policy]
    content {
      disabled_protocols   = lookup(ssl_policy.value, "disabled_protocols", null)
      policy_type          = lookup(ssl_policy.value, "policy_type", null)
      policy_name          = lookup(ssl_policy.value, "policy_name", null)
      cipher_suites        = lookup(ssl_policy.value, "cipher_suites", null)
      min_protocol_version = lookup(ssl_policy.value, "min_protocol_version", null)
    }
  }

  enable_http2 = lookup(var.application_gateway, "enable_http2", null)

  dynamic "probe" {
    for_each = lookup(var.application_gateway, "probe", null) == null ? [] : var.application_gateway.probe
    content {
      name                                      = probe.value.name
      host                                      = lookup(probe.value, "host", null)
      interval                                  = probe.value.interval
      protocol                                  = probe.value.protocol
      path                                      = lookup(probe.value, "path", null)
      timeout                                   = probe.value.timeout
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      port                                      = lookup(probe.value, "port", null)
      pick_host_name_from_backend_http_settings = lookup(probe.value, "pick_host_name_from_backend_http_settings", null)

      dynamic "match" {
        for_each = lookup(probe.value, "match", null) == null ? [] : [probe.value.match]
        content {
          body        = lookup(match.value, "body", null)
          status_code = lookup(match.value, "status_code", null)
        }
      }

      minimum_servers = lookup(probe.value, "minimum_servers", null)
    }
  }

  dynamic "ssl_certificate" {
    for_each = lookup(var.application_gateway, "ssl_certificate", null) == null ? [] : var.application_gateway.ssl_certificate
    content {
      name                = ssl_certificate.value.name
      data                = lookup(ssl_certificate.value, "data", null)
      password            = lookup(ssl_certificate.value, "password", null)
      key_vault_secret_id = lookup(ssl_certificate.value, "key_vault_secret_id", null)
    }
  }

  dynamic "url_path_map" {
    for_each = lookup(var.application_gateway, "url_path_map", null) == null ? [] : var.application_gateway.url_path_map
    content {
      name                                = url_path_map.value.name
      default_backend_address_pool_name   = lookup(url_path_map.value, "default_backend_address_pool_name", null)
      default_backend_http_settings_name  = lookup(url_path_map.value, "default_backend_http_settings_name", null)
      default_redirect_configuration_name = lookup(url_path_map.value, "default_redirect_configuration_name", null)
      default_rewrite_rule_set_name       = lookup(url_path_map.value, "default_rewrite_rule_set_name", null)

      dynamic "path_rule" {
        for_each = lookup(url_path_map.value, "path_rule", null) == null ? [] : url_path_map.value.path_rule
        content {
          name                        = path_rule.value.name
          paths                       = path_rule.value.paths
          backend_address_pool_name   = lookup(path_rule.value, "backend_address_pool_name", null)
          backend_http_settings_name  = lookup(path_rule.value, "backend_http_settings_name", null)
          redirect_configuration_name = lookup(path_rule.value, "redirect_configuration_name", null)
          rewrite_rule_set_name       = lookup(path_rule.value, "rewrite_rule_set_name", null)
          firewall_policy_id          = lookup(path_rule.value, "firewall_policy_id", null)
        }
      }
    }
  }

  dynamic "waf_configuration" {
    for_each = lookup(var.application_gateway, "waf_configuration", null) == null ? [] : var.application_gateway.waf_configuration

    content {
      enabled          = waf_configuration.value.enabled
      firewall_mode    = waf_configuration.value.firewall_mode
      rule_set_type    = lookup(waf_configuration.value, "rule_set_type", null)
      rule_set_version = lookup(waf_configuration.value, "rule_set_version", null) != null ? waf_configuration.value.rule_set_version : "3.1"

      dynamic "disabled_rule_group" {
        for_each = lookup(waf_configuration.value, "disabled_rule_group", null) == null ? [] : waf_configuration.value.disabled_rule_group
        content {
          rule_group_name = disabled_rule_group.value.rule_group_name
          rules           = lookup(disabled_rule_group.value, "rules", null)
        }
      }

      file_upload_limit_mb     = lookup(waf_configuration.value, "file_upload_limit_mb", null)
      request_body_check       = lookup(waf_configuration.value, "request_body_check", null)
      max_request_body_size_kb = lookup(waf_configuration.value, "max_request_body_size_kb", null)

      dynamic "exclusion" {
        for_each = lookup(waf_configuration.value, "exclusion", null) == null ? [] : waf_configuration.value.exclusion
        content {
          match_variable          = exclusion.value.match_variable
          selector_match_operator = exclusion.value.selector_match_operator
          selector                = lookup(exclusion.value, "selector", null)
        }
      }
    }
  }

  dynamic "custom_error_configuration" {
    for_each = lookup(var.application_gateway, "custom_error_configuration", null) == null ? [] : var.application_gateway.custom_error_configuration
    content {
      status_code           = custom_error_configuration.value.status_code
      custom_error_page_url = custom_error_configuration.value.custom_error_page_url
    }
  }

  firewall_policy_id = lookup(var.application_gateway, "firewall_policy_id", null)

  dynamic "redirect_configuration" {
    for_each = lookup(var.application_gateway, "redirect_configuration", null) == null ? [] : var.application_gateway.redirect_configuration
    content {
      name                 = redirect_configuration.value.name
      redirect_type        = redirect_configuration.value.redirect_type
      target_listener_name = lookup(redirect_configuration.value, "target_listener_name", null)
      target_url           = lookup(redirect_configuration.value, "target_url", null)
      include_path         = lookup(redirect_configuration.value, "include_path", null)
      include_query_string = lookup(redirect_configuration.value, "include_query_string", null)
    }
  }

  dynamic "autoscale_configuration" {
    for_each = lookup(var.application_gateway, "autoscale_configuration", null) == null ? [] : var.application_gateway.autoscale_configuration
    content {
      min_capacity = autoscale_configuration.value.min_capacity
      max_capacity = lookup(autoscale_configuration.value, "max_capacity", null)
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = lookup(var.application_gateway, "rewrite_rule_set", null) == null ? [] : var.application_gateway.rewrite_rule_set
    content {
      name = rewrite_rule_set.value.name

      dynamic "rewrite_rule" {
        for_each = lookup(rewrite_rule_set.value, "rewrite_rule", null) == null ? [] : rewrite_rule_set.value.rewrite_rule
        content {
          name          = rewrite_rule.value.name
          rule_sequence = rewrite_rule.value.rule_sequence

          dynamic "condition" {
            for_each = lookup(rewrite_rule.value, "condition", null) == null ? [] : rewrite_rule.value.condition
            content {
              variable    = condition.value.variable
              pattern     = condition.value.pattern
              ignore_case = lookup(condition.value, "ignore_case", null)
              negate      = lookup(condition.value, "negate", null)
            }
          }

          dynamic "request_header_configuration" {
            for_each = lookup(rewrite_rule.value, "request_header_configuration", null) == null ? [] : rewrite_rule.value.request_header_configuration
            content {
              header_name  = request_header_configuration.value.header_name
              header_value = request_header_configuration.value.header_value
            }
          }

          dynamic "response_header_configuration" {
            for_each = lookup(rewrite_rule.value, "response_header_configuration", null) == null ? [] : rewrite_rule.value.response_header_configuration
            content {
              header_name  = response_header_configuration.value.header_name
              header_value = response_header_configuration.value.header_value
            }
          }

          dynamic "response_header_configuration" {
            for_each = lookup(rewrite_rule.value, "response_header_configuration", null) == null ? [] : rewrite_rule.value.response_header_configuration
            content {
              header_name  = response_header_configuration.value.header_name
              header_value = response_header_configuration.value.header_value
            }
          }

          dynamic "url" {
            for_each = lookup(rewrite_rule.value, "url", null) == null ? [] : rewrite_rule.value.url
            content {
              path         = lookup(url.value, "path", null)
              query_string = lookup(url.value, "query_string", null)
              reroute      = lookup(url.value, "reroute", null)
            }
          }
        }
      }
    }
  }

  tags = merge(local.tags, {
    Name = local.application_gateway_name
  })

  dynamic "timeouts" {
    for_each = lookup(var.application_gateway, "timeouts", null) == null ? [] : [var.application_gateway.timeouts]
    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      read   = lookup(timeouts.value, "read", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }
}
