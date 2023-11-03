#!/bin/bash

############################################################################################################################################################
###-----------------------------------------------------------------DESCRIPTION BELOW-------------------------------------------------------------------------###
############################################################################################################################################################
# The following script are to be used in conjunction with the CloudFormation template files for the Cloud Mania Passport Photo Validation App.
# Which can be found at https://github.com/addnightowl/Full-Stack-Desktop-Apps/tree/main/Cloud-Mania-Passport-Photo-Validation/AWS-CF-Templates-Cloud-Mania-Passport-Photo-Screening

# This script will:
    # 1. Create and Update the AWS Infrastructure using CloudFormation Templates.
    # 2. Create the .env file - if desired.
    # 3. Create and Deploy the Cloud Mania application - if desired.
        # - The Cloud Mania application will allow you to upload a passport photo to an S3 bucket.
        # - The S3 bucket will trigger a Lambda function to send the photo to Amazon Rekognition for analysis.
        # - If the photo is valid or invalid, the Lambda function will send the photo to an S3 bucket and trigger the SNS topic.
        # - The SNS topic will trigger a Lambda function to send an email to the user with the validation or invalidion of photo.
        # - The Cloud Mania application will allow you to view the results of the photo uploaded to the S3 bucket.
    # 4. Delete the AWS Infrastructure - if desired.
        # - The S3 bucket will trigger a Lambda function to delete all photos from the S3 bucket before deleting the bucket.
        # - After the S3 bucket is deleted, the CloudFormation stack will be deleted.

# Additional Notes:
    # Run the command below to check the status of the stack manually:
        # aws cloudformation describe-stacks --stack-name <user_provided_stack_name> --query "Stacks[0].StackStatus" --output text

    # If you have multiple profiles, you can specify the profile to use with the command below:
        # aws cloudformation describe-stacks --stack-name <user_provided_stack_name> --query "Stacks[0].StackStatus" --output text --profile <profile_name>

    # You may need to configure your AWS CLI with the command below:
        # aws configure --profile <profile_name>
        # And provide the following information:
            # AWS Access Key ID [None]: <access_key_id>
            # AWS Secret Access Key [None]: <secret_access_key>
            # Default region name [None]: <region_name>
            # Default output format [None]: <output_format>

############################################################################################################################################################
###-----------------------------------------------------------------DESCRIPTION ABOVE-------------------------------------------------------------------------###
############################################################################################################################################################

############################################################################################################################################################
###-----------------------------------------------------------------FUNCTIONS BELOW----------------------------------------------------------------------###
############################################################################################################################################################

# Function to check stack status and wait for the stack to reach the desired status.
check_stack_status() {
    stack_name=$1
    desired_status=$2

    while true; do
        # Get stack status
        current_status=$(aws cloudformation describe-stacks --stack-name "$stack_name" --query "Stacks[0].StackStatus" --output text)
        if [[ $? -ne 0 ]]; then
            echo "Failed to get stack status because the stack does not exist or was deleted."
            exit 1
        fi

        if [[ $current_status == $desired_status ]]; then
            echo "Stack '$stack_name' is '$desired_status'"
            break
        elif [[ $current_status == "ROLLBACK_COMPLETE" || $current_status == "UPDATE_ROLLBACK_COMPLETE" ]]; then
            echo "Stack update failed and was rolled back"
            exit 1
        elif [[ $current_status == "DELETE_COMPLETE" ]]; then
            echo "Stack '$stack_name' has been deleted"
            break
        else
            echo "Waiting for stack '$stack_name' to reach status '$desired_status'..."
            sleep 30
        fi
    done
}

# Function to prompt user to provide the desired stack name and CloudFormation templates path. Then, check if the stack name and CloudFormation templates path are empty.
user_inputs(){
    # Prompt user to provide the desired stack name
    echo "Please enter the stack name: "
    read -p "Input: " user_provided_stack_name

    # Check if the stack name is empty
    if [[ -z "$user_provided_stack_name" ]]; then
        echo "Stack name cannot be empty."
        exit 1
    fi

    # Prompt user to provide the full path to the Cloud Mania CloudFormation templates
    echo "Please enter the full path to the Cloud Mania CloudFormation templates: "
    read -p "Input: " cf_temp_path

    # Check if the CloudFormation templates path is empty
    if [[ -z "$cf_temp_path" ]]; then
        echo "CloudFormation templates path cannot be empty."
        exit 1
    fi
}

# Function to check if the stack creation failed.
stack_creation_status() {
    if [[ $? -ne 0 ]]; then
        echo "Failed to create stack."
        exit 1
    fi
}

# Function to check if the stack update failed.
stack_update_status() {
    if [[ $? -ne 0 ]]; then
        echo "Failed to update stack."
        exit 1
    fi
}

# Function to deploy the app, delete the stack, or exit the script.
manage_stack_app_script() {
    local choice
    local open_cloud_mania_app="python3 S3BucketCode.py"
    local delete_stack="aws cloudformation delete-stack --stack-name $user_provided_stack_name"

    while true; do
        echo "Menu: Select an option to perform an action."
        echo "1. Deploy the Cloud Mania app on your desktop."
        echo "2. Delete the stack."
        echo "3. Exit."
        echo "Choose an option [1/2/3]: " 
        read -p "Input: " choice

        case $choice in
            1)
                # If the file already exists, delete it and create a new one.
                if [[ -f .env ]]; then
                    echo "File '.env' exists. Removing it now to create a new one..."
                    rm .env
                    echo "File '.env' has been deleted."
                fi
                # Create .env file to store the AWS credentials.
                echo "Creating the .env file..."
                create_env_vars_file
                # Prompt user to edit the .env file and enter done when finished.
                while true; do
                    echo "Please edit the .env file and enter 'done' when finished."
                    read -p "Input: " edit_env_file
                    # Break the loop if the user entered 'done'.
                    if [[ $edit_env_file == "done" ]]; then
                        echo "The .env file has been edited."
                        break
                    fi
                done

                # If the file already exists, delete it and create a new one.
                if [[ -f S3BucketCode.py ]]; then
                    echo "File 'S3BucketCode.py' exists. Removing it now to create a new one..."
                    rm S3BucketCode.py
                    echo "File 'S3BucketCode.py' has been deleted."
                fi
                # Create S3BucketCode.py file to deploy the app on desktop.
                echo "Creating the S3BucketCode.py file..."
                create_s3bucketcode_file

                # Deploy App on desktop.
                echo "Deploying the Cloud Mania app on your desktop..."
                eval $open_cloud_mania_app
                ;;

            2)
                # If the files 'S3BucketCode.py' exists, delete it.
                if [[ -f S3BucketCode.py ]]; then
                    echo "File 'S3BucketCode.py' exists. Removing it now..."
                    rm S3BucketCode.py
                    echo "File 'S3BucketCode.py' has been deleted."
                fi

                # If the file '.env' exists, delete it.
                if [[ -f .env ]]; then
                    echo "File '.env' exists. Removing it now..."
                    rm .env
                    echo "File '.env' has been deleted."
                fi

                # Delete the stack.
                eval $delete_stack
                # Check stack status for deletion.
                check_stack_status "$user_provided_stack_name" "DELETE_COMPLETE"
                ;;

            3)
                # If the file 'S3BucketCode.py' exists, delete it.
                if [[ -f S3BucketCode.py ]]; then
                    echo "File 'S3BucketCode.py' exists. Removing it now..."
                    rm S3BucketCode.py
                    echo "File 'S3BucketCode.py' has been deleted."
                fi

                # If the file '.env' exists, delete it.
                if [[ -f .env ]]; then
                    echo "File '.env' exists. Removing it now..."
                    rm .env
                    echo "File '.env' has been deleted."
                fi

                # Exit.
                echo "Exiting..."
                exit 0
                ;;

            *)
                # Invalid choice if user enters a number other than 1, 2, or 3.
                echo "Invalid choice. Please enter a number shown in the menu."
                ;;
        esac
    done
}


# Function to create the .env file
create_env_vars_file(){
    # Create the .env file.
    cat << EOF > .env
# This file contains the environment variables for:
#     - Path to this .env file - containing the following variables:
#     - AWS Access Key ID
#     - AWS Secret Access Key
#     - AWS Region
#     - API Gateway Name

# Full path to the .env file that contains the AWS credentials.
AWS_ENV_PATH="<Input /full/path/to/.env>"

# AWS Access Key ID.
AWS_ACCESS_KEY="<Input Access Key ID for the IAM User>"

# AWS Secret Access Key.
AWS_SECRET_KEY="<Input Secret Access Key for the IAM User>"

# AWS Region.
AWS_REGION="<Input AWS Region>"

# API Gateway Name.
API_NAME="<Input API Gateway Name>"

EOF

    echo "The .env file has been created."
}

# Function to create the S3BucketCode.py file
create_s3bucketcode_file() {
    # Create the S3BucketCode.py file.
    cat << EOF > S3BucketCode.py
'''
Tkinter GUI application that allows users to upload images to an AWS S3 bucket 
and if the file is an image - view the results (if that image passes/fails the passport validation process) 
of the image uploaded to the bucket.
'''

# Importing necessary modules for the GUI, file dialog, AWS connection, and other utilities.
import tkinter as tk
# Importing the file dialog module from tkinter.
from tkinter import filedialog
# Importing the boto3 library for interacting with AWS services.
import boto3
# Importing the NoCredentialsError and PartialCredentialsError exceptions from the botocore library.
from botocore.exceptions import NoCredentialsError, PartialCredentialsError
# Importing the os module to work with the operating system.
import os
# Importing the load_dotenv function from the dotenv library.
from dotenv import load_dotenv
# Importing the Image and ImageTk modules from the PIL library.
from PIL import Image, ImageTk
# Importing the requests library to make HTTP requests.
import requests
# Importing the API Gateway module from the apigatewayv2_module.py file.
import apigatewayv2_module as apigw
# Importing the time module to sleep for a few seconds.
import time

# Load the environment variables for AWS credentials from the specified path.
load_dotenv(os.environ.get("AWS_ENV_PATH"))

# Setting up AWS credentials to access S3.
AWS_ACCESS_KEY = os.environ.get("AWS_ACCESS_KEY")
AWS_SECRET_KEY = os.environ.get("AWS_SECRET_KEY")
AWS_REGION = os.environ.get("AWS_REGION")
API_NAME = os.environ.get("API_NAME")

# List of allowed extensions for images.
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

# Initialize the S3 client with the provided credentials and region.
s3 = boto3.client(
    's3',
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
    region_name=AWS_REGION,
)

# Function to check if the file is an image.
def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# Function to show a preview of the selected image in the GUI.
def show_preview(file_path):
    if allowed_file(file_path):
        image = Image.open(file_path)
        image.thumbnail((100, 100))
        photo = ImageTk.PhotoImage(image)
        preview_label.config(image=photo)
        preview_label.image = photo
    else:
        preview_label.config(text="Preview not available for non-image files.", fg="red")

# Function to upload a file to the specified S3 bucket and/or folder.
def upload_file(file_path, bucket_name):
    file_name = os.path.basename(file_path)
    
    try:
        s3.upload_file(file_path, bucket_name, file_name)
        upload_message = f'Successfully uploaded to {bucket_name}/{file_name}'
        message_label.config(text=upload_message, fg="green")
        if allowed_file(file_name):
            get_validation_result(file_name)
    except (NoCredentialsError, PartialCredentialsError):
        message_label.config(text='No credentials found.', fg="red")
    except Exception as e:
        message_label.config(text=f'An error occurred: {e}', fg="red")

def get_invoke_url(api_name):
    http_apis = apigw.list_http_apis()
    for api in http_apis:
        if api['Name'] == api_name:
            api_id = api['ApiId']
            break
    else:
        print(f"No API found with name {api_name}")
        return None

    api_stages = apigw.get_api_stages(api_id)
    if not api_stages:
        print(f"No stages found for API ID: {api_id}")
        return None

    # Assuming you're interested in the first stage of the API
    stage_name = api_stages[0]['StageName']
    region = boto3.session.Session().region_name  # Get current region
    invoke_url = apigw.construct_invoke_url(api_id, region, stage_name)

    return invoke_url

# Function to get validation result for the uploaded image.
def get_validation_result(image_name):
    invoke_url = get_invoke_url(API_NAME)  # Get the invoke URL dynamically 
    # Sleep for 5 seconds to allow the API to be deployed.
    time.sleep(5)
    if not invoke_url:
        message_label.config(text='Failed to get the invoke URL.', fg="red")
        return
    url = f'{invoke_url}/images?imageName={image_name}'
    response = requests.get(url)
    if response.status_code == 200:
        response_json = response.json()
        validation_result = response_json.get("ValidationResult")
        if validation_result == "FAIL":
            failure_reasons = response_json.get("FailureReasons")
            message = f'Validation Result: {validation_result}\nFailure Reasons: {failure_reasons}'
            results_label.config(text=message, fg="red")
        else:
            validation_message = f'Validation Result: {validation_result}'
            results_label.config(text=validation_message, fg="blue")

# Function to refresh the GUI.
def refresh_gui():
    # Resetting the preview label.
    preview_label.config(image=None, text="")
    # Resetting the message label.
    message_label.config(text="")
    # Resetting the results label.
    results_label.config(text="")

# Function to open file dialog and get the selected file path.
def open_file_dialog():
    # Refresh the GUI each time a new file dialog is opened.
    refresh_gui()
    file_path = filedialog.askopenfilename()
    bucket_name = bucket_entry.get()
    if file_path and bucket_name:
        show_preview(file_path)
        upload_file(file_path, bucket_name)

# Creating the main GUI window.
root = tk.Tk()
# Setting the title of the GUI window.
root.title("Cloud Mania Passport Photo Validation App")
# Setting the size of the GUI window.
root.geometry("500x500")

# Creating and placing the 'Upload File' button on the GUI.
upload_button = tk.Button(root, text="Upload File", command=open_file_dialog)
# Placing the Upload File Button on the GUI.
upload_button.pack(pady=10)

# Creating and placing the 'Bucket Name' label and entry field on the GUI.
bucket_label = tk.Label(root, text="Bucket Name (Required):")
# Placing the Bucket Name Label on the GUI.
bucket_label.pack(pady=5)
# Creating the Bucket Name Entry field on the GUI.
bucket_entry = tk.Entry(root)
# Placing the Bucket Name Entry field on the GUI.
bucket_entry.pack(pady=5)

# Creating and placing the message label to display messages on the GUI.
message_label = tk.Label(root, text="", wraplength=350)
# Placing the message label on the GUI.
message_label.pack(pady=5)

# Creating and placing the results label to display validation results on the GUI.
results_label = tk.Label(root, text="", wraplength=350)
# Placing the results label on the GUI.
results_label.pack(pady=5)

# Creating and placing the label to display the image preview on the GUI.
preview_label = tk.Label(root)
# Placing the image preview label on the GUI.
preview_label.pack(pady=10)

# Start the Tkinter event loop to run the GUI.
root.mainloop()

EOF

    echo "File 'S3BucketCode.py' has been created!"
}

############################################################################################################################################################
###-----------------------------------------------------------------FUNCTIONS ABOVE----------------------------------------------------------------------###
############################################################################################################################################################

############################################################################################################################################################
###-------------------------------------------------------------------MAIN BELOW------------------------------------------------------------------------###
############################################################################################################################################################
# Users/electi22/Desktop/AWS-WebApp-Project/AWS-CF-Templates-Cloud-Mania-Passport-Photo-Screening
# Call the 'user_inputs' function.
user_inputs

# Create Initial Stack with Template 01.
aws cloudformation create-stack --stack-name $user_provided_stack_name --template-body file:///$cf_temp_path/01-cloud-mania-s3-template.yaml --capabilities CAPABILITY_NAMED_IAM
# Call the 'stack_creation_status' function.
stack_creation_status
# Check stack status before updating.
check_stack_status "$user_provided_stack_name" "CREATE_COMPLETE"
# Echo the stack status.
echo "The Initial Stack has been created with Template 01."

# Update Stack with Template 02.
aws cloudformation update-stack --stack-name $user_provided_stack_name --template-body file:///$cf_temp_path/02-cloud-mania-add-s3-notification.yaml --capabilities CAPABILITY_NAMED_IAM
# Call the 'stack_update_status' function.
stack_update_status
# Check stack status before next update.
check_stack_status "$user_provided_stack_name" "UPDATE_COMPLETE"
# Echo the Stack Update Status.
echo "The Stack has been updated with Template 02."

# Update Stack with Template 03.
aws cloudformation update-stack --stack-name $user_provided_stack_name --template-body file:///$cf_temp_path/03-cloud-mania-add-sns-topic.yaml --capabilities CAPABILITY_NAMED_IAM
# Call the 'stack_update_status' function.
stack_update_status
# Check stack status before next update.
check_stack_status "$user_provided_stack_name" "UPDATE_COMPLETE"
# Echo the Stack Update Status.
echo "The Stack has been updated with Template 03."

# Update Stack with Template 04.
aws cloudformation update-stack --stack-name $user_provided_stack_name --template-body file:///$cf_temp_path/04-cloud-mania-add-lambda-destination.yaml --capabilities CAPABILITY_NAMED_IAM
# Call the 'stack_update_status' function.
stack_update_status
# Check stack status before next update.
check_stack_status "$user_provided_stack_name" "UPDATE_COMPLETE"
# Echo the Stack Update Status.
echo "The Stack has been updated with Template 04."

# Update Stack  with Template 05.
aws cloudformation update-stack --stack-name $user_provided_stack_name --template-body file:///$cf_temp_path/05-cloud-mania-add-image-request-function.yaml --capabilities CAPABILITY_NAMED_IAM
# Call the 'stack_update_status' function.
stack_update_status
# Check stack status before next update.
check_stack_status "$user_provided_stack_name" "UPDATE_COMPLETE"
# Echo the Stack Update Status.
echo "The Stack has been updated with Template 05."

# Update Stack with Template 06.
aws cloudformation update-stack --stack-name $user_provided_stack_name --template-body file:///$cf_temp_path/06-cloud-mania-add-api-gateway-endpoint.yaml --capabilities CAPABILITY_NAMED_IAM
# Call the 'stack_update_status' function.
stack_update_status
# Check stack status before next update.
check_stack_status "$user_provided_stack_name" "UPDATE_COMPLETE"
# Echo the Stack Update Status.
echo "The Stack has been updated with Template 06."

# Update Stack with Template 07.
aws cloudformation update-stack --stack-name $user_provided_stack_name --template-body file:///$cf_temp_path/07-cloud-mania-add-s3-deletion-function.yaml --capabilities CAPABILITY_NAMED_IAM
# Call the 'stack_update_status' function.
stack_update_status
# Check stack status before next update.
check_stack_status "$user_provided_stack_name" "UPDATE_COMPLETE"
# Echo the Stack Update Status.
echo "The Stack has been updated with Template 07."

# Call the function 'manage_stack_app_script' and pass the arguments.
manage_stack_app_script

############################################################################################################################################################
###-------------------------------------------------------------------MAIN ABOVE------------------------------------------------------------------------###
############################################################################################################################################################
