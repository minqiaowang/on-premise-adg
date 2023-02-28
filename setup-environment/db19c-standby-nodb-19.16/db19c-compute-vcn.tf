variable "tenancy_ocid" {}
variable "region" {}
// variable "display_name" { default = "workshop" }
variable "instance_shape" {
  default = "VM.Standard.E4.Flex"
}
variable "compartment_ocid" {}
variable "ssh_public_key" {}

//variable "num_instances" {
//  default = "1"
//}

terraform {
  required_version = ">= 0.12.0"
}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

provider "oci" {
  tenancy_ocid = "${var.tenancy_ocid}"
  region       = "${var.region}"
}


variable "VCN-example" { default = "10.0.0.0/16" }
resource "oci_core_virtual_network" "example-vcn" {
  cidr_block     = "${var.VCN-example}"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "standby-vcn"
  dns_label      = "standbyvcn"
}

# --- Create a new Internet Gateway
resource "oci_core_internet_gateway" "example-ig" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "standby-internet-gateway"
  vcn_id         = "${oci_core_virtual_network.example-vcn.id}"
}
#---- Create Route Table
resource "oci_core_route_table" "example-rt" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.example-vcn.id}"
  display_name   = "standby-route-table"
  route_rules {
    cidr_block        = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.example-ig.id}"
  }
}

#--- Create a public Subnet 1 in AD1 in the new vcn
resource "oci_core_subnet" "example-public-subnet1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name")}"
  cidr_block          = "10.0.1.0/24"
  display_name        = "standby-public-subnet1"
  dns_label           = "subnet1"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.example-vcn.id}"
  route_table_id      = "${oci_core_route_table.example-rt.id}"
  dhcp_options_id     = "${oci_core_virtual_network.example-vcn.default_dhcp_options_id}"
}


#--- Defualt  Network Security List

resource "oci_core_default_security_list" "default-security-list" {
  manage_default_resource_id = "${oci_core_virtual_network.example-vcn.default_security_list_id}"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }


  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 1521
      max = 1521
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 443
      max = 443
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 22
      max = 22
    }

  }
}

##
# Found image id from Marketplace and get signature
##
#    Resource Elements

resource "oci_core_app_catalog_subscription" "generated_oci_core_app_catalog_subscription" {
	compartment_id = "${var.compartment_ocid}"
	eula_link = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.eula_link}"
	listing_id = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.listing_id}"
	listing_resource_version = "Oracle_Database_19.16.0.0.220719_-_OL7U9"
	oracle_terms_of_use_link = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.oracle_terms_of_use_link}"
	signature = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.signature}"
	time_retrieved = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.time_retrieved}"
}

resource "oci_core_app_catalog_listing_resource_version_agreement" "generated_oci_core_app_catalog_listing_resource_version_agreement" {
	listing_id = "ocid1.appcataloglisting.oc1..aaaaaaaaheuwo4wunrr4eqn6hab36sgeur5xb25nbs5v4f4w3cytjcqysurq"
	listing_resource_version = "Oracle_Database_19.16.0.0.220719_-_OL7U9"
}

# Compute Instances

resource "oci_core_instance" "ssworkshop_instance" {
 // count               = "${var.num_instances}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "standby"
  shape               = "${var.instance_shape}"
  shape_config {
		memory_in_gbs = "16"
		ocpus = "1"
	}
  
  create_vnic_details {
    subnet_id = "${oci_core_subnet.example-public-subnet1.id}"
    display_name     = "standby"
    assign_public_ip = true
    hostname_label   = "standby"
  }

  source_details {
    source_type = "image"
    source_id   = "ocid1.image.oc1..aaaaaaaa5ji3j4qm5m3xwi4t3233wpkv7meqm5vbwrlfzo7tuu6au3ahth3a"

  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(file("custom-db.sh"))}"
  }
  depends_on = [
		oci_core_app_catalog_subscription.generated_oci_core_app_catalog_subscription
	]
}

output "primary_public_ips" {
  value = ["${oci_core_instance.ssworkshop_instance.public_ip}"]
}
