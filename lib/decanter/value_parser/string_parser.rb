module Decanter
  module ValueParser
    class StringParser < Base
      def self.parse(val, options={})
        val && val.respond_to?(:to_s) ? val.to_s : nil
      end
    end
  end
end
