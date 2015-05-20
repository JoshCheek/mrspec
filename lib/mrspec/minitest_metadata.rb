# Allow Minitest to support RSpec's metadata (eg tagging)
# Thus you can tag a test or a class, and then pass `-t mytag` to mrspec,
# and it will only run the tagged code.
class << Minitest::Runnable
  # Add metadata to the current class
  def classmeta(metadata)
    class_metadata.merge! metadata
  end

  # Add metadata to the next defined test
  def meta(metadata)
    pending_metadata.merge! metadata
  end

  def class_metadata
    @selfmetadata ||= {}
  end

  def example_metadata
    @metadata ||= Hash.new { |metadata, mname| metadata[mname] = {} }
  end

  private

  def method_added(manme)
    example_metadata[manme.intern].merge! pending_metadata
    pending_metadata.clear
  end

  def pending_metadata
    @pending_metadata ||= {}
  end
end
