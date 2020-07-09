# Standalone SNS topic

SNS topic connected to [marbot](https://marbot.io/) to forward events to Slack or Microsoft Teams.

## Usage

1. Create a new directory
2. Within the new directory, create a file `main.tf` with the following content:
```
provider "aws" {}

module "marbot-standalone-topic" {
  source  = "marbot-io/marbot-standalone-topic/aws"
  #version = "x.y.z"    # we recommend to pin the version

  endpoint_id      = "" # to get this value, select a channel where marbot belongs to and send a message like this: "@marbot show me my endpoint id"
}
```
3. Run the following commands:
```
terraform init
terraform apply
```

## Update procedure

1. Update the `version`
2. Run the following commands:
```
terraform get
terraform apply
```

## License
All modules are published under Apache License Version 2.0.

## About
A [marbot.io](https://marbot.io/) project. Engineered by [widdix](https://widdix.net).
