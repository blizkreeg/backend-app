require 'rubygems' # not necessary with ruby 1.9 but included for completeness
require 'twilio-ruby'

# put your own credentials here
account_sid = 'AC21917a58e30e14acd89a6e69df6eb406'
auth_token = '7d536102b6d6f7c417e4e75e0a84f3c3'

# set up a client to talk to the Twilio REST API
@client = Twilio::REST::Client.new account_sid, auth_token

# alternatively, you can preconfigure the client like so
Twilio.configure do |config|
  config.account_sid = account_sid
  config.auth_token = auth_token
end

# and then you can create a new client without parameters
@client = Twilio::REST::Client.new

city = ""
numbers = %w(
)

puts "numbers: #{numbers.count}"
puts "uniq numbers: #{numbers.uniq.count}"

(puts "ERROR: city missing!" and exit 1) if city.empty?

from = 'Vineet'

numbers.uniq.each_with_index do |num, idx|
  puts "sending to #{num}"
  response = @client.messages.create(
    from: '+14154297272',
    to: "+91#{num}",
    body: "Hi! This is #{from} from ekCoffee. We are now live in #{city}! Download the ekCoffee app & get started -> http://goo.gl/JPLpqS"
  )
end
