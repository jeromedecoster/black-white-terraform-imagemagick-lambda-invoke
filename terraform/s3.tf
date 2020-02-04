locals {
  imagemagick_source = "../layers/imagemagick-7.0.9-20.zip"
  imagemagick_key = "layers/imagemagick-7.0.9-20.zip"
  squirrel_source = "../uploads/squirrel.jpg"
  squirrel_key = "uploads/squirrel.jpg"
}

#
# bucket for the project
#

resource aws_s3_bucket bucket {
  bucket = "${var.project_name}-${random_id.random.hex}"
  acl    = "private"

  force_destroy = true
}

resource aws_s3_bucket_object squirrel {
  bucket = aws_s3_bucket.bucket.id
  source = local.squirrel_source
  key    = local.squirrel_key
}

output bucket {
  value = aws_s3_bucket.bucket.id
}

#
# imagemagick lambda layer
#

resource aws_s3_bucket_object imagemagick {
  bucket = aws_s3_bucket.bucket.id
  source = local.imagemagick_source
  key    = local.imagemagick_key
  etag = filemd5(local.imagemagick_source)
}

resource aws_lambda_layer_version imagemagick_layer {
  layer_name = "imagemagick"
  s3_bucket = aws_s3_bucket.bucket.id
  s3_key = aws_s3_bucket_object.imagemagick.id
  compatible_runtimes = ["nodejs12.x"]
}
