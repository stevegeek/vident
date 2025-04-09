# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "test/dummy/config/application"

Rails.application.load_tasks

desc "Run tests"
task :test do
  sh "bin/test"
end

task default: :test

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

desc "Push all built gems to RubyGems"
task :release do
  # Get list of gem files
  gem_files = Dir.glob("*.gem")

  if gem_files.empty?
    puts "No gem files found. Run 'rake build' first."
    exit 1
  end

  # Ask for confirmation
  puts "The following gems will be pushed to RubyGems:"
  gem_files.each { |gem| puts "  - #{gem}" }

  print "\nAre you sure you want to continue? [y/N] "
  confirmation = $stdin.gets.chomp.downcase

  if confirmation == 'y'
    # Push each gem
    gem_files.each do |gem_file|
      puts "\nPushing #{gem_file}..."
      system "gem push #{gem_file}"

      # Check if push was successful
      if $?.success?
        puts "Successfully pushed #{gem_file}"
      else
        puts "Failed to push #{gem_file}"
      end
    end
  else
    puts "Aborted."
  end
end
