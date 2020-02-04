locals {
  aws_region = "eu-west-3"
}

provider aws {
  region = local.aws_region
}
resource random_id random {
  byte_length = 3
}

variable project_name {
  type        = string
  default     = "black-white-imagemagick"
}

output region {
  value = local.aws_region
}

#
# write some variables to settings.sh
#

resource null_resource settings_sh {

  triggers = {
    #everytime = uuid()
    rarely = join("-", [
      local.aws_region, 
      aws_s3_bucket.bucket.id, 
      aws_lambda_function.convert_function.function_name,
      fileexists("../settings.sh")
    ])
  }

  provisioner local-exec {
    command = <<EOF
echo 'AWS_REGION=${local.aws_region}
BUCKET=${aws_s3_bucket.bucket.id}
FUNCTION=${aws_lambda_function.convert_function.function_name}' >> ../settings.sh;
awk --include inplace '!a[$0]++' ../settings.sh
EOF
  }
}