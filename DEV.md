### Development setup

    gem install bundler
    bundle install

Transit Ruby uses transito as a submodule to get at the transito
exemplar files. The tests will not run without the exemplar files.
You need to run a couple of git commands to set up the transito
git submodule:

    git submodule init
    git submodule update

### Run rspec examples

    rspec

## Benchmarks

    ./bin/benchmark # reads transito data in json and json-verbose formats
