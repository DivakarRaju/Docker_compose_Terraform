def ping_pong(event, context):
    response = {
        "statusCode": 200,
        "body": {"message": "Hello"}
    }
    return response
