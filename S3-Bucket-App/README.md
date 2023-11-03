<h1>
    <span style="color:green;"> Simple-S3-Bucket-App
    </span>
</h1>

The following script are to be used in conjunction with my [cloudformation template files](https://github.com/addnightowl/Full-Stack-Desktop-Apps/tree/main/Cloud-Mania-Passport-Photo-Validation/AWS-CF-Templates-Cloud-Mania-Passport-Photo-Screening) that were created for my Cloud Mania Passport Photo Validation App.

<h2>
    <span style="color:blue;">
    Essentially This Script Will:
    </span>
</h2>

1. Create and Update the AWS Infrastructure using CloudFormation Templates.
2. Create the .env file - if desired.
3. Create and Deploy the Cloud Mania application - if desired.
    - The Cloud Mania application will allow you to upload a passport photo to an S3 bucket.
    - The S3 bucket will trigger a Lambda function to send the photo to Amazon Rekognition for analysis.
    - If the photo is valid or invalid, the Lambda function will send the photo to an S3 bucket and trigger the SNS topic.
    - The SNS topic will trigger a Lambda function to send an email to the user with the validation or invalidion of photo.
    - The Cloud Mania application will allow you to view the results of the photo uploaded to the S3 bucket.
4. Delete the AWS Infrastructure - if desired.
    - The S3 bucket will trigger a Lambda function to delete all photos from the S3 bucket before deleting the bucket.
    - After the S3 bucket is deleted, the CloudFormation stack will be deleted.

<h4>
    <span style="color:red;">
    📝 Additional Notes:
    </span>
</h4>

- Run the command below to check the status of the stack manually:
 ```aws cloudformation describe-stacks --stack-name <user_provided_stack_name> --query "Stacks[0].StackStatus" --output text```

- If you have multiple profiles, you can specify the profile to use with the command below:
 ```aws cloudformation describe-stacks --stack-name <user_provided_stack_name> --query "Stacks[0].StackStatus" --output text --profile <profile_name>```

- You may need to configure your AWS CLI with the command below:
     ```aws configure --profile <profile_name>```
  - And provide the following information:
    - ```AWS Access Key ID [None]: <access_key_id>```
    - ```AWS Secret Access Key [None]: <secret_access_key>```
    - ```Default region name [None]: <region_name>```
    - ```Default output format [None]: <output_format>```
