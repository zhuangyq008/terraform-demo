#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.



terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.37.0"
    }
  }
}

provider "aws" {
  region     = "eu-central-1"
}
variable "vpcid" {
  default = "vpc-042b9f31672801f1a"
}
variable "subnetIds" {
  default = ["subnet-0f37fbbedd10e9ad3",  "subnet-071734970b301665a"]
}
variable "securityGroups" {
  default = ["sg-084c1c93e89eec45c"]
}
variable "keyName" {
  default = "my_kp_eu_central_1"
}
module "route53zone" {
  source              = "./modules/route53zone"
  vpc_id              = "${var.vpcid}"
}
module "zk" {
  depends_on          = [module.route53zone]
  source              = "./modules/zk"
  cluster_size        = 3
  key_name            = "${var.keyName}"
  instance_type       = "t2.nano"
  vpc_id              = "${var.vpcid}"
  subnet_ids          = "${var.subnetIds}"
  security_groups     = "${var.securityGroups}"
}

module "shardingsphere" {
  depends_on                    = [module.zk]
  source                        = "./modules/shardingsphere"
  cluster_size                  = 3
  shardingsphere_proxy_version  = "5.2.1"
  key_name                      = "${var.keyName}"
  image_id                      = module.zk.ss_ami
  instance_type                 = "t3.medium"
  attach_iam_role               = module.zk.ss_iam_profile
  lb_listener_port              = 3307
  vpc_id                        = "${var.vpcid}"
  vpc_zone_identifier           = var.subnetIds
  subnet_ids                    = "${var.subnetIds}"
  security_groups               = "${var.securityGroups}"
  zk_servers                    = module.zk.zk_node_domain
}
