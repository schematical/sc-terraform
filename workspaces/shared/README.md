
```
terraform apply -var='users=["testman"]'
```

```
terraform apply -var='users=["sjobs","bgates","emusk","gwashington","nmandella","jfk","lbj","mlk","ctop","rnixon","bfarve","arogers","pgerhartz", "3rdpartapp1", "3rdpartapp2", "3rdpartapp3"]'
```

terraform import aws_codestarconnections_connection.codestarconnections_connection arn:aws:codestar-connections:us-east-1:368590945923:connection/67d17ca5-a542-49db-9256-157204b67b1d