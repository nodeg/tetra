# Contributing

## Development environment

To develop tetra, you will need:

* to install Bundler and Ruby development headers.
* to get development dependencies: `bundle install`.

To install a development version of tetra use:

```bash
sudo rake install
```

## Tests

To run tests, simply run `rake` or `bundle exec rake` which runs the full set of tests.

> [!NOTE]
> Tests are divided into fine (more similar to unit tests) and coarse (more similar to integration tests).

```bash
# only run fine tests
bundle exec rspec spec/lib/fine/*

# only run coarse tests
bundle exec rspec spec/lib/coarse/*

# run all coarse tests with and show example names
bundle exec rspec spec/lib/coarse/* --format documentation

# only run selected tests
bundle exec rspec spec/lib/coarse/version_spec.rb
```

## Coding style

We use RuboCop to enforce a certain coding style for Ruby. With every Pull request and push, RuboCop checks the coding
style and reports any errors. You can do this locally by simple executing `rubocop` if you have RuboCop installed. For
the exact RuboCop version used, take a look at `tetra.gemspec`.

## New features

In case you want to add new features, please be aware to also add the necessary fine grained or coarse grained tests
for it.

## Maintainers

### Release

This is an example for the version number 2.0.9.

1. Install release helper gem `gem install gem-release`
1. Bump the version in `lib/tetra/version.rb`
1. Regenerate `Gemfile.lock` with `bundle install`
1. Build the gem with `gem build tetra.gemspec`
1. Run the local tests with `rake`
1. Add both files and commit them
1. Tag new version: `git tag -am "tag v2.0.9" v2.0.9`
1. Push to master: `git push upstream` and `git push --tags upstream`
1. (Optional: Take a look at the GitHub Action tests)
1. Release the gem on [rubygems.org](https://rubygems.org): `gem release --pretend` and `gem release`
