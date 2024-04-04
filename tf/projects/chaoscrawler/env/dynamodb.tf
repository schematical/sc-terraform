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
/*  attribute {
    name = "ttl"
    type = "N"
  }*/
  attribute {
    name = "digestStreamEpisode"
    type = "S"
  }
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
  global_secondary_index {
    name               = "digestStreamEpisode"
    hash_key           = "digestStreamEpisode"
    # range_key          = "TopScore"
    # write_capacity     = 1
    # read_capacity      = 1
    projection_type    = "ALL"
    # non_key_attributes = ["digestStreamEpisode"]
  }


  tags = {
    Name        = "schematical-com"
  }
}
resource "aws_dynamodb_table" "dynamodb_table_digeststreamepisode" {
  name           = "${var.env}_ChaosCrawlerDigestStreamEpisode"
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
  ttl {
    attribute_name = "ttl"
    enabled        = false
  }
*/



  tags = {
    Name        = "schematical-com"
  }
}
resource "aws_dynamodb_table" "dynamodb_table_diagram" {
  name           = "${var.env}_ChaosCrawlerDiagram"
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


  tags = {
    Name        = "schematical-com"
  }
}
resource "aws_dynamodb_table" "dynamodb_table_diagramobject" {
  name           = "${var.env}_ChaosCrawlerDiagramObject"
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


  tags = {
    Name        = "schematical-com"
  }
}
resource "aws_dynamodb_table" "dynamodb_table_diagramflow" {
  name           = "${var.env}_ChaosCrawlerDiagramFlow"
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


  tags = {
    Name        = "schematical-com"
  }
}
resource "aws_dynamodb_table" "dynamodb_table_site" {
  name           = "${var.env}_ChaosCrawlerSplitGPTSite"
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

}
resource "aws_dynamodb_table" "dynamodb_table_site_element" {
  name           = "${var.env}_ChaosCrawlerSplitGPTSiteElement"
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

}