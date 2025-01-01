resource "aws_s3_bucket" "demo_s3" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.demo_s3.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "publiceaccess" {
  bucket                  = aws_s3_bucket.demo_s3.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.ownership,
    aws_s3_bucket_public_access_block.publiceaccess,
  ]

  bucket = aws_s3_bucket.demo_s3.id
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "public" {
  bucket = aws_s3_bucket.demo_s3.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["http://localhost:3000", "http://localhost:3001", "https://${aws_cloudfront_distribution.cdn_test.domain_name}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.demo_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.demo_s3.arn}/*"
      },
      {
        Sid    = "AllowCloudFrontServicePrincipalRead"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.demo_s3.arn}/*"
      }
    ]
  })
}

resource "aws_cloudfront_response_headers_policy" "cors_with_preflight" {
  name = "Custom-CORS-With-Preflight"

  cors_config {
    access_control_allow_origins {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS"]
    }

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_expose_headers {
      items = ["ETag", "x-amz-meta-custom-header"]
    }

    access_control_max_age_sec       = 86400 # Thời gian cho phép cache preflight request
    origin_override                  = true  # Ghi đè header CORS từ origin
    access_control_allow_credentials = false
  }

  security_headers_config {
    content_security_policy {
      content_security_policy = "default-src 'self';"
      override                = true
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    xss_protection {
      protection = true
      mode_block = true
      override   = true
    }
  }
}

resource "aws_cloudfront_distribution" "cdn_test" {
  origin {
    domain_name              = aws_s3_bucket.demo_s3.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.demo_s3.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.cdn_oac.id
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Photos, CSS, JS, HTML resources"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.demo_s3.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    response_headers_policy_id = aws_cloudfront_response_headers_policy.cors_with_preflight.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP", "VN"]
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


# Origin Access Control
resource "aws_cloudfront_origin_access_control" "cdn_oac" {
  name                              = "test-cdn-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

