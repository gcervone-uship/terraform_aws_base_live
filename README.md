# terraform_aws_base_live

This repo represents what's deployed in AWS and utilizes common generic modules in the "terraform_aws_base" repo.

Directory layout:
    /common                                     - Contains AWS credentials and common code in global.tf
    /<account_name>/<region>/<environment>      - Contains sym link to global.tf and any .tf files needed.

The "environment" directory is 1:1 with a terraform deployment and state file.  This is the CWD for
issuing all terraform commands for that specific environment.


## Dependencies

* ml-aws/shared/us-east-1/shared must be created first since all other accounts depend on it.
* Git credentials for the module source gets will have to be setup.
* Backend config should be the same across all deploys.  The only part that should change is the key.

## Setup

1.  Setup the common/credentials file
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

2.  Create a symbolic link to the global.tf file in /common.  There is no need to change anything here.

3.  Create an <environment_name>.tf.  You can use /examples/environment_config_template.tf as a starting point.
Ensure you change any line with the "# CHANGEME" comment and review the rest of the config for changes relative
to your needs.

## Execution

0. Ensure all prerequisites are met.
1. Run 'terraform init' to initialize the directory.  This can be run multiple times with out issue.
2. Run 'terraform get -update' to get the latest modules.  This can be run multiple times out issue.
3. Run 'terraform plan'
4. Run 'terraform apply'
