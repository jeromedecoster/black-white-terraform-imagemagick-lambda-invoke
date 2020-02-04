locals {
  convert_source = "../lambda/convert.js"
  convert_output = "../lambda/convert.zip"
}

data archive_file convert_zip {
  type        = "zip"
  source_file = local.convert_source
  output_path = local.convert_output
}

resource aws_lambda_function convert_function {
  filename         = data.archive_file.convert_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.convert_zip.output_path)

  function_name = "${var.project_name}-${random_id.random.hex}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "convert.handler"
  runtime       = "nodejs12.x"

  layers = [aws_lambda_layer_version.imagemagick_layer.arn]
}

resource aws_cloudwatch_log_group convert_log_group {
  name = "/aws/lambda/${aws_lambda_function.convert_function.function_name}"
}

output convert_function {
  value = aws_lambda_function.convert_function.function_name
}

output convert_log_group {
  value = aws_cloudwatch_log_group.convert_log_group.name
}

