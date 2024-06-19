#Uncomment if you want to use s3 as backend

/*terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "epoch-time-api/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "your-dynamodb-table"
    encrypt        = true
  }
}
*/

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

