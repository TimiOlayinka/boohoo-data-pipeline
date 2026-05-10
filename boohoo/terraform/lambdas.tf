locals {
  lambda_names = [
    "ecommerce_customers",
    "ecommerce_orders",
    "ecommerce_products",
    "marketing_email_campaigns",
    "marketing_ga4_sessions",
    "marketing_google_ads",
    "marketing_influencers",
    "marketing_meta_ads",
    "marketing_tiktok_ads"
  ]
}

resource "aws_lambda_function" "data_generators" {
  for_each      = toset(local.lambda_names)
  
  function_name = "boohoo-${replace(each.value, "_", "-")}"
  role          = data.aws_iam_role.lambda_exec_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 512

  filename         = "${path.module}/../dist/${each.value}.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/${each.value}.zip")
}
