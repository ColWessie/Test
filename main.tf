
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

}

provider "aws" {
  region = "eu-north-1"

}


#HOSTING SITE

module "template_files" {
  source   = "hashicorp/dir/template"
  base_dir = "${path.module}/tech-test/tech-test"
}


resource "aws_s3_bucket" "hosting_bucket" {
  bucket = "news-site-hosting-bucket"
}

resource "aws_s3_bucket_ownership_controls" "owner" {
  bucket = aws_s3_bucket.hosting_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket = aws_s3_bucket.hosting_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_acl" "acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.owner,
    aws_s3_bucket_public_access_block.access_block,
  ]

  bucket = aws_s3_bucket.hosting_bucket.id
  acl    = "public-read"
}


resource "aws_s3_bucket_policy" "hosting_bucket_policy" {
  bucket = aws_s3_bucket.hosting_bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::news-site-hosting-bucket/*"
      }
    ]
  })
}
resource "aws_s3_bucket_website_configuration" "hosting_bucket_website_configuration" {
  bucket = aws_s3_bucket.hosting_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}


resource "aws_s3_object" "hosting_bucket_files" {
  bucket = aws_s3_bucket.hosting_bucket.id

  for_each = module.template_files.files

  key          = each.key
  content_type = each.value.content_type

  source  = each.value.source_path
  content = each.value.content

  etag = each.value.digests.md5
}





#CREATING USERS

#Bobby

resource "aws_iam_user" "Bobby" {

  name = "Bobby"

}

resource "aws_iam_access_key" "Bobby_Access" {

  user = aws_iam_user.Bobby.name

}

#Alice

resource "aws_iam_user" "Alice" {

  name = "Alice"

}

resource "aws_iam_access_key" "Alice_Access" {

  user = aws_iam_user.Alice.name

}

#Malory

resource "aws_iam_user" "Malory" {

  name = "Malory"

}

resource "aws_iam_access_key" "Malory_Access" {

  user = aws_iam_user.Malory.name

}

#Charlie

resource "aws_iam_user" "Charlie" {

  name = "Charlie"

}

resource "aws_iam_access_key" "Charlie_Access" {

  user = aws_iam_user.Charlie.name

}






#CREATING POLICIES
resource "aws_iam_policy" "Content_Editor" {
  name = "Content_Editor"


  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : ["s3:ListAllMyBuckets", ],
        "Resource" : ["arn:aws:s3:::*", ]
      },

      {
        "Effect" : "Allow",
        "Action" : ["s3:*"],
        "Resource" : ["arn:aws:s3:::news-site-hosting-bucket*",

        ]
      }

    ]


  })
}



resource "aws_iam_policy" "Marketing" {
  name = "Marketing"


  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListAllMyBuckets",
        "s3:GetBucketLocation"],
        "Resource" : ["arn:aws:s3:::*", ]
      },
      {
        "Action" : ["s3:ListBucket"],
        "Effect" : "Allow",
        "Resource" : ["arn:aws:s3:::news-site-hosting-bucket"],
      },
      {
        "Action" : ["s3:GetObject", "s3:PutObject"],
        "Effect" : "Deny",
        "Resource" : ["arn:aws:s3:::news-site-hosting-bucket/people.html"]
      },
      {
        "Action" : ["s3:GetObject", "s3:PutObject"],
        "Effect" : "Deny",
        "Resource" : ["arn:aws:s3:::news-site-hosting-bucket/index.html"]
      }


    ]
  })


}


resource "aws_iam_policy" "HR" {
  name = "HR"
  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListAllMyBuckets",
        "s3:GetBucketLocation"],
        "Resource" : ["arn:aws:s3:::*", ]
      },
      {
        "Action" : ["s3:ListBucket"],
        "Effect" : "Allow",
        "Resource" : ["arn:aws:s3:::news-site-hosting-bucket"],
      },
      {
        "Action" : ["s3:GetObject", "s3:PutObject"],
        "Effect" : "Deny",
        "Resource" : ["arn:aws:s3:::news-site-hosting-bucket/news/*"]
      },
      {
        "Action" : ["s3:GetObject", "s3:PutObject"],
        "Effect" : "Deny",
        "Resource" : ["arn:aws:s3:::news-site-hosting-bucket/index.html"]
      }


    ]
  })


}

#Applying Policies
resource "aws_iam_user_policy_attachment" "Bobby" {
  user       = aws_iam_user.Bobby.name
  policy_arn = aws_iam_policy.Content_Editor.arn
}
resource "aws_iam_user_policy_attachment" "Alice" {
  user       = aws_iam_user.Alice.name
  policy_arn = aws_iam_policy.Marketing.arn
}
resource "aws_iam_user_policy_attachment" "Malory" {
  user       = aws_iam_user.Malory.name
  policy_arn = aws_iam_policy.Marketing.arn
}

resource "aws_iam_user_policy_attachment" "Charlie" {
  user       = aws_iam_user.Charlie.name
  policy_arn = aws_iam_policy.HR.arn
}