module LocalOpen

  # a method to add a singleton method to an instance
  # that allows a PDF to be opened locally (ie on a dev machine)
  def add_local_open_method
    define_singleton_method(
      :open,
      Proc.new do
        render_file(path_and_pdf_filename)
        self.open
        self.rewind
        system "open #{self.path}"
      end
    )
  end

end