# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "test/dummy/config/application"

Rails.application.load_tasks

desc "Build all gems"
task :build do
  # Remove any existing gem files
  puts "Removing existing gem files..."
  FileUtils.rm_f(Dir.glob("*.gem"))

  # Build each gemspec
  Dir.glob("*.gemspec").each do |gemspec|
    puts "Building #{gemspec}..."
    system "gem build #{gemspec}"
  end
end

desc "Inspect gem contents by unpacking them to tmp/inspect"
task :unpack do
  require 'fileutils'

  # Create and clean the inspect directory
  inspect_dir = "tmp/inspect"
  FileUtils.rm_rf(inspect_dir) if Dir.exist?(inspect_dir)
  FileUtils.mkdir_p(inspect_dir)

  # Find and unpack all gem files
  Dir.glob("*.gem").each do |gem_file|
    puts "Unpacking #{gem_file}..."
    system "gem unpack #{gem_file} --target=#{inspect_dir}"
  end

  puts "\nGems unpacked to #{inspect_dir}"
end
