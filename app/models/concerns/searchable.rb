require 'active_support/concern'

# For this concern to work, generate a migration for the model adding
# a datetime 'deleted_at' attribute with nil as default
module Searchable
  extend ActiveSupport::Concern

  class_methods do

    # search for keywords in certain fields
    def search(keywords, *fields)
      # not search anything if there are no keywords or fields to search for
      return all unless keywords.present?
      raise ArgumentError, "No fields to search were given" unless fields.any?

      query = Array.new

      keywords = Utils.format_search_keywords(keywords)
      operator = keywords.at(Utils::REGEXP_SPLITTER) ? :REGEXP : :LIKE

      fields.each do |field|
        query << "#{field} #{operator} :keywords"
      end

      query = query.join(' OR ')
      where(query, keywords: keywords)
    end

  end
end
