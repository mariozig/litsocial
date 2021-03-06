APP_ROOT = File.expand_path(File.dirname(File.dirname(File.dirname(__FILE__))))

if ENV['MY_RUBY_HOME'] && ENV['MY_RUBY_HOME'].include?('rvm')
  begin
    #rvm_path = File.dirname(File.dirname(ENV['MY_RUBY_HOME']))
    #rvm_lib_path = File.join(rvm_path, 'lib')
    #$LOAD_PATH.unshift rvm_lib_path
    require 'rvm'
    RVM.use_from_path! APP_ROOT
  rescue LoadError
    raise "RVM ruby lib is currently unavailable."
  end
end

ENV['BUNDLE_GEMFILE'] = APP_ROOT + '/Gemfile'
require 'bundler/setup'

worker_processes 1
working_directory APP_ROOT

preload_app true

timeout 30

listen "127.0.0.1:3000"

pid APP_ROOT + "/tmp/pids/unicorn.pid"

stderr_path APP_ROOT + "/log/unicorn.stderr.log"
stdout_path APP_ROOT + "/log/unicorn.stdout.log"

before_fork do |server, worker|
  defined?(ActiveRecord::Base) && ActiveRecord::Base.connection.disconnect!

  old_pid = APP_ROOT + '/tmp/pids/unicorn.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      puts "Old master alerady dead"
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) && ActiveRecord::Base.establish_connection
end