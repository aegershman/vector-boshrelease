terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "aegershman"

    workspaces {
      name = "vector_boshrelease"
    }
  }
}

provider "aws" {
  version = "~> 3.8"
  region  = "us-east-2"
}

####################################
# blobstore bucket
####################################

resource "aws_s3_bucket" "vector_boshrelease" {
  bucket = "vector-boshrelease"
  acl    = "private"
}

data "aws_iam_policy_document" "vector_boshrelease_blobstore_public_read" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.vector_boshrelease.arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "vector_boshrelease" {
  bucket = "${aws_s3_bucket.vector_boshrelease.id}"
  policy = "${data.aws_iam_policy_document.vector_boshrelease_blobstore_public_read.json}"
}

####################################
# service account for writing to the blobstore
####################################

resource "aws_iam_user" "vector_boshrelease" {
  name = "vector_boshrelease"
}

data "aws_iam_policy_document" "vector_boshrelease_blobstore_write" {
  statement {
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.vector_boshrelease.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "vector_boshrelease_blobstore_write" {
  name   = "vector_boshrelease_blobstore_write"
  policy = "${data.aws_iam_policy_document.vector_boshrelease_blobstore_write.json}"
}

resource "aws_iam_user_policy_attachment" "vector_boshrelease" {
  user       = "${aws_iam_user.vector_boshrelease.name}"
  policy_arn = "${aws_iam_policy.vector_boshrelease_blobstore_write.arn}"
}

####################################
# access key for our service account
####################################

resource "aws_iam_access_key" "vector_boshrelease" {
  user    = "${aws_iam_user.vector_boshrelease.name}"
  pgp_key = "keybase:aegershman"
}

output "vector_boshrelease_access_key_id" {
  value = "${aws_iam_access_key.vector_boshrelease.id}"
}

output "vector_boshrelease_secret_access_key" {
  value = "${aws_iam_access_key.vector_boshrelease.encrypted_secret}"
}
