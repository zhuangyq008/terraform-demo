# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Output declarations

output "access_url" {
  value = module.application.go_app_alb_endpoint

}