import json 
import boto3 
import os 
import logging

logging.getLogger().setLevel(logging.INFO)

def lambda_handler(event, context): 
    sns = boto3.client('sns') 
    topic_arn = os.environ['SNS_TOPIC_ARN']

    try:
        for record in event['detail']['findings']:
            severity = record['Severity']['Label']
            title = record.get('Title', 'Untitled Finding')
            description = record.get('Description', 'No description available')
            
            logging.info(f"Processing finding: Severity={severity}, Title={title}")
            
            # Publish to SNS for all findings (severity filtered by EventBridge)
            message = f"Security Hub Finding\nTitle: {title}\nSeverity: {severity}\nDescription: {description}"
            sns.publish(
                TopicArn=topic_arn,
                Message=message,
                Subject=f"{severity} Severity Finding: {title[:100]}"  # Truncate subject
            )
            logging.info(f"Published SNS message for finding: {title}")
        
        return {
            'statusCode': 200,
            'body': json.dumps('Processed findings')
        }

    except Exception as e:
        logging.error(f"Error processing findings: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error: {str(e)}")
        }