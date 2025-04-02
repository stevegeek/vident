require "rake/testtask"

# We don't use bundler/gem_tasks directly since we have multiple gems
# Instead, we define our own build and install tasks

desc "Run tests for all gems"
task :test do
  # Find all test directories
  test_dirs = Dir.glob("test/*").select { |d| File.directory?(d) }

  test_dirs.each do |dir|
    puts "Running tests for #{File.basename(dir)}..."
    Rake::TestTask.new("test:#{File.basename(dir)}") do |t|
      t.libs << "test"
      t.libs << "lib"
      t.test_files = FileList["#{dir}/**/*_test.rb"]
    end
    Rake::Task["test:#{File.basename(dir)}"].invoke
  end
end

desc "Build all gems"
task :build do
  gemspecs = Dir.glob("*.gemspec")
  gemspecs.each do |gemspec|
    gem_name = File.basename(gemspec, ".gemspec")
    puts "Building #{gem_name}..."
    system("gem build #{gemspec}") || fail("Build failed for #{gem_name}")
  end
end

desc "Install all gems locally"
task install: :build do
  gem_files = Dir.glob("*.gem")
  gem_files.each do |gem_file|
    puts "Installing #{gem_file}..."
    system("gem install #{gem_file}") || fail("Installation failed for #{gem_file}")
  end
end

# Define the default task
task default: :test
