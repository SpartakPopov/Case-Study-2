resource "aws_ssm_parameter" "pfsense_api_key" {
  name        = "/innovatech/soar/pfsense-api-key"
  description = "REST API key the SOAR Lambda uses on pfSense R2"
  type        = "SecureString"
  value       = var.pfsense_api_key
}
