terraform {
  backend "gcs" {
    bucket = "ns-gcs-sigma-outcome"
    prefix = "tfstate/novascope"
    impersonate_service_account = "817261716888-compute@developer.gserviceaccount.com"

  }
}
