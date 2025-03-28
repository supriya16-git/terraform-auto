# Create EC2 instance
resource "aws_instance" "cherry_instance" {
  ami           = "ami-0e35ddab05955cf57"  # Replace with valid AMI ID
  instance_type = "t2.micro"
  key_name      = "Jenkinslave"                   # Replace with key name
  tags = {
    Name = "jenkins-ec2-instance"
  }
}

# Create S3 bucket
resource "aws_s3_bucket" "cherry_bucket" {
  bucket = "23rd-cherry-bucket"
  lifecycle {
    ignore_changes = [bucket]
  }
}
