module Pdf

  def pdf
    @pdf ||= generate_pdf
  end

  def generate_pdf(prawn_document = Prawn::Document.new)
    raise ArgumentError, 'must pass a Prawn::Document' unless prawn_document.is_a?(Prawn::Document)
    pdf_file_name = "#{self.class.name.gsub(/(.)([A-Z])/,'\1_\2').downcase}.pdf"
    path_and_pdf_filename = "../tmp/#{pdf_file_name}"
    build_pdf(prawn_document).tap do |p|
      _open = Proc.new do
        render_file(path_and_pdf_filename)
        system "open #{path_and_pdf_filename}"
      end
      p.define_singleton_method(:open, _open)
    end
  end

  def build_pdf(prawn_document)
    raise ArgumentError, 'must pass a Prawn::Document' unless prawn_document.is_a?(Prawn::Document)
    prawn_document.tap do |p|
      # anything you want at the start of all components, add here!
    end
  end

end