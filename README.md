# RspecProfiling

[![Test](https://github.com/procore-oss/rspec_profiling/actions/workflows/test.yaml/badge.svg?branch=main)](https://github.com/procore-oss/rspec_profiling/actions/workflows/test.yaml)
[![Gem Version](https://badge.fury.io/rb/rspec_profiling.svg)](https://badge.fury.io/rb/rspec_profiling)
[![Discord](https://img.shields.io/badge/Chat-EDEDED?logo=discord)](https://discord.gg/PbntEMmWws) 


Collects profiles of RSpec test suites, enabling you to identify specs
with interesting attributes. For example, find the slowest specs, or the
spec which issues the most queries.

Collected attributes include:

- git commit SHA (or SVN revision) and date
- example file, line number and description
- example status (i.e. passed or failed)
- example exception (i.e. nil if passed, reason for failure otherwise)
- example time
- query count and time
- request count and time

## Compatibility

RspecProfiling should work with Rails >= 3.2 and RSpec >= 2.14.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rspec_profiling'
```

And then execute:

```bash
bundle
```

Require the gem to your `spec_helper.rb`.

```ruby
require "rspec_profiling/rspec"
```

Lastly, run the installation rake tasks to initialize an empty database in
which results will be collected.

```bash
bundle exec rake rspec_profiling:install
```

If you are planning on using `sqlite` or `pg` ensure to add the dependency to your gemfile

```ruby
  gem 'sqlite', require: false
  gem 'pg', require: false
```

## Usage

### Choose a version control system

Results are collected based on the version control system employed e.g. revision or commit SHA for `svn` and `git` respectively.

#### Git

By default, RspecProfiling expects Git as the version control system.

#### Subversion

RspecProfiling can be configured to use `svn` in `config/initializers/rspec_profiling.rb`:

```Ruby
RspecProfiling.configure do |config|
  config.vcs = RspecProfiling::VCS::Svn
end
```

#### Git / Subversion

For those with a mixed project, with some developers using `git svn` and others regular `svn`, use this configuration to detect which is being used locally and behave accordingly.

```Ruby
RspecProfiling.configure do |config|
  config.vcs = RspecProfiling::VCS::GitSvn
end
```

#### Custom Ownership Tracking

If the repo you are running the profiler on has many teams working on it, you can use the `magic_comment` option to specify a comment at the top of files to scan for ownership tracking.  In the example below,
the profiler will look for `#team: <owner>` comments at the top of each file and add <owner> to the results.
The default is `team` but can be configured to any comment you want.

```Ruby
RspecProfiling.configure do |config|
  config.magic_comment = 'team'
end
```

#### Custom Event Subscriptions

```Ruby
RspecProfiling.configure do |config|
  config.events = %w[event1 event2]
end
```

Note that custom events are only currently reported by the CSV collector.

#### Custom Event Recording

It is possible to record the event metadata for a spec.

```Ruby
  describe 'Records all active record queries', record_events: %w[sql.active_record] do
    it 'Records Rails deprecations', record_events: %w[deprecation.rails] do
      ...
    end
    it 'Records nothing' do
      ...
    end
  end
```

### Choose a results collector

Results are collected just by running the specs.

#### SQLite3

Make sure you've run the installation rake task before attempting.

You can configure `RspecProfiling` to collect results in a SQL database in `config/initializers/rspec_profiling.rb`:

```Ruby
RspecProfiling.configure do |config|
  config.collector = RspecProfiling::Collectors::SQL
end
```

You can review results by running the RspecProfiling console.
The console has a preloaded `results` variable.

```bash
bundle exec rake rspec_profiling:console

> results.count
=> 1970
```

You can find the spec that runs the most queries:

```ruby
> results.order(:query_count).last.to_s
=> "Updating my account - ./spec/features/account_spec.rb:15"
```

Or find the spec that takes the most time:

```ruby
> results.order(:time).last.to_s
=> "Updating my account - ./spec/features/account_spec.rb:15"
```

There are additional attributes available on the `Result` instances to enable
debugging, such as `exception` and `status`.

#### CSV

By default, profiles are collected in an a CSV file. You can configure `RspecProfiling` to collect results in a CSV in `config/initializers/rspec_profiling.rb`:

```Ruby
RspecProfiling.configure do |config|
  config.collector = RspecProfiling::Collectors::CSV
end
```

By default, the CSV is output to `cat tmp/spec_benchmarks.csv`.
Rerunning spec will overwrite the file. You can customize the CSV path
to, for example, include the sample time.

```Ruby
RspecProfiling.configure do |config|
  config.collector = RspecProfiling::Collectors::CSV
  config.csv_path = ->{ "tmp/spec_benchmark_#{Time.now.to_i}" }
end
```

#### Postgresql

You can configure `RspecProfiling` to collect results in a Postgres database
in your `spec_helper.rb` file.

```Ruby
RspecProfiling.configure do |config|
  config.collector = RspecProfiling::Collectors::PSQL
  config.db_path   = 'profiling'
end
```

## Configuration Options

Configuration is performed like this:

```Ruby
RspecProfiling.configure do |config|
  config.<option> = <something>
end
```

### Options

- `db_path` - the location of the SQLite database file
- `table_name` - the database table name in which results are stored
- `csv_path` - the directory in which CSV files are dumped
- `collector` - collector to use
- `magic_comment` - comment to scan top of files to enable ownership tracking (EX: `#team: tooling`)

### Usage in a script

If you want to access the results from a Ruby script instead of the `rake rspec_profiling:console` shell command:

```ruby
require 'rspec_profiling'
require 'rspec_profiling/console'
```

Then `results` will be available as a variable to the script.

## Uninstalling

To remove the results database, run `bundle exec rake rspec_profiling:uninstall`.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Local Development

Local tools needed:

- docker
- docker-compose
- ruby

To run the specs:

```bash
make spec
```
