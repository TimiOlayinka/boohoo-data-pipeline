locals {
  lambda_names = [
    "cx_tickets",
    "cx_surveys",
    "supply_chain_warehouse",
    "supply_chain_deliveries",
    "supply_chain_otif"
  ]
}

resource "aws_lambda_function" "data_generators" {
  for_each      = toset(local.lambda_names)
  
  function_name = "hnb-${replace(each.value, "_", "-")}"
  role          = data.aws_iam_role.lambda_exec_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 512

  filename         = "${path.module}/../dist/${each.value}.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/${each.value}.zip")
}
