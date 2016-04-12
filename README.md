# AmiSpec

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

System-wide: gem install ami-spec

With bundler:

Add `gem 'ami-spec'` to your Gemfile.
Run `bundle install`

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
and try to SSH to it (`--ssh-user` and `--key-file`).
When the instances becomes reachable it will run all Specs inside the role spec directory (`--role` i.e. `my_project/spec/web_server`).

Alternative to the `--ami` and `--role` variables, a file of comma separated roles and AMIs (`ROLE,AMI\n`) can be supplied to `--role-ami-file`.

## Known caveats

[ServerSpecs advanced tips](http://serverspec.org/advanced_tips.html) provides a mechanism to conditionally apply tests based on server information.

```ruby
describe file('/usr/lib64'), :if => os[:arch] == 'x86_64' do
  it { should be_directory }
end
```

If these are used in shared examples, say loaded via a rspec helper, this doesn't work with AmiSpec, because the evaluation of `os[:arch] == 'x86_64'` is done when the spec is loaded not at run time.

To get around this, we can make the conditional a procedure:

```ruby
describe file('/usr/lib64'), :if => proc { os[:arch] == 'x86_64' } do
  it { should be_directory }
end
```

Rspec will `call` the procedure at run time, avoiding an Exception being thrown at load time as no ssh options are defined.

## Development Status

Active and ready for Production

## Contributing

For bug fixes, documentation changes, and small features:
1. Fork it ( https://github.com/envato/ami-spec/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Maintainers

Patrick Robinson (@nemski)

## License

AmiSpec uses the MIT license. See [LICENSE.txt](./LICENSE.txt)
