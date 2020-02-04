# resource null_resource layer {
#   provisioner local-exec {
#     command = <<EOL
#       curl --location \
#           https://github.com/jeromedecoster/imagemagick-lambda-layer/releases/download/v7.0.9-20/imagemagick-7.0.9-20.zip \
#           --output imagemagick.zip
# EOL 
#     # "curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl;"
#   }
# }