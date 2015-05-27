# Monkey in the middleing Minitest::Spec::DSL#it,
# and aliases to record the block in the user's code,
# this way the backtrace lines up with the logical definition site,
# and we don't risk filtering the entire backtrace
# which causes RSpec to not filter,
# and the entire backtrace is quite distracting
require 'minitest/spec'
dsl = Minitest::Spec::DSL
it_location = dsl.instance_method(:it).source_location
dsl.instance_methods
   .map    { |name| [name, dsl.instance_method(name)] }
   .select { |name, method| method.source_location == it_location }
   .each   { |name, method|
     dsl.__send__ :define_method, name do |*args, &block|
       callsite = caller[0] || 'unknown-location:0:' # can't think of a situation where this wouldn't be true, but just in case
       callsite =~ /^(.*?):(\d+):/
       caller_filename, caller_lineno = $1, $2.to_i
       block ||= eval 'proc { skip "(no tests defined)" }', binding, caller_filename, caller_lineno
       method.bind(self).call(*args, &block)
     end
   }
