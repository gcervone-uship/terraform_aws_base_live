# terraform_aws_base_live

- common
- examples
- account
    - region
        - environment

Each environment should have it's own state file.
Link to the the global.tf file for some common code.

## Setup

* Setup the common/credentials file.
```
[terraform_prototype]
aws_access_key_id = CHANGE_ME
aws_secret_access_key = CHANGE_ME
[terraform_shared]
aws_access_key_id = CHANGE_ME
aws_secret_access_key = CHANGE_ME
[terraform_sandbox]
aws_access_key_id = CHANGE_ME
aws_secret_access_key = CHANGE_ME
```

*


Backend config should be the same across all deploys.  The only part that should change is the key.
        