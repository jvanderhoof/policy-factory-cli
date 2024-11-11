# frozen_string_literal: true

require 'spec_helper'
require './lib/compiler/utilities/hash_util'

describe(Compiler::Utilities::HashUtil) do
  let(:hash) { {} }
  subject { described_class.new.underscore_keys(hash) }

  context 'when hash includes dashed keys' do
    let(:hash) { { 'foo-bar' => 'baz', 'foo_bing' => 'bar', 'foo-baz' => 'baz' } }
    it 'converts dashed keys to underscores' do
      expect(subject).to eq(
        {
          foo_bar: 'baz',
          foo_bing: 'bar',
          foo_baz: 'baz'
        }
      )
    end
    context 'when keys are deeply nested' do
      let(:hash) { { 'foo-bar' => { 'bar-baz' => { 'bing-bang' => 'bang' } } } }
      it 'convers keys to underscore' do
        expect(subject).to eq(
          { foo_bar: { bar_baz: { bing_bang: 'bang' } } }
        )
      end
    end
  end
  context 'when the keys are symbols' do
    let(:hash) { { foo: 'bar', 'bar' => 'foo', baz: 'bing'} }
    it 'converts symbols to strings' do
      expect(subject).to eq(
        {
          foo: 'bar',
          bar: 'foo',
          baz: 'bing'
        }
      )
    end
  end
end
