locals {
  application_gateway_name = var.application_gateway != null ? (
    var.application_gateway.name
    ) != null ? var.application_gateway.name : join(
    module.const.delimiter, compact([
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
    for_each = var.application_gateway.backend_address_pool
    content {
      name = backend_address_pool.value.name != null ? backend_address_pool.value.name : join(module.const.delimiter, compact([
        local.application_gateway_name,
        backend_address_pool.key,
        "backend_address_pool"
      ]))
      fqdns        = backend_address_pool.value.fqdns
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.application_gateway.backend_http_settings
    content {
      name = backend_http_settings.value.name != null ? backend_http_settings.value.name : join(module.const.delimiter, compact([
        local.application_gateway_name,
        backend_http_settings.key,
        "backend_http_settings"
      ]))
      cookie_based_affinity               = backend_http_settings.value.cookie_based_affinity != null ? backend_http_settings.value.cookie_based_affinity : "Disabled"
      affinity_cookie_name                = backend_http_settings.value.affinity_cookie_name
      path                                = backend_http_settings.value.path
      port                                = backend_http_settings.value.port
      probe_name                          = backend_http_settings.value.probe_name
      protocol                            = backend_http_settings.value.protocol
      request_timeout                     = backend_http_settings.value.request_timeout
      host_name                           = backend_http_settings.value.host_name
      pick_host_name_from_backend_address = backend_http_settings.value.pick_host_name_from_backend_address

      dynamic "authentication_certificate" {
        for_each = backend_http_settings.value.authentication_certificate != null ? backend_http_settings.value.authentication_certificate : []
        content {
          name = authentication_certificate.value.name.null != null ? authentication_certificate.value.name : join(
            module.const.delimiter, compact([
              local.application_gateway_name,
              backend_http_settings.key,
              "backend_http_settings",
              authentication_certificate.key,
              "authentication_certificate"
          ]))

          # according to terraform-provider-azurerm/internal/services/network/application_gateway_resource.go
          # data = authentication_certificate.value.data
        }
      }

      trusted_root_certificate_names = backend_http_settings.value.trusted_root_certificate_names

      dynamic "connection_draining" {
        for_each = backend_http_settings.value.connection_draining != null ? [backend_http_settings.value.connection_draining] : []
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
      name = frontend_ip_configuration.value.name != null ? frontend_ip_configuration.value.name : join(
        module.const.delimiter, compact([
          local.application_gateway_name,
          frontend_ip_configuration.key,
          "frontend_ip_configuration"
      ]))

      subnet_id          = frontend_ip_configuration.value.subnet_id
      private_ip_address = frontend_ip_configuration.value.private_ip_address

      public_ip_address_id = frontend_ip_configuration.value.public_ip_address_id != null ? (
        frontend_ip_configuration.value.public_ip_address_id == "" && local.enable_public_ip > 0
        ? azurerm_public_ip.this[0].id
        : frontend_ip_configuration.value.public_ip_address_id
      ) : null

      private_ip_address_allocation = frontend_ip_configuration.value.private_ip_address_allocation
    }
  }

  dynamic "frontend_port" {
    for_each = var.application_gateway.frontend_port
    content {
      #! Error: Missing required argument
      # The argument "frontend_port.5.name" is required, but no definition was found.
      # name = lookup(frontend_port.value, "name", join(module.const.delimiter, compact([
      #   "port",
      #   frontend_port.value.port
      # ])))
      name = frontend_port.value.name != null ? frontend_port.value.name : join(
        module.const.delimiter, compact([
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
      name = gateway_ip_configuration.value.name != null ? gateway_ip_configuration.value.name : join(
        module.const.delimiter, compact([
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

      host_name            = http_listener.value.host_name
      host_names           = http_listener.value.host_names
      protocol             = http_listener.value.protocol
      require_sni          = http_listener.value.require_sni
      ssl_certificate_name = http_listener.value.ssl_certificate_name

      dynamic "custom_error_configuration" {
        for_each = http_listener.value.custom_error_configuration != null ? [http_listener.value.custom_error_configuration] : []
        content {
          status_code           = custom_error_configuration.value.status_code
          custom_error_page_url = custom_error_configuration.value.custom_error_page_url
        }
      }

      firewall_policy_id = http_listener.value.firewall_policy_id
    }
  }

  dynamic "identity" {
    for_each = var.application_gateway.identity != null ? [var.application_gateway.identity] : []
    content {
      type         = identity.value.type != null ? identity.value.type : "UserAssigned"
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.application_gateway.request_routing_rule
    content {
      name = request_routing_rule.value.name != null ? request_routing_rule.value.name : join(
        module.const.delimiter, compact([
          local.application_gateway_name,
          request_routing_rule.key,
          "request_routing_rule"
      ]))
      rule_type          = request_routing_rule.value.rule_type
      http_listener_name = request_routing_rule.value.http_listener_name

      backend_address_pool_name   = request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name  = request_routing_rule.value.backend_http_settings_name
      redirect_configuration_name = request_routing_rule.value.redirect_configuration_name
      rewrite_rule_set_name       = request_routing_rule.value.rewrite_rule_set_name
      url_path_map_name           = request_routing_rule.value.url_path_map_name
    }
  }

  dynamic "sku" {
    for_each = [var.application_gateway.sku]
    content {
      name     = sku.value.name
      tier     = sku.value.tier
      capacity = sku.value.capacity
    }
  }

  zones = var.application_gateway.zones

  dynamic "authentication_certificate" {
    for_each = var.application_gateway.authentication_certificate != null ? var.application_gateway.authentication_certificate : []
    content {
      name = authentication_certificate.value.name
      data = authentication_certificate.value.data
    }
  }

  dynamic "trusted_root_certificate" {
    for_each = var.application_gateway.trusted_root_certificate != null ? var.application_gateway.trusted_root_certificate : []
    content {
      name = trusted_root_certificate.value.name
      data = trusted_root_certificate.value.data
    }
  }

  dynamic "ssl_policy" {
    for_each = var.application_gateway.ssl_policy != null ? [var.application_gateway.ssl_policy] : []
    content {
      disabled_protocols   = ssl_policy.value.disabled_protocols
      policy_type          = ssl_policy.value.policy_type
      policy_name          = ssl_policy.value.policy_name
      cipher_suites        = ssl_policy.value.cipher_suites
      min_protocol_version = ssl_policy.value.min_protocol_version
    }
  }

  enable_http2 = var.application_gateway.enable_http2

  dynamic "probe" {
    for_each = var.application_gateway.probe != null ? var.application_gateway.probe : []
    content {
      name                                      = probe.value.name
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      host                                      = probe.value.host
      interval                                  = probe.value.interval
      timeout                                   = probe.value.timeout
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      port                                      = probe.value.port
      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings

      dynamic "match" {
        for_each = probe.value.match != null ? [probe.value.match] : []
        content {
          body        = match.value.body
          status_code = match.value.status_code
        }
      }

      minimum_servers = probe.value.minimum_servers
    }
  }

  dynamic "ssl_certificate" {
    for_each = var.application_gateway.ssl_certificate != null ? var.application_gateway.ssl_certificate : []
    content {
      name                = ssl_certificate.value.name
      data                = ssl_certificate.value.data
      password            = ssl_certificate.value.password
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }
  }

  dynamic "url_path_map" {
    for_each = var.application_gateway.url_path_map != null ? var.application_gateway.url_path_map : []
    content {
      name                                = url_path_map.value.name
      default_backend_address_pool_name   = url_path_map.value.default_backend_address_pool_name
      default_backend_http_settings_name  = url_path_map.value.default_backend_http_settings_name
      default_redirect_configuration_name = url_path_map.value.default_redirect_configuration_name
      default_rewrite_rule_set_name       = url_path_map.value.default_rewrite_rule_set_name

      dynamic "path_rule" {
        for_each = url_path_map.value.path_rule != null ? url_path_map.value.path_rule : []
        content {
          name                        = path_rule.value.name
          paths                       = path_rule.value.paths
          backend_address_pool_name   = path_rule.value.backend_address_pool_name
          backend_http_settings_name  = path_rule.value.backend_http_settings_name
          redirect_configuration_name = path_rule.value.redirect_configuration_name
          rewrite_rule_set_name       = path_rule.value.rewrite_rule_set_name
          firewall_policy_id          = path_rule.value.firewall_policy_id
        }
      }
    }
  }

  dynamic "waf_configuration" {
    for_each = var.application_gateway.waf_configuration != null ? var.application_gateway.waf_configuration : []
    content {
      enabled          = waf_configuration.value.enabled
      firewall_mode    = waf_configuration.value.firewall_mode
      rule_set_type    = waf_configuration.value.rule_set_type
      rule_set_version = waf_configuration.value.rule_set_version != null ? waf_configuration.value.rule_set_version : "3.1"

      dynamic "disabled_rule_group" {
        for_each = waf_configuration.value.disabled_rule_group != null ? waf_configuration.value.disabled_rule_group : []
        content {
          rule_group_name = disabled_rule_group.value.rule_group_name
          rules           = disabled_rule_group.value.rules
        }
      }

      file_upload_limit_mb     = waf_configuration.value.file_upload_limit_mb
      request_body_check       = waf_configuration.value.request_body_check
      max_request_body_size_kb = waf_configuration.value.max_request_body_size_kb

      dynamic "exclusion" {
        for_each = waf_configuration.value.exclusion != null ? waf_configuration.value.exclusion : []
        content {
          match_variable          = exclusion.value.match_variable
          selector_match_operator = exclusion.value.selector_match_operator
          selector                = exclusion.value.selector
        }
      }
    }
  }

  dynamic "custom_error_configuration" {
    for_each = var.application_gateway.custom_error_configuration != null ? var.application_gateway.custom_error_configuration : []
    content {
      status_code           = custom_error_configuration.value.status_code
      custom_error_page_url = custom_error_configuration.value.custom_error_page_url
    }
  }

  firewall_policy_id = var.application_gateway.firewall_policy_id

  dynamic "redirect_configuration" {
    for_each = var.application_gateway.redirect_configuration != null ? var.application_gateway.redirect_configuration : []
    content {
      name                 = redirect_configuration.value.name
      redirect_type        = redirect_configuration.value.redirect_type
      target_listener_name = redirect_configuration.value.target_listener_name
      target_url           = redirect_configuration.value.target_url
      include_path         = redirect_configuration.value.include_path
      include_query_string = redirect_configuration.value.include_query_string
    }
  }

  dynamic "autoscale_configuration" {
    for_each = var.application_gateway.autoscale_configuration != null ? var.application_gateway.autoscale_configuration : []
    content {
      min_capacity = autoscale_configuration.value.min_capacity
      max_capacity = autoscale_configuration.value.max_capacity
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = var.application_gateway.rewrite_rule_set != null ? var.application_gateway.rewrite_rule_set : []
    content {
      name = rewrite_rule_set.value.name

      dynamic "rewrite_rule" {
        for_each = rewrite_rule_set.value.rewrite_rule != null ? rewrite_rule_set.value.rewrite_rule : []
        content {
          name          = rewrite_rule.value.name
          rule_sequence = rewrite_rule.value.rule_sequence

          dynamic "condition" {
            for_each = rewrite_rule.value.condition != null ? rewrite_rule.value.condition : []
            content {
              variable    = condition.value.variable
              pattern     = condition.value.pattern
              ignore_case = condition.value.ignore_case
              negate      = condition.value.negate
            }
          }

          dynamic "request_header_configuration" {
            for_each = rewrite_rule.value.request_header_configuration != null ? rewrite_rule.value.request_header_configuration : []
            content {
              header_name  = request_header_configuration.value.header_name
              header_value = request_header_configuration.value.header_value
            }
          }

          dynamic "response_header_configuration" {
            for_each = rewrite_rule.value.response_header_configuration != null ? rewrite_rule.value.response_header_configuration : []
            content {
              header_name  = response_header_configuration.value.header_name
              header_value = response_header_configuration.value.header_value
            }
          }

          dynamic "response_header_configuration" {
            for_each = rewrite_rule.value.response_header_configuration != null ? rewrite_rule.value.response_header_configuration : []
            content {
              header_name  = response_header_configuration.value.header_name
              header_value = response_header_configuration.value.header_value
            }
          }

          dynamic "url" {
            for_each = rewrite_rule.value.url != null ? rewrite_rule.value.url : []
            content {
              path         = url.value.path
              query_string = url.value.query_string
              reroute      = url.value.reroute
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
    for_each = var.application_gateway.timeouts != null ? [var.application_gateway.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      read   = timeouts.value.read
      delete = timeouts.value.delete
    }
  }
}
