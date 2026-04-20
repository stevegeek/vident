# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "test/dummy/config/application"

Rails.application.load_tasks

task default: :test

require "rake/testtask"

# In-process unit-test runner for SimpleCov. `rake test` spawns `rails test` as
# a subprocess (see Rails::TestUnit::Runner.run_from_rake), so coverage started
# in the parent never sees the lib files and the child's report gets overwritten.
# This task loads test_helper once in this process — SimpleCov there captures
# everything.
task :_enable_coverage do
  ENV["COVERAGE"] ||= "1"
end
Rake::TestTask.new(:_coverage_run) do |t|
  t.libs << "test"
  t.test_files = FileList["test/vident/**/*_test.rb", "test/components/**/*_test.rb", "test/public_api_spec/**/*_test.rb", "test/vident2/**/*_test.rb"]
  t.warning = false
end
desc "Run unit tests in-process with SimpleCov enabled"
task coverage: [:_enable_coverage, :_coverage_run]

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
  require "fileutils"

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

GEM_COOP_HOST = ENV.fetch("GEM_COOP_HOST", "https://beta.gem.coop/@stephen")

def push_gem(gem_file, host: nil, api_key: nil)
  cmd = "gem push #{gem_file}"
  cmd += " --host #{host}" if host
  otp = ENV["OTP"] || ENV["GEM_HOST_OTP_CODE"]
  cmd += " --otp #{otp}" if otp && !otp.empty?

  env = {}
  env["GEM_HOST_API_KEY"] = api_key if api_key

  puts "\nPushing #{gem_file}#{host ? " to #{host}" : " to RubyGems"}..."
  system(env, cmd)
  if $?.success?
    puts "Successfully pushed #{gem_file}"
    true
  else
    puts "Failed to push #{gem_file}"
    false
  end
end

def require_env!(*names)
  missing = names.reject { |n| ENV[n] && !ENV[n].empty? }
  return if missing.empty?
  raise "Required env var#{"s" if missing.size > 1} not set: #{missing.join(", ")}"
end

desc "Push all built gems to RubyGems and gem.coop"
task :release do
  require_env!("GEM_COOP_API_KEY", "OTP")

  gem_files = Dir.glob("*.gem")
  if gem_files.empty?
    puts "No gem files found. Run 'rake build' first."
    exit 1
  end

  coop_key = ENV["GEM_COOP_API_KEY"]

  puts "The following gems will be pushed to: RubyGems, #{GEM_COOP_HOST}"
  gem_files.each { |gem| puts "  - #{gem}" }

  print "\nAre you sure you want to continue? [y/N] "
  confirmation = $stdin.gets.chomp.downcase

  unless confirmation == "y"
    puts "Aborted."
    exit 0
  end

  gem_files.each { |gem_file| push_gem(gem_file) }
  gem_files.each { |gem_file| push_gem(gem_file, host: GEM_COOP_HOST, api_key: coop_key) }
end

desc "Push all built gems to gem.coop only"
task :"release:coop" do
  require_env!("GEM_COOP_API_KEY")

  gem_files = Dir.glob("*.gem")
  if gem_files.empty?
    puts "No gem files found. Run 'rake build' first."
    exit 1
  end

  coop_key = ENV["GEM_COOP_API_KEY"]
  gem_files.each { |gem_file| push_gem(gem_file, host: GEM_COOP_HOST, api_key: coop_key) }
end
