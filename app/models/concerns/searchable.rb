require 'active_support/concern'

module Searchable
  extend ActiveSupport::Concern

  class_methods do

    # search for key_words in certain fields
    # available options, key_words = String, fields = Array and joins = Hash
    def search(options={})
      # not search anything if there are no key_words or fields to search for
      return all unless options[:key_words].present?
      raise ArgumentError, "No fields to search were given" unless options[:fields].present?
      raise ArgumentError, "fields option must be an Array" unless options[:fields].kind_of? Array
      raise ArgumentError, "joins options must be a Hash" if options[:joins].present? and !options[:joins].kind_of? Hash

      query = Array.new

      options[:key_words] = Utils.format_search_key_words(options[:key_words])
      operator = options[:key_words].at(Utils::REGEXP_SPLITTER) ? :REGEXP : :LIKE

      options[:fields].each do |field|
        query << "#{field} #{operator} :key_words"
      end

      query = query.join(' OR ')

      if options[:joins].present?
        joins(options[:joins]).where(query, key_words: options[:key_words])
      else
        where(query, key_words: options[:key_words])
      end
    end

  end
end
