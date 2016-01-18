ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("../../config/environment", __FILE__)
require 'capybara/rspec'



OmniAuth.config.test_mode = true
omniauth_hash = {"provider"=>"facebook", "uid"=>"605136095", "info"=>{"email"=>"vinthanedar@gmail.com", "first_name"=>"Vineet", "last_name"=>"Thanedar", "image"=>"http://graph.facebook.com/605136095/picture?type=large", "name"=>"Vineet Thanedar"}, "credentials"=>{"token"=>"CACQSJ3guse0BALIfpkn9OvzDw9vFJPXQyQP3ZAqC90vbWDrqZBfHs025hXIZC4CAAeMFuQ4qVaYx0XLWUZCiSqILUjkQzLxfKRhaG7fB8n5hRBSORqPx6PmUGqfBuTUo7qBRcZC1kb9MR9UgFXBZCe7tKNNvztpoEYYYocvI52teKlCvWc37zj55LZB2MCwJzdtUpVzidSXigZDZD", "expires_at"=>1457929490, "expires"=>true}, "extra"=>{"raw_info"=>{"id"=>"605136095", "birthday"=>"09/09/1980", "education"=>[{"school"=>{"id"=>"115177175164238", "name"=>"St. Francis De Sales High School, Aurangabad"}, "type"=>"High School", "year"=>{"id"=>"116962635018500", "name"=>"1996"}}, {"school"=>{"id"=>"113368758673858", "name"=>"University of Pune"}, "type"=>"College", "year"=>{"id"=>"194878617211512", "name"=>"2002"}}, {"school"=>{"id"=>"107888572565045", "name"=>"University of California, Santa Barbara"}, "type"=>"Graduate School"}], "email"=>"vinthanedar@gmail.com", "first_name"=>"Vineet", "last_name"=>"Thanedar", "gender"=>"male", "work"=>[{"end_date"=>"2013-01-01", "employer"=>{"id"=>"8062627951", "name"=>"TechCrunch"}, "location"=>{"id"=>"114952118516947", "name"=>"San Francisco, California"}, "position"=>{"id"=>"125320577510930", "name"=>"Dev Lead"}, "start_date"=>"2010-01-01"}, {"end_date"=>"2010-01-01", "employer"=>{"id"=>"108472637291", "name"=>"Qualcomm"}, "position"=>{"id"=>"142300459126053", "name"=>"Senior Engineer"}, "start_date"=>"2004-01-01"}]}}}
OmniAuth.config.add_mock(:facebook, omniauth_hash)

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

# The settings below are suggested to provide a good initial experience
# with RSpec, but feel free to customize to your heart's content.
=begin
  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  config.disable_monkey_patching!

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed
=end
end
