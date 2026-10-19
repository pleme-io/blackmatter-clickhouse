{ lib, terraform-providers }:
let
  version = "3.39.0";
  rev = "v${version}";
  project = "github.com/ClickHouse/terraform-provider-clickhouse/internal/project";
in
(terraform-providers.mkProvider {
  owner = "ClickHouse";
  repo = "terraform-provider-clickhouse";
  inherit rev version;
  spdx = "Apache-2.0";
  hash = "sha256-HClmggBZlDCaWbXD0/0xB26YbEWUSqI82DifAQiJ5S8=";
  vendorHash = "sha256-2EkDCCJSUYwehsCZ7Ucnc/hE4oxh9bAWVtf6EbKFE2E=";
  homepage = "https://registry.terraform.io/providers/ClickHouse/clickhouse";
  provider-source-address = "registry.terraform.io/ClickHouse/clickhouse";
}).overrideAttrs
  (old: {
    ldflags = old.ldflags ++ [
      "-X ${project}.version=${version}"
      "-X ${project}.commit=${rev}"
    ];
    meta = old.meta // {
      description = "ClickHouse Cloud Terraform/OpenTofu provider";
    };
  })
