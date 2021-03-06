require 'fast_spec_helper'
require 'interpol'

describe Interpol do
  describe ".default_configuration" do
    it 'returns Configuration.default' do
      expect(Interpol.default_configuration).to be(Interpol::Configuration.default)
    end

    it 'yields the configuration instance if a block is given' do
      yielded1 = nil
      Interpol.default_configuration { |c| yielded1 = c }
      expect(yielded1).to be(Interpol.default_configuration)

      yielded2 = nil
      Interpol.default_configuration { |c| yielded2 = c }
      expect(yielded2).to be(Interpol.default_configuration)
    end
  end
end

