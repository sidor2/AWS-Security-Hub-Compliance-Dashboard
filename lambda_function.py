import json
import boto3

def lambda_handler(event, context):
    sns = boto3.client('sns')
    topic_arn = "${aws_sns_topic.alerts.arn}"

    for record in event['detail']['findings']:
        severity = record['Severity']['Label']
        title = record['Title']
        description = record['Description']
        
        if severity in ['CRITICAL', 'HIGH']:
            message = f"Security Hub Finding\nTitle: {title}\nSeverity: {severity}\nDescription: {description}"
            sns.publish(
                TopicArn=topic_arn,
                Message=message,
                Subject=f"High Severity Finding: {title}"
            )

    return {
        'statusCode': 200,
        'body': json.dumps('Processed findings')
    }