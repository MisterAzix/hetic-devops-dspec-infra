resource "aws_sns_topic" "sns" {
  name = "hetic-dspec-sns"
}

resource "aws_cloudwatch_metric_alarm" "spark_apps_pending_alarm" {
  alarm_name          = "hetic-dspec-spark-apps-pending-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "AppsPending"
  namespace           = "AWS/ElasticMapReduce"
  period              = "300"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Alarm when Spark has pending applications"
  dimensions = {
    JobFlowId = aws_emr_cluster.cluster.id
  }
  actions_enabled = true
  alarm_actions   = [aws_sns_topic.sns.arn]
}

resource "aws_cloudwatch_metric_alarm" "mongodb_error_alarm" {
  alarm_name          = "hetic-dspec-mongodb-error-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ErrorCount"
  namespace           = "YourNamespace"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarm when MongoDB logs contain errors"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.sns.arn]
}
