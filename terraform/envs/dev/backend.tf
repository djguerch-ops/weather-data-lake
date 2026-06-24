terraform {
  backend "s3" {
    bucket = "weather-terraform-state-563683519302"
    key    = "envs/dev/terraform.tfstate"
    region = "eu-west-1"
  }
}