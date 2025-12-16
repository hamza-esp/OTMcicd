provider "aws" {
  region = "eu-central-1"
}  
resource "aws_s3_bucket" "b" {
  bucket = "demo-terraform-eks-state-s3-bucket-hamza"
  lifecycle {
    prevent_destroy = false
  }
  }
# terraform locks name of resource, name of the actual dynamoDB is terraform-eks-state-lock
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-eks-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    #name should match hash_key
    type = "S"
  }
  
}