# AmiSpec

AmiSpec is a RubyGem used to spin up an Amazon Machine Image (AMI) and run ServerSpecs against it. It wraps around the AWS API and RSpec to spin up and tear down instances.

## Project Goals

To decouple the building of AMIs from testing them. Other approaches to this problem involve copying ServerSpec tests to an EC2 instance before it's converted to an AMI and running the tests there.
The problem with this approach is:

- It does not test the instance in the state it will be in when it's actually used in Production.
- It does makes it harder to replace the AMI builder software (i.e. [Packer](https://github.com/mitchellh/packer)).
- It requires the software required to test the AMI exist in the AMI.

To run tests as fast as possible, this approach is slightly slower than the alternative listed above (about 1-2 minutes), but should not be onerous.

## CLI Usage

```cli
$ bundle exec ami_spec --help
Options:
  -r, --role=<s>                    The role to test, this should map to a directory in the spec folder
  -a, --ami=<s>                     The ami ID to run tests against
  -o, --role-ami-file=<s>           A file containing comma separated roles and amis. i.e.
                                    web_server,ami-id.
  -s, --specs=<s>                   The directory to find ServerSpecs
  -u, --subnet-id=<s>               The subnet to start the instance in
  -k, --key-name=<s>                The SSH key name to assign to instances
  -e, --key-file=<s>                The SSH private key file associated to the key_name
  -h, --ssh-user=<s>                The user to ssh to the instance as
  -w, --aws-region=<s>              The AWS region, defaults to AWS_DEFAULT_REGION environment variable
  -i, --aws-instance-type=<s>       The ec2 instance type, defaults to t2.micro (default: t2.micro)
  -c, --aws-security-groups=<s+>    Security groups to associate to the launched instances. May be specified
                                    multiple times
  -p, --aws-public-ip               Launch instances with a public IP
  -t, --ssh-retries=<i>             The number of times we should try sshing to the ec2 instance before
                                    giving up. Defaults to 30 (default: 30)
  -d, --debug                       Don't terminate instances on exit
  -l, --help                        Show this message
$  bundle exec ami_spec \
--role web_server \
--ami ami-12345678 \
--subnet-id subnet-abcdefgh \
--key-name ec2-key-pair \
--key-file ~/.ssh/ec2-key-pair.pem \
--ssh-user ubuntu \
--specs ./my_project/spec
```

AmiSpec will launch an EC2 instance from the given AMI (`--ami`), in a subnet (`--subnet-id`) with a key-pair (`--key-name`)
and try to SSH to it (`--ssh-user` and `--key-file`) for a given number of retries.
When the instances becomes reachable it will run all Specs inside the `my_project/spec/web_server` directory.
