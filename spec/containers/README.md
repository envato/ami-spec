## Integration test containers

This directory is used to create containers that can be used to test the `WaitForRC` class. Because they require upstart/systemd to exist we have to install and start the init environment. We also setup SSH so that we can simple call the `wait` function and have it SSH to our container to execute.

Refer to the [README](../../README.md#running-tests) for how to execute them.
