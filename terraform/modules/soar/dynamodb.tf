resource "aws_dynamodb_table" "incidents" {
  name         = "innovatech-soar-incidents"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "src_ip"

  attribute {
    name = "src_ip"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}