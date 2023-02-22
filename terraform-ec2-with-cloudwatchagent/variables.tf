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

variable "cluster_size" {
  type        = number
  default = 3
  description = "The cluster size that same size as available_zones"
}

variable "app_version" {
  type        = string
  default = "1.0"
  description = "The app version"
}

variable "image_id" {
  type        = string
  default = "ami-094bbd9e922dc515d"
  description = "The AMI id"
}

variable "key_name" {
  type        = string
  default = "my-kp-default"
  description = "the ssh keypair for remote connection"
}

variable "instance_type" {
  type        = string
  default = "t3.medium"
  description = "The EC2 instance type"
}


