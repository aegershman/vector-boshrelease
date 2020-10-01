terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "aegershman"

    workspaces {
      name = "vector-boshrelease"
    }
  }
}

provider "aws" {
  version = "~> 2.50"
  region  = "us-east-2"
}

####################################
# blobstore bucket
####################################

resource "aws_s3_bucket" "vector" {
  bucket = "vector-boshrelease"
  acl    = "private"

  tags = {
    name = "vector-boshrelease"
  }
}

data "aws_iam_policy_document" "vector_bucket_public_read" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.vector.arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "vector" {
  bucket = "${aws_s3_bucket.vector.id}"
  policy = "${data.aws_iam_policy_document.vector_bucket_public_read.json}"
}

####################################
# service account for writing to the blobstore
####################################

resource "aws_iam_user" "vector" {
  name = "vector"

  tags = {
    name = "vector-boshrelease"
  }
}

data "aws_iam_policy_document" "vector_blobstore_write" {
  statement {
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.vector.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "vector_blobstore_write" {
  name        = "vector-blobstore-write"
  description = "vector-boshrelease blobstore bucket write permission"
  policy      = "${data.aws_iam_policy_document.vector_blobstore_write.json}"
}

resource "aws_iam_user_policy_attachment" "vector" {
  user       = "${aws_iam_user.vector.name}"
  policy_arn = "${aws_iam_policy.vector_blobstore_write.arn}"
}

####################################
# access key for that service account
####################################

resource "aws_iam_access_key" "vector" {
  user    = "${aws_iam_user.vector.name}"
  pgp_key = "keybase:aegershman"
}

output "vector_access_key_id" {
  value = "${aws_iam_access_key.vector.id}"
}

output "vector_secret_access_key" {
  value = "${aws_iam_access_key.vector.encrypted_secret}"
}
