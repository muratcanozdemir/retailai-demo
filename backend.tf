terraform {
  backend "s3" {
    bucket         = "my-sonarqube-tfstate-bucket" # Given to you
    key            = "sonarqube/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "sonarqube-tfstate-lock" # If given, else omit
    encrypt        = true
  }
}
