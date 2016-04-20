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
set :log_level, :info
set :pty, false

set :assets_roles, [:app]
set :keep_assets, 3

set :migration_role, :migrator
set :migration_servers, -> { primary(fetch(:migration_role)) }
set :conditionally_migrate, true

set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle')
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml', 'config/puma.rb', '.rbenv-vars')

set :bundle_without, %w{development test}.join(' ')
set :rbenv_map_bins, %w{rake gem bundle ruby rails sidekiq sidekiqctl}

set :puma_user, fetch(:user)
# set :puma_rackup, -> { File.join(current_path, 'config.ru') }
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"    #accept array for multi-bind
set :puma_default_control_app, "unix://#{shared_path}/tmp/sockets/pumactl.sock"
set :puma_conf, "#{shared_path}/config/puma.rb"
set :puma_access_log, "#{shared_path}/log/puma_access.log"
set :puma_error_log, "#{shared_path}/log/puma_error.log"
set :puma_role, :app
set :puma_env, fetch(:rack_env, fetch(:rails_env, 'production'))
set :puma_threads, [2, 8]
set :puma_workers, 2
# set :puma_worker_timeout, nil
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
set :puma_preload_app, false
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
        execute "cd #{current_path} && echo '#!/bin/bash' > ~/export_vars.sh && #{fetch(:rbenv_path)}/bin/rbenv vars >> ~/export_vars.sh && chmod u+x ~/export_vars.sh && source ~/export_vars.sh && \
                (nohup node #{current_path}/node_scripts/firebase_master.js > #{shared_path}/log/firebase_master.log 2>&1 &) && sleep 2", pty: true
      end
    end

    task :stop do
      on roles(:firebase) do
        execute "kill -s SIGTERM `cat #{shared_path}/tmp/pids/firebase_master.pid`"
      end
    end

    task :restart do
      on roles(:firebase) do
        invoke 'firebase:master:stop'
        sleep 2
        invoke 'firebase:master:start'
      end
    end
  end

  namespace :worker do
    task :start do
      on roles(:firebase) do
        execute "cd #{current_path} && echo '#!/bin/bash' > ~/export_vars.sh && #{fetch(:rbenv_path)}/bin/rbenv vars >> ~/export_vars.sh && chmod u+x ~/export_vars.sh && source ~/export_vars.sh && \
                (nohup node #{current_path}/node_scripts/firebase_worker.js > #{shared_path}/log/firebase_worker.log 2>&1 &) && sleep 2", pty: true
      end
    end

    task :stop do
      on roles(:firebase) do
        execute "kill -s SIGTERM `cat #{shared_path}/tmp/pids/firebase_worker.pid`"
      end
    end

    task :restart do
      on roles(:firebase) do
        invoke 'firebase:worker:stop'
        sleep 2
        invoke 'firebase:worker:start'
      end
    end
  end
end

namespace :deploy do
  after :publishing, :restart_firebase_master do
    invoke 'firebase:master:restart'
  end

  after :publishing, :restart_firebase_worker do
    invoke 'firebase:worker:restart'
  end
end
