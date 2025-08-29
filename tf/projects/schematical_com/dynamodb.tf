# TENANT table: PK namespace
resource "aws_dynamodb_table" "tenant" {
  name         = "Tenant"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "namespace"

  attribute {
    name = "namespace"
    type = "S"
  }


}

# INBOX table: PK tenantNamespace, SK namespace
# GSI InboxByAddress: PK address, SK tns_ns (computed "${tenantNamespace}#${namespace}")
resource "aws_dynamodb_table" "tenant_inbox" {
  name         = "TenantInbox"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenantNamespace"
  range_key    = "namespace"

  attribute {
    name = "tenantNamespace"
    type = "S"
  }
  attribute {
    name = "namespace"
    type = "S"
  }
  attribute {
    name = "address"
    type = "S"
  }

  global_secondary_index {
    name            = "InboxByAddress"
    hash_key        = "address"
    projection_type = "ALL"
  }

  # Optional: by type per tenant
  global_secondary_index {
    name            = "InboxByType"
    hash_key        = "tenantNamespace"
    range_key       = "type_ns"    # computed "type#namespace"
    projection_type = "ALL"
  }

  attribute {
    name = "type_ns"
    type = "S"
  }


}

# INBOX_MESSAGE table: PK inboxNamespace, SK id
# LSI for createdAt to support time-window queries
resource "aws_dynamodb_table" "tenant_inbox_message" {
  name         = "TenantInboxMessage"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "inboxNamespace"
  range_key    = "id"

  attribute {
    name = "inboxNamespace"
    type = "S"
  }
  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "createdAt"
    type = "S"
  }

  local_secondary_index {
    name            = "MessagesByCreatedAt"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled = true
  }


}

# TENANT_USER table: PK tenantNamespace, SK userId
resource "aws_dynamodb_table" "tenant_user" {
  name         = "TenantUser"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "tenantNamespace"
  range_key    = "userId"

  attribute {
    name = "tenantNamespace"
    type = "S"
  }
  attribute {
    name = "userId"
    type = "S"
  }

  # Optional cross-tenant lookup by userId
  global_secondary_index {
    name            = "TenantUserByUserId"
    hash_key        = "userId"
    range_key       = "tenantNamespace"
    projection_type = "ALL"
  }

}



