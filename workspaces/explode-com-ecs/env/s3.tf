resource "aws_s3_bucket" "important_stuff_bucket" {
  bucket = "explodeme-com-secret-stuff"
}
data "local_file" "important_file" {
  filename = "${path.module}/extremely_important_stuff.txt"
}
resource  "aws_s3_object" "important_stuff_s3_object" {
  bucket = aws_s3_bucket.important_stuff_bucket.bucket
  key    = "extremely_important_stuff.txt"
  content  =  data.local_file.important_file.content
}