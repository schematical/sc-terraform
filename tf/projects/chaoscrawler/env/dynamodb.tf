resource "aws_dynamodb_table" "dynamodb_table_user" {
  name           = "${var.env}_ChaosCrawlerUser"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "parentUri"
  range_key      = "_id"
  attribute {
    name = "_id"
    type = "S"
  }
  attribute {
    name = "parentUri"
    type = "S"
  }
  /*  attribute {
      name = "Title"
      type = "S"
    }

    attribute {
      name = "Body"
      type = "S"
    }*/
  /*
    ttl {
      attribute_name = "TimeToExist"
      enabled        = false
    }*/

  /* global_secondary_index {
     name               = "GameTitleIndex"
     hash_key           = "GameTitle"
     range_key          = "TopScore"
     write_capacity     = 10
     read_capacity      = 10
     projection_type    = "INCLUDE"
     non_key_attributes = ["UserId"]
   }*/

  tags = {
    Name        = "schematical-com"
  }
}
resource "aws_dynamodb_table" "dynamodb_table_signupcode" {
  name           = "${var.env}_ChaosCrawlerSignupCode"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "parentUri"
  range_key      = "_id"
  attribute {
    name = "_id"
    type = "S"
  }
  attribute {
    name = "parentUri"
    type = "S"
  }

  /*  attribute {
      name = "Title"
      type = "S"
    }

    attribute {
      name = "Body"
      type = "S"
    }*/

  /*
    ttl {
      attribute_name = "TimeToExist"
      enabled        = false
    }*/

  /* global_secondary_index {
     name               = "GameTitleIndex"
     hash_key           = "GameTitle"
     range_key          = "TopScore"
     write_capacity     = 10
     read_capacity      = 10
     projection_type    = "INCLUDE"
     non_key_attributes = ["UserId"]
   }*/

  tags = {
    Name        = "schematical-com"
  }
}
resource "aws_dynamodb_table" "dynamodb_table_digeststream" {
  name           = "${var.env}_ChaosCrawlerDigestStream"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "parentUri"
  range_key      = "_id"
  attribute {
    name = "_id"
    type = "S"
  }
  attribute {
    name = "parentUri"
    type = "S"
  }
  /*

    attribute {
      name = "Body"
      type = "S"
    }*/

  /*
    ttl {
      attribute_name = "TimeToExist"
      enabled        = false
    }*/

  /* global_secondary_index {
     name               = "GameTitleIndex"
     hash_key           = "GameTitle"
     range_key          = "TopScore"
     write_capacity     = 10
     read_capacity      = 10
     projection_type    = "INCLUDE"
     non_key_attributes = ["UserId"]
   }*/

  tags = {
    Name        = "schematical-com"
  }
}
resource "aws_dynamodb_table" "dynamodb_table_digeststreamitem" {
  name           = "${var.env}_ChaosCrawlerDigestStreamItem"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "parentUri"
  range_key      = "_id"
  attribute {
    name = "_id"
    type = "S"
  }
  attribute {
    name = "parentUri"
    type = "S"
  }


  ttl {
    attribute_name = "ttl"
    enabled        = false
  }



  tags = {
    Name        = "schematical-com"
  }
}