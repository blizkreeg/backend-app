set :stage, :production
set :rails_env, 'production'
set :rack_env, 'production'
set :puma_env, 'production'

# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

server '128.199.234.90', user: 'deploy', roles: %w{app sidekiq}, primary: true
server '128.199.164.71', user: 'deploy', roles: %w{app firebase}#, other_property: :other_value
server '128.199.234.90', user: 'deploy', roles: %w{migrator}



# role-based syntax
# ==================

# Defines a role with one or multiple servers. The primary server in each
# group is considered to be the first unless any  hosts have the primary
# property set. Specify the username and a domain or IP for the server.
# Don't use `:all`, it's a meta role.

role :app, %w{deploy@128.199.234.90 deploy@128.199.164.71}#, my_property: :my_value
role :sidekiq, %w(deploy@128.199.234.90)
role :master, %w(deploy@128.199.234.90)
role :firebase, %w(deploy@128.199.164.71)
role :migrator,  %w{deploy@128.199.234.90}

namespace :deploy do
  desc "Update crontab with whenever"
  task :update_cron do
    on roles(:master) do
      within current_path do
        execute :bundle, :exec, "whenever --update-crontab #{fetch(:application)}"
      end
    end
  end

  after :finishing, 'deploy:update_cron'
end

# Configuration
# =============
# You can set any configuration variable like in config/deploy.rb
# These variables are then only loaded and set in this stage.
# For available Capistrano configuration variables see the documentation page.
# http://capistranorb.com/documentation/getting-started/configuration/
# Feel free to add new variables to customise your setup.



# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult the Net::SSH documentation.
# http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#
# The server-based syntax can be used to override options:
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
