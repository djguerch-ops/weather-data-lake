# ─────────────────────────────────────────────────────────────
# Streaming infrastructure — Kinesis + Lambda
# ─────────────────────────────────────────────────────────────

resource "aws_kinesis_stream" "weather_events" {
  name             = "weather-events-stream"
  shard_count      = 1
  retention_period = 24

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    Project     = "weather-data-lake"
    Environment = "dev"
  }
}

resource "aws_iam_role" "lambda_weather_consumer" {
  name = "weather-lambda-kinesis-consumer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_weather_consumer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_kinesis_to_s3" {
  name = "weather-lambda-kinesis-to-s3"
  role = aws_iam_role.lambda_weather_consumer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:DescribeStreamSummary",
          "kinesis:ListShards",
          "kinesis:ListStreams"
        ]
        Resource = aws_kinesis_stream.weather_events.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "arn:aws:s3:::weather-data-dev-563683519302/streaming/*"
      }
    ]
  })
}

resource "aws_lambda_function" "weather_kinesis_to_s3" {
  function_name    = "weather-kinesis-to-s3"
  role             = aws_iam_role.lambda_weather_consumer.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128
  filename         = "../../../src/lambda/kinesis_to_s3/build/lambda.zip"
  source_code_hash = filebase64sha256("../../../src/lambda/kinesis_to_s3/build/lambda.zip")

  environment {
    variables = {
      TARGET_BUCKET = "weather-data-dev-563683519302"
      TARGET_PREFIX = "streaming/events"
    }
  }

  tags = {
    Project     = "weather-data-lake"
    Environment = "dev"
  }
}

resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn                   = aws_kinesis_stream.weather_events.arn
  function_name                      = aws_lambda_function.weather_kinesis_to_s3.arn
  starting_position                  = "LATEST"
  batch_size                         = 100
  maximum_batching_window_in_seconds = 5
}