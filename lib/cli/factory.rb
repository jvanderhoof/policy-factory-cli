# frozen_string_literal: true

module CLI
  # Struct to hold factory details
  Factory = Struct.new(:name, :category, :version, :type, :title, :description, :factory, keyword_init: true) do
    def variable_path
      "#{category}/#{version}/#{name}"
    end
  end
end
