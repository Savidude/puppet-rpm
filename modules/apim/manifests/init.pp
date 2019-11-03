# ----------------------------------------------------------------------------
#  Copyright (c) 2018 WSO2, Inc. http://www.wso2.org
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# ----------------------------------------------------------------------------

# Class: apim
# Init class of API Manager default profile
class apim inherits apim::params {

  # Install system packages
  package { $packages:
    ensure => installed
  }

  file { "move-installer-scripts":
    ensure => "directory",
    source => "puppet:///modules/${module_name}/",
    recurse => "remote",
    path => "${product_dir}",
  }

  exec { "unzip-pack":
    command => "unzip ${product_dir}/products/${product_binary}",
    path    => "/usr/bin/",
    cwd     => "${product_dir}/products/",
    require => File["move-installer-scripts"]
  }

  # Copy configuration changes to the installed directory
  $template_list.each |String $template| {
    file { "${product_dir}/products/wso2am-3.0.0/${template}":
      ensure  => file,
      mode    => '0644',
      content => template("${module_name}/carbon-home/${template}.erb"),
      require => Exec["unzip-pack"],
    }
  }

  exec { "delete-pack":
    command => "rm ${product_dir}/products/${product_binary}",
    path    => "/usr/bin/",
    require => Exec["unzip-pack"],
  }

  exec { "repackage":
    command => "zip -r ${product_binary} wso2am-${version}",
    path    => "/usr/bin/",
    cwd     => "${product_dir}/products/",
    require => Exec["delete-pack"],
  }

  exec { "delete-server":
    command => "rm -rf wso2am-${version}",
    path    => "/usr/bin/",
    cwd     => "${product_dir}/products/",
    require => Exec["repackage"],
  }

  exec { "build-installer":
    command => "/bin/sh ${product_dir}/generate_installers.sh",
    cwd     => "${product_dir}",
  }
}
