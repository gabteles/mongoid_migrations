# require 'mongoid_migrations/tasks'
# will give you the resque tasks

namespace :db do
  unless Rake::Task.task_defined?("db:drop")
    desc 'Drops all the collections for the database for the current env'
    task :drop do
      Mongoid.master.collections.each {|col| col.drop_indexes && col.drop unless ['system.indexes', 'system.users'].include?(col.name) }
    end
  end

  unless Rake::Task.task_defined?("db:seed")
    # if another ORM has defined db:seed, don't run it twice.
    desc 'Load the seed data from db/seeds.rb'
    task :seed do
      seed_file = File.join('db', 'seeds.rb')
      load(seed_file) if File.exist?(seed_file)
    end
  end

  unless Rake::Task.task_defined?("db:setup")
    desc 'Create the database, and initialize with the seed data'
    task :setup => [ 'db:create', 'db:seed' ]
  end

  unless Rake::Task.task_defined?("db:reseed")
    desc 'Delete data and seed'
    task :reseed => [ 'db:drop', 'db:seed' ]
  end

  unless Rake::Task.task_defined?("db:create")
    task :create do
      # noop
    end
  end

  desc 'Current database version'
  task :version do
    puts Mongoid::Migrator.current_version.to_s
  end

  desc "Migrate the database through scripts in db/migrate. Target specific version with VERSION=x. Turn off output with VERBOSE=false."
  task :migrate do
    Mongoid::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    Mongoid::Migrator.migrate(Mongoid::Migrator.migrations_path, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
  end

  namespace :migrate do
    desc  'Rollback the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x. Target specific version with VERSION=x.'
    task :redo do
      if ENV["VERSION"]
        Rake::Task["db:migrate:down"].invoke
        Rake::Task["db:migrate:up"].invoke
      else
        Rake::Task["db:rollback"].invoke
        Rake::Task["db:migrate"].invoke
      end
    end

    desc 'Resets your database using your migrations for the current environment'
    # should db:create be changed to db:setup? It makes more sense wanting to seed
    task :reset => ["db:drop", "db:create", "db:migrate"]

    desc 'Runs the "up" for a given migration VERSION.'
    task :up do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      Mongoid::Migrator.run(:up, Mongoid::Migrator.migrations_path, version)
    end

    desc 'Runs the "down" for a given migration VERSION.'
    task :down do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      Mongoid::Migrator.run(:down, Mongoid::Migrator.migrations_path, version)
    end

    desc 'Create a migration file for given migration NAME'
    task :create do
      migration_name = ENV["NAME"] || 'migration'
      Mongoid::Migrator.generate(migration_name)
    end
  end

  desc 'Rolls the database back to the previous migration. Specify the number of steps with STEP=n'
  task :rollback do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    Mongoid::Migrator.rollback(Mongoid::Migrator.migrations_path, step)
  end

  namespace :schema do
    task :load do
      # noop
    end
  end

  namespace :test do
    task :prepare do
      # Stub out for MongoDB
    end
  end
end