# frozen_string_literal: true

require 'bundler'
Bundler.setup(:default, :test)
Bundler.require
require 'pry'

require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
end
