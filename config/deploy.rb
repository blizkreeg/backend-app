# config valid only for current version of Capistrano
lock '3.4.1'

set :user, 'deploy'
set :application, 'backend-app'
set :repo_url, 'git@github.com:blizkreeg/backend-app.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

set :deploy_to, "/home/#{fetch(:user)}/#{fetch(:application)}"
set :rails_env, 'production'
set :rbenv_path, '/home/deploy/.rbenv'
set :rbenv_type, :user
set :rbenv_ruby, '2.3.0'
set :scm, :git
set :format, :pretty
set :log_level, :debug
set :pty, false

set :assets_roles, [:app]
set :keep_assets, 2

# set :migration_role, :db
# set :migration_servers, -> { primary(fetch(:migration_role)) }

set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle')
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml', '.rbenv-vars')

set :bundle_without, %w{development test}.join(' ')
set :rbenv_map_bins, %w{rake gem bundle ruby rails sidekiq sidekiqctl}

set :puma_user, fetch(:user)
# set :puma_rackup, -> { File.join(current_path, 'config.ru') }
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"    #accept array for multi-bind
# set :puma_default_control_app, "unix://#{shared_path}/tmp/sockets/pumactl.sock"
set :puma_conf, "#{shared_path}/puma.rb"
set :puma_access_log, "#{shared_path}/log/puma_access.log"
set :puma_error_log, "#{shared_path}/log/puma_error.log"
set :puma_role, :app
set :puma_env, fetch(:rack_env, fetch(:rails_env, 'production'))
set :puma_threads, [1, 16]
set :puma_workers, 0
# set :puma_worker_timeout, nil
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
set :puma_preload_app, true
set :puma_init_active_record, true
# set :nginx_use_ssl, false

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

set :sidekiq_config, 'config/sidekiq.yml'
set :sidekiq_role, :sidekiq
set :sidekiq_processes, 1

namespace :firebase do
  namespace :master do
    task :start do
      on roles(:firebase) do
        execute "cd #{current_path} && echo '#!/bin/bash' > ~/export_vars.sh && #{fetch(:rbenv_path)}/bin/rbenv vars >> ~/export_vars.sh && chmod u+x ~/export_vars.sh && cat ~/export_vars.sh && source ~/export_vars.sh && \
                (nohup node #{current_path}/node_scripts/firebase_master.js > #{shared_path}/log/firebase_master.log 2>&1 &) && sleep 2", pty: true
      end
    end

    task :stop do
      on roles(:firebase) do
        execute "kill -s SIGTERM `cat #{shared_path}/tmp/pids/firebase_master.pid`"
      end
    end
  end

  namespace :worker do
    task :start do
      on roles(:firebase) do
        execute "cd #{current_path} && echo '#!/bin/bash' > ~/export_vars.sh && #{fetch(:rbenv_path)}/bin/rbenv vars >> ~/export_vars.sh && chmod u+x ~/export_vars.sh && cat ~/export_vars.sh && source ~/export_vars.sh && \
                (nohup node #{current_path}/node_scripts/firebase_worker.js > #{shared_path}/log/firebase_worker.log 2>&1 &) && sleep 2", pty: true
      end
    end

    task :stop do
      on roles(:firebase) do
        execute "kill -s SIGTERM `cat #{shared_path}/tmp/pids/firebase_worker.pid`"
      end
    end
  end
end

namespace :deploy do


  # after :restart, :clear_cache do
  #   on roles(:app), in: :groups, limit: 3, wait: 10 do
  #     # Here we can do anything such as:
  #     # within release_path do
  #     #   execute :rake, 'cache:clear'
  #     # end
  #   end
  # end

  desc "Make sure local git is in sync with remote."
  # task :check_revision do
  #   on roles(:app) do
  #     unless `git rev-parse HEAD` == `git rev-parse origin/master`
  #       puts "WARNING: HEAD is not the same as origin/master"
  #       puts "Run `git push` to sync changes."
  #       exit
  #     end
  #   end
  # end

  # desc 'Initial Deploy'
  # task :initial do
  #   on roles(:app) do
  #     before 'deploy:restart', 'puma:start'
  #     invoke 'deploy'
  #   end
  # end

  # desc 'Restart application'
  # task :restart do
  #   on roles(:app), in: :sequence, wait: 5 do
  #     invoke 'puma:restart'
  #   end
  # end

  # before :starting,     :check_revision
  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  # after  :finishing,    :restart
end
