package security.storage

deny[msg] {
  input.resource.type == "google_storage_bucket"
  input.change.after.uniform_bucket_level_access == false
  msg = sprintf("Bucket %s must enable uniform bucket-level access", [input.resource.name])
}

# METADATA
# title: Cloud Storage buckets must enforce uniform access
# description: Prevents use of legacy ACLs that bypass central IAM.

### Tests ###

test_bucket_without_uniform_access_fails {
  deny with input as {
    "resource": {
      "type": "google_storage_bucket",
      "name": "logs-bucket"
    },
    "change": {
      "after": {
        "uniform_bucket_level_access": false
      }
    }
  }
}

test_bucket_with_uniform_access_succeeds {
  not deny with input as {
    "resource": {
      "type": "google_storage_bucket",
      "name": "secure-bucket"
    },
    "change": {
      "after": {
        "uniform_bucket_level_access": true
      }
    }
  }
}