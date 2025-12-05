############################################
# HTTP API — ci-wake backend
# Purpose: expose /wake and /status for wake console
############################################
resource "aws_apigatewayv2_api" "ci_wake" {
  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
  }
}

############################################
# Integrations — /status and /wake → prod Lambdas
############################################
resource "aws_apigatewayv2_integration" "status_integration" {
  api_id                 = aws_apigatewayv2_api.ci_wake.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.status.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "wake_integration" {
  api_id                 = aws_apigatewayv2_api.ci_wake.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.wake.invoke_arn
  payload_format_version = "2.0"
}

############################################
# Routes — GET /status, POST /wake
############################################
resource "aws_apigatewayv2_route" "status_route" {
  api_id    = aws_apigatewayv2_api.ci_wake.id
  route_key = "GET /status"
  target    = "integrations/${aws_apigatewayv2_integration.status_integration.id}"
}

resource "aws_apigatewayv2_route" "wake_route" {
  api_id    = aws_apigatewayv2_api.ci_wake.id
  route_key = "POST /wake"
  target    = "integrations/${aws_apigatewayv2_integration.wake_integration.id}"
}

############################################
# Stage — prod with auto deploy
############################################
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.ci_wake.id
  name        = "prod"
  auto_deploy = true
}

############################################
# Lambda permissions for API Gateway
############################################
resource "aws_lambda_permission" "status_apigw" {
  statement_id  = "apigw-prod-status"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.status.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.ci_wake.execution_arn}/*/GET/status"
}

resource "aws_lambda_permission" "wake_apigw" {
  statement_id  = "apigw-prod-wake"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.wake.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.ci_wake.execution_arn}/*/POST/wake"
}

############################################
# API mapping — bind prod stage to custom domain
# Existing custom domain: api.ci-wake.online
############################################
resource "aws_apigatewayv2_api_mapping" "ci_wake_mapping" {
  api_id      = aws_apigatewayv2_api.ci_wake.id
  domain_name = var.apigw_domain_name
  stage       = aws_apigatewayv2_stage.prod.name
}
