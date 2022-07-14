# aws_send_log_to_s3

Compress and send logs to S3.

## Requirement

You have aws-cli installed on your server.
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## Overview

1. Compress log to zip or tar.gz
2. Send compresed log to AWS S3

## How to Use

1. Customize variable parameters
2. Just run it

```sh
./aws_send_log_to_s3.sh
```

## Customize Variables parameters

| Variable    | Description                     |
|-------------|---------------------------------|
| LOGFILE     | Output destination of error log |
| BUCKET      | S3 bucket name                  |
| BUCKET_URI  | S3 folder name                  |
| TARGET_LOGS | Logs to be uploaded             |
| MODE        | Compress type                   |

## Author

[Dillen H. Tomida](https://twitter.com/t0mihir0)

## License

This software is licensed under the MIT license, see [LICENSE](./LICENSE) for more information.
