# AmiSpec

[![License MIT](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://github.com/envato/ami-spec/blob/master/LICENSE.txt)
[![Gem Version](https://badge.fury.io/rb/ami_spec.svg)](https://badge.fury.io/rb/ami_spec)
[![Build Status](https://github.com/envato/ami-spec/workflows/tests/badge.svg?branch=master)](https://github.com/envato/ami-spec/actions?query=branch%3Amaster+workflow%3Atests)

Acceptance testing your AMIs.

AmiSpec is a RubyGem used to launch an Amazon Machine Image (AMI) and run ServerSpecs against it. It wraps around the AWS API and ServerSpec to spin up, test and tear down instances.

## Project Goals

1. To decouple the building of AMIs from testing them. Other approaches to this problem involve copying ServerSpec tests to an EC2 instance before it's converted to an AMI and running the tests there.
The problem with this approach is:

- It does not test the instance in the state it will be in when it's actually in production.
- It does makes it harder to replace the AMI builder software (i.e. [Packer](https://github.com/mitchellh/packer)).
- The software required to test the AMI must exist in the AMI.

2. To run tests as fast as possible; this approach is slightly slower than the alternative listed above (about 1-2 minutes), but should not be onerous.

## Installation

System-wide: gem install ami\_spec

With bundler:

Add `gem 'ami_spec'` to your Gemfile.
Run `bundle install`

## CLI Usage

```cli
$ bundle exec ami_spec --help
Options:
  -r, --role=<s>                            The role to test, this should map to a directory in the spec
                                            folder
  -a, --ami=<s>                             The ami ID to run tests against
  -o, --role-ami-file=<s>                   A file containing comma separated roles and amis. i.e.
                                            web_server,ami-id.
  -s, --specs=<s>                           The directory to find ServerSpecs
  -u, --subnet-id=<s>                       The subnet to start the instance in. If not provided a subnet
                                            will be chosen from the default VPC
  -k, --key-name=<s>                        The SSH key name to assign to instances. If not provided a
                                            temporary key pair will be generated in AWS
  -e, --key-file=<s>                        The SSH private key file associated to the key_name
  -h, --ssh-user=<s>                        The user to ssh to the instance as
  -w, --aws-region=<s>                      The AWS region, defaults to AWS_DEFAULT_REGION environment
                                            variable
  -i, --aws-instance-type=<s>               The ec2 instance type, defaults to t2.micro (default:
                                            t2.micro)
  -c, --aws-security-groups=<s>             Security groups IDs to associate to the launched instances. May be
                                            specified multiple times. If not provided a temporary security
                                            group will be generated in AWS
  -n, --allow-any-temporary-security-group  The temporary security group will allow SSH connections 
                                            from any IP address (0.0.0.0/0), otherwise allow the subnet's block
  -p, --aws-public-ip                       Launch instances with a public IP and use that IP for SSH
  -q, --associate-public-ip                 Launch instances with a public IP and use the Private IP for SSH
  -t, --ssh-retries=<i>                     The number of times we should try sshing to the ec2 instance
                                            before giving up. Defaults to 30 (default: 30)
  -g, --tags=<s>                            Additional tags to add to launched instances in the form of
                                            comma separated key=value pairs. i.e. Name=AmiSpec (default: )
  -d, --debug                               Don't terminate instances on exit
  -b, --buildkite                           Output section separators for buildkite
  -f, --wait-for-rc                         Wait for oldschool SystemV scripts to run before conducting
                                            tests. Currently only supports Ubuntu with upstart
  -l, --user-data-file=<s>                  File path for aws ec2 user data
  -m, --iam-instance-profile-arn=<s>        IAM instance profile to use
  --help                                    Show this message

```

AmiSpec will launch an EC2 instance from the given AMI (`--ami`), in a subnet (`--subnet-id`) with a key-pair (`--key-name`)
and try to SSH to it (`--ssh-user` and `--key-file`).
When the instances becomes reachable it will run all Specs inside the role spec directory (`--role` i.e. `my_project/spec/web_server`).

Alternative to the `--ami` and `--role` variables, a file of comma separated roles and AMIs (`ROLE,AMI\n`) can be supplied to `--role-ami-file`.

## ServerSpec test layout

AmiSpec expects the usual ServerSpec configuration layout as generated by "serverspec-init":

    spec/
    ├── webserver
    │   └── webserver_spec.rb
    └── spec_helper.rb

The \*\_spec.rb files under the role (e.g. webserver) contain the ServerSpec
tests that you want to run. The spec_helper.rb file can be very simple:

    require 'serverspec'

    set :backend, :ssh

Note that the backend *needs* to be :ssh or ami_spec might run the tests on
your local machine, not in EC2.

## Example usage

To test a custom AMI using a pre-created security group that allows SSH from anywhere:

```cli
ami_spec --role webserver\
 --specs spec\
 --aws-region us-east-1\
 --ami ami-0123456789abcdef0\
 --key-name default\
 --key-file ~/.ssh/default.pem\
 --ssh-user ubuntu\
 --aws-public-ip\
 --aws-security-groups sg-0123456789abcdef0
```

## Known caveats

### RSpec conditions in examples

[ServerSpecs advanced tips](http://serverspec.org/advanced_tips.html) provides a mechanism to conditionally apply tests based on server information.

```ruby
describe file('/usr/lib64'), :if => os[:arch] == 'x86_64' do
  it { should be_directory }
end
```

If these are used in shared examples, say loaded via a rspec helper, this doesn't work with AmiSpec, because the evaluation of `os[:arch] == 'x86_64'` is done when the spec is loaded not at run time.

Working around this is tricky. We need to move the evaluation of `os[:arch]` to runtime not load time. Since RSpec example metadata can only be a bool, string or symbol we set a metadata key of `:os_arch` to the value we expect:

```ruby
describe file('/usr/lib64'), :os_arch => 'x86_64' do
  it { should be_directory }
end
```

We then have to set an RSpec exclusion of examples where the architecture does not match the host under test's architecture. This can be done in the `spec_helper` with a lambda function that tests this:

```ruby
RSpec.configure do |c|
  c.filter_run_excluding :os_arch => lambda { |arch| arch if os[:arch] != arch }
end
```

We are exluding any example with the metadata key :os_arch where the value does not match our architecture. Similar examples can be included for os family etc.

## Development Status

Active and ready for Production

## Contributing

For bug fixes, documentation changes, and small features:
1. Fork it ( https://github.com/envato/ami-spec/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Running tests

Use the following command to run non-integration tests:
```
bundle exec rake spec
```

If you're working on the `WaitForRC` feature you can run it's integration tests by first bringing up the containers, then executing the integration tests:
```
docker-compose -f spec/containers/docker-compose.yml up -d
bundle exec rspec . --tag integration
docker-compose -f spec/containers/docker-compose.yml down
```

## Maintainers

Patrick Robinson (@patrobinson)

## License

AmiSpec uses the MIT license. See [LICENSE.txt](./LICENSE.txt)
