# frozen_string_literal: true

module Tweetkit
  class Search
    attr_accessor :search_term

    def initialize(term)
      @search_term = term + ' '
    end

    def opts
      @opts ||= {}
    end

    def connectors
      @connectors ||= opts[:connectors] = []
    end

    def update_search_term(term)
      @search_term += term
    end

    def setup(&block)
      instance_eval(&block)
    end

    def or_search(term)
    end

    def combined_query
      @combined_query = "#{@search_term.strip} #{combine_connectors}"
    end

    def combine_connectors
      connectors.join(' ')
    end

    def add_connector(term, grouped: true)
      grouped ? connectors.push("(#{term})") : connectors.push(term)
    end

    def build_connector(connector, terms, &block)
      query = ''
      connector =
        connector
        .to_s
        .delete_prefix('and_')
        .delete_prefix('or_')
        .delete_suffix('_one_of')
        .to_sym
      if connector.match?('contains')
        terms.each do |term|
          term = term.to_s.strip
          if term.split.length > 1
            query += "\"#{term}\" "
          else
            query += "#{term} "
          end
        end
        update_search_term(query)
      elsif connector.match?('without')
        terms.each do |term|
          term = term.to_s.strip
          if term.split.length > 1
            query += "-\"#{term}\" "
          else
            query += "-#{term} "
          end
        end
        add_connector(query.rstrip, grouped: false)
      elsif connector.match?('is_not')
        connector = connector.to_s.delete_suffix('_not').to_sym
        terms.each do |term|
          term = term.to_s.strip
          query += "-#{connector}:#{term} "
        end
        add_connector(query.rstrip)
      else
        terms.each do |term|
          term = term.to_s.strip
          query += "#{connector}:#{term} "
        end
        add_connector(query.rstrip, grouped: false)
      end
      block_given? ? yield : self
    end

    def build_one_of_connector(connector, terms, &block)
      query = []
      connector =
        connector
        .to_s
        .delete_prefix('and_')
        .delete_prefix('or_')
        .delete_suffix('_one_of')
        .to_sym
      if connector.match?('contains')
        terms.each do |term|
          term = term.to_s.strip
          query << term
        end
      else
        terms.each do |term|
          term = term.to_s.strip
          query << "#{connector}: #{term}"
        end
      end
      add_connector(query.join(' OR '))
      block_given? ? yield : self
    end

    def method_missing(connector, *terms, &block)
      if connector.match?('one_of')
        build_one_of_connector(connector, terms, &block)
      else
        build_connector(connector, terms, &block)
      end
    end

    def respond_to_missing?(method)
      method.match?('one_of') || super
    end
  end
end
