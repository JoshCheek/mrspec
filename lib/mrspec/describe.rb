module MRspec
  module Describe

    # They keep changing the bytecode name, eg:
    # ruby 2.1.1
    # 0006 opt_send_simple  <callinfo!mid:expect, argc:1, FCALL|ARGS_SKIP>

    # chruby 2.2.2
    # 0006 opt_send_without_block <callinfo!mid:expect, argc:1, FCALL|ARGS_SIMPLE>

    # chruby 1.9.3
    # 0005 send             :expect, 1, nil, 8, <ic:0>

    # matches a call to a method that probably comes from minitest, in the disassembled bytecode
    MINITEST_REGEX = /
    ^     # beginning of a line
    \d+   # line number
    \s*   # whitespace
    send  # bytecode for message send
    \s*   #
    :
    (?:
      # Minitest::Assertions#methods
      _synchronize    | assert_in_delta       | assert_kind_of   | assert_output
      assert          | assert_in_epsilon     | assert_match     | assert_predicate
      assert_empty    | assert_includes       | assert_nil       | assert_raises
      assert_equal    | assert_instance_of    | assert_operator  | assert_respond_to
      assert_same     | capture_io            | flunk            | pass
      assert_send     | capture_subprocess_io | message          | refute
      assert_silent   | diff                  | mu_pp            | refute_empty
      assert_throws   | exception_details     | mu_pp_for_diff   | refute_equal
      refute_in_delta | refute_kind_of        | refute_predicate | refute_in_epsilon
      refute_match    | refute_respond_to     | refute_includes  | refute_nil
      refute_same     | refute_instance_of    | refute_operator  | skip

      # Minitest::Test::LifecycleHooks#methods
      after_setup | after_teardown | before_teardown | setup | teardown

      # Minitest::Spec::DSL::InstanceMethods#methods
      before_setup | expect | value
    )
    ,
    /x

    def self.guess_which(&block)
      iseq = RubyVM::InstructionSequence.disasm(block)
      if iseq =~ MINITEST_REGEX
        :minitest
      else
        :rspec
      end
    end
  end
end
