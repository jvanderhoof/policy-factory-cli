module Compiler
  module Utilities
    # Operations related to Hash manipulation
    class HashUtil
      def underscore_keys(hsh)
        {}.tap do |rtn_hsh|
          hsh.each do |key, value|
            rtn_hsh[key.to_s.underscore.to_sym] = if value.is_a?(Hash)
                                             underscore_keys(value)
                                           else
                                             value
                                           end
          end
        end
      end
    end
  end
end
