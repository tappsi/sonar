# Contributing

We welcome everyone to contribute to Tappsi core and help us tackle
existing issues!  To do so, there are a few things you need to know
about the code. The first thing you will need to do is read all the
current [documentation][1].

You can run all tests in the root directory with `mix test`.

In case you are changing a single file, you can compile and run tests
only for that particular file for fast development cycles. For
example, if you are changing the Driver module, you can compile it and
run its tests as:

```sh
mix test tests/drivers/driver_test.exs
```

After your changes are done, please remember to run the full suite with
`mix test`.

From time to time, your tests may fail in an existing project checkout
and may require a clean start by running `mix do clean, compile`.

With tests running and passing, you are ready to contribute to Tappsi
core services and [send a pull
request](https://help.github.com/articles/using-pull-requests/).

We usually keep a list of enhancements and bugs [in the issue
tracker][2].  For proposing new features, please start a discussion in
the [GitHub issues][2]. Keep in mind that it is your
responsibility to argue and explain why a feature is useful and how it
will impact the codebase and the community. Finally, remember all
interactions in our official spaces follow our [Code of Conduct][3].

## Reviewing changes

Once a pull request is sent, the Tappsi development team will review
your changes.  We outline our process below to clarify the roles of
everyone involved.

All pull requests must be approved by at least one committer before
being merged into the repository. In case any changes are necessary,
the team will leave appropriate comments requesting changes to the
code.

The Tappsi development team may optionally assign someone to review a
pull request.  In case someone is assigned, they must explicitly
approve the code before another team member can merge it.

When review is completed, your pull request will be squashed and
merged into the repository.

## Development links

  * [Documentation][1]
  * [Issues tracker][2]
  * [Code of Conduct][3]
  * [Tappsi development team (backend)][4]

  [1]: https://github.com/tappsi/sonar/wiki
  [2]: https://github.com/tappsi/sonar/issues
  [3]: CODE_OF_CONDUCT.md
  [4]: https://chat.easytaxi.net.br/easytaxi/channels/coitdevbackend