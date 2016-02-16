require 'spec_helper'

describe Decanter::Core do

  let(:dummy) { Class.new { include Decanter::Core } }

  before(:each) do
    Decanter::Core.class_variable_set(:@@handlers, {})
    Decanter::Core.class_variable_set(:@@strict_mode, {})
  end

  after(:each) do
    Decanter::Core.class_variable_set(:@@handlers, {})
    Decanter::Core.class_variable_set(:@@strict_mode, {})
  end

  describe '#input' do

    let(:name) { :profile }
    let(:parser) { :string }
    let(:options) { {} }

    before(:each) { dummy.input name, parser, options }

    it 'adds a handler for the provided name' do
      expect(dummy.handlers.has_key? name ).to be true
    end

    context 'for multiple values' do

      let(:name) { [:first_name, :last_name] }

      it 'adds a handler for the provided name' do
        expect(dummy.handlers.has_key? name ).to be true
      end

      it 'raises an error if multiple values are passed without a parser' do
        expect { dummy.input name }.to raise_error(ArgumentError)
      end
    end

    it 'the handler has type :input' do
      expect(dummy.handlers[name][:type]).to eq :input
    end

    it 'the handler has default key equal to the name' do
      expect(dummy.handlers[name][:key]).to eq name
    end

    it 'the handler has name = provided name' do
      expect(dummy.handlers[name][:name]).to eq name
    end

    it 'the handler passes through the options' do
      expect(dummy.handlers[name][:options]).to eq options
    end

    it 'the handler has parser of provided parser' do
      expect(dummy.handlers[name][:parser]).to eq parser
    end

    context 'with key specified in options' do
      let(:options) { { key: :foo } }

      it 'the handler has key from options' do
        expect(dummy.handlers[name][:key]).to eq options[:key]
      end
    end
  end

  describe '#has_one' do

    let(:name) { :profile }
    let(:options) { {} }

    before(:each) { dummy.has_one name, options }

    it 'adds a handler for the provided name' do
      expect(dummy.handlers.has_key? name ).to be true
    end

    it 'the handler has type :has_one' do
      expect(dummy.handlers[name][:type]).to eq :has_one
    end

    it 'the handler has default key :#{name}_attributes' do
      expect(dummy.handlers[name][:key]).to eq "#{name}_attributes".to_sym
    end

    it 'the handler has name = provided name' do
      expect(dummy.handlers[name][:name]).to eq name
    end

    it 'the handler passes through the options' do
      expect(dummy.handlers[name][:options]).to eq options
    end

    context 'with key specified in options' do
      let(:options) { { key: :foo } }

      it 'the handler has key from options' do
        expect(dummy.handlers[name][:key]).to eq options[:key]
      end
    end
  end

  describe '#has_many' do

    let(:name) { :profile }
    let(:options) { {} }

    before(:each) { dummy.has_many name, options }

    it 'adds a handler for the provided name' do
      expect(dummy.handlers.has_key? name ).to be true
    end

    it 'the handler has type :has_many' do
      expect(dummy.handlers[name][:type]).to eq :has_many
    end

    it 'the handler has default key :#{name}_attributes' do
      expect(dummy.handlers[name][:key]).to eq "#{name}_attributes".to_sym
    end

    it 'the handler has name = provided name' do
      expect(dummy.handlers[name][:name]).to eq name
    end

    it 'the handler passes through the options' do
      expect(dummy.handlers[name][:options]).to eq options
    end

    context 'with key specified in options' do
      let(:options) { { key: :foo } }

      it 'the handler has key from options' do
        expect(dummy.handlers[name][:key]).to eq options[:key]
      end
    end
  end


  describe '#strict' do

    let(:mode) { true }

    it 'sets the strict mode' do
      dummy.strict mode
      expect(dummy.strict_mode).to eq mode
    end

    context 'for an unknown mode' do

      let(:mode) { :foo }

      it 'raises an error' do
        expect { dummy.strict mode }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#parse' do

    let(:parser) { double("parser", parse: nil) }

    before(:each) do
      allow(Decanter::ValueParser)
        .to receive(:value_parser_for)
        .and_return(parser)
    end

    context 'when a parser is not specified' do

      it 'returns an array with the key and value' do
        expect(dummy.parse(:first_name, nil, 'bar', {})).to eq [:first_name, 'bar']
      end

      it 'does not sall ValueParser.value_parser_for' do
        dummy.parse(:first_name, nil, 'bar', {})
        expect(Decanter::ValueParser).to_not have_received(:value_parser_for)
      end
    end

    context 'when a parser is specified' do

      it 'calls ValueParser.value_parser_for with the parser' do
        dummy.parse(:first_name, :foo, 'bar', {})
        expect(Decanter::ValueParser).to have_received(:value_parser_for).with(:foo)
      end

      it 'calls parse on the returned parser with the key, values and options' do
        options = {}
        dummy.parse(:first_name, :foo, 'bar', options)
        expect(parser).to have_received(:parse).with(:first_name, 'bar', options)
      end

    end
  end

  describe '#decanter_for_handler' do

    let(:handler) { { name: :foo, options: {} } }

    before(:each) do
      allow(Decanter).to receive(:decanter_for)
    end

    it 'calls Decanter::decanter_for with the default name' do
      dummy.decanter_for_handler(handler)
      expect(Decanter).to have_received(:decanter_for).with(handler[:name])
    end

    context 'with the decanter specified in options' do

      let(:handler) { { name: :foo, options: { decanter: :bar } } }

      it 'calls Decanter::decanter_for with the specified name' do
        dummy.decanter_for_handler(handler)
        expect(Decanter).to have_received(:decanter_for).with(handler[:options][:decanter])
      end
    end
  end

  describe '#unhandled_keys' do

    let(:args) { { foo: :bar } }

    context 'when there are no unhandled keys' do

      before(:each) { allow(dummy).to receive(:handlers).and_return({ foo: nil }) }

      it 'returns an empty hash' do
        expect(dummy.unhandled_keys(args)).to match({})
      end
    end

    context 'when there are unhandled keys' do

      before(:each) { allow(dummy).to receive(:handlers).and_return({}) }

      context 'and strict mode is true' do

        before(:each) { dummy.strict true }

        it 'spits out a warning' do
          # Not sure how to test this
        end
      end

      context 'and strict mode is :with_exception' do

        before(:each) { dummy.strict :with_exception }

        it 'raises an error' do
          expect { dummy.unhandled_keys(args) }.to raise_error(ArgumentError)
        end
      end

      context 'and strict mode is not specified' do
        it 'returns a hash with the unhandled keys and values' do
          expect(dummy.unhandled_keys(args)).to match(args)
        end
      end
    end
  end

  describe '#handled_keys' do

    let(:args)     { { baz: 'fob', far: 'baf' } }
    let(:handlers) { { foo: 'foo', bar: 'bar' } }

    before(:each) do
      allow(dummy).to receive(:handlers).and_return(handlers)
      allow(dummy).to receive(:handle)
        .and_return([:baz, 'fob'],[:far, 'baf'])
    end

    it 'calls handle for each handler with the handler and args' do
      dummy.handled_keys(args)
      handlers.values.each do |handler|
        expect(dummy)
          .to have_received(:handle)
          .with(handler, args)
      end
    end

    it 'returns a hash with the results of handling each handler' do
      expect(dummy.handled_keys(args)).to eq args
    end
  end

  describe '#handle' do

    let(:args)    { { foo: 'hi', bar: 'bye' } }
    let(:name)    { [:foo, :bar] }
    let(:values)  { args.values_at(*name) }
    let(:handler) { { type: :input, name: name } }

    before(:each) { allow(dummy).to receive(:handle_input).and_return(:foobar) }

    context 'for an input' do
      it 'calls the handle_input with the handler and extracted values' do
        dummy.handle(handler, args)
        expect(dummy)
          .to have_received(:handle_input)
          .with(handler, values)
      end

      it 'returns the results form handle_input' do
        expect(dummy.handle(handler, args)).to eq :foobar
      end
    end
  end

  describe '#handle_input' do

    let(:key)     { double('key') }
    let(:parser)  { double('parser') }
    let(:options) { double('options') }
    let(:values)  { double('values') }
    let(:output)  { double('output') }
    let(:handler) { { key: key, parser: parser, options: options } }

    before(:each) do
      allow(dummy).to receive(:parse).and_return(output)
    end

    it 'calls parse with the handler key, handler parser, values and options' do
      dummy.handle_input(handler, values)
      expect(dummy)
        .to have_received(:parse)
        .with(key, parser, values, options)
    end

    it 'returns the response' do
      expect(dummy.handle_input(handler, values)).to eq output
    end
  end

  describe '#handle_has_one' do

    let(:output)   { { foo: 'bar' } }
    let(:handler)  { { key: 'key', options: {} } }
    let(:values)   { { baz: 'foo' } }
    let(:decanter) { double('decanter') }

    before(:each) do

      allow(decanter)
        .to receive(:decant)
        .and_return(output)

      allow(dummy)
        .to receive(:decanter_for_handler)
        .and_return(decanter)
    end

    it 'calls decanter_for_handler with the handler' do
      dummy.handle_has_one(handler, values)
      expect(dummy)
        .to have_received(:decanter_for_handler)
        .with(handler)
    end

    it 'calls decant with the values on the found decanter' do
      dummy.handle_has_one(handler, values)
      expect(decanter)
        .to have_received(:decant)
        .with(values)
    end

    it 'returns an array containing the key, and the decanted value' do
      expect(dummy.handle_has_one(handler, values))
        .to match ([handler[:key], output])
    end
  end

  describe '#handle_has_many' do

    let(:output)   { [{ foo: 'bar' },{ bar: 'foo' }] }
    let(:handler)  { { key: 'key', options: {} } }
    let(:values)   { [{ baz: 'foo' }, { faz: 'boo' }] }
    let(:decanter) { double('decanter') }

    before(:each) do

      allow(decanter)
        .to receive(:decant)
        .and_return(*output)

      allow(dummy)
        .to receive(:decanter_for_handler)
        .and_return(decanter)
    end

    it 'calls decanter_for_handler with the handler' do
      dummy.handle_has_many(handler, values)
      expect(dummy)
        .to have_received(:decanter_for_handler)
        .with(handler)
    end

    it 'calls decant with the each of the values on the found decanter' do
      dummy.handle_has_many(handler, values)
      expect(decanter)
        .to have_received(:decant)
        .with(values[0])
      expect(decanter)
        .to have_received(:decant)
        .with(values[1])
    end

    it 'returns an array containing the key, and an array of decanted values' do
      expect(dummy.handle_has_many(handler, values))
        .to match ([handler[:key], output])
    end
  end

  describe '#decant' do

    let(:args) { { foo: 'bar', baz: 'foo'} }

    before(:each) do
      allow(dummy).to receive(:unhandled_keys).and_return(args)
      allow(dummy).to receive(:handled_keys).and_return(args)
    end

    it 'passes the args to unhandled keys' do
      dummy.decant(args)
      expect(dummy).to have_received(:unhandled_keys).with(args)
    end

    it 'passes the args to handled keys' do
      dummy.decant(args)
      expect(dummy).to have_received(:handled_keys).with(args)
    end

    it 'returns the merged result' do
      expect(dummy.decant(args)).to eq args.merge(args)
    end
  end
end
