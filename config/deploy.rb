# frozen_string_literal: true

lock '3.17.1'

set :repo_url, ENV.fetch('REPO', 'mastodon@conchrepublic.social:repos/mastodon')
set :branch, ENV.fetch('BRANCH', 'master')

set :application, 'mastodon'
set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip
set :migration_role, :app

append :linked_files, '.env.production', 'public/robots.txt'
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "vendor/bundle", "storage"

namespace :systemd do
  %i[sidekiq streaming web].each do |service|
    %i[reload restart status].each do |action|
      desc "Perform a #{action} on #{service} service"
      task "#{service}:#{action}".to_sym do
        on roles(:app) do
          # runs e.g. "sudo restart mastodon-sidekiq.service"
          sudo :systemctl, action, "#{fetch(:application)}-#{service}.service"
        end
      end
    end
  end
end

after 'deploy:publishing', 'systemd:web:reload'
after 'deploy:publishing', 'systemd:sidekiq:restart'
after 'deploy:publishing', 'systemd:streaming:restart'
