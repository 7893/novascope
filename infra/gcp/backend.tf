terraform {
  backend "gcs" {
    bucket = "ns-gcs-sigma-outcome"
    prefix = "tfstate/novascope"
  }
}
