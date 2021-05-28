class AssemblyInstructions

  require_rel './pdf/assembly_instructions_pdf_generator.rb'
  include AssemblyInstructionsPdfGenerator

  def initialize(topic)
    raise ArgumentError, 'must pass a topic (string) when initializing' unless topic.is_a?(String) && !topic.empty?
    # save the topic
    @topic = topic.split().map(&:capitalize).join(' ')
  end

  def generate
    return self
  end

end