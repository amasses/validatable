module Validatable
  class Errors
    extend Forwardable
    include Enumerable

    def_delegators :errors, :clear, :each, :each_pair, :empty?, :length, :size

    # Returns true if the specified +attribute+ has errors associated with it.
    #
    #   class Company < ActiveRecord::Base
    #     validates_presence_of :name, :address, :email
    #     validates_length_of :name, :in => 5..30
    #   end
    #
    #   company = Company.create(:address => '123 First St.')
    #   company.errors.invalid?(:name)      # => true
    #   company.errors.invalid?(:address)   # => false
    def invalid?(attribute)
      !@errors[attribute.to_sym].nil?
    end

    # Adds an error to the base object instead of any particular attribute. This is used
    # to report errors that don't tie to any specific attribute, but rather to the object
    # as a whole. These error messages don't get prepended with any field name when iterating
    # with +each_full+, so they should be complete sentences.
    def add_to_base(msg)
      add(:base, msg)
    end

    # Returns errors assigned to the base object through +add_to_base+ according to the normal rules of <tt>on(attribute)</tt>.
    def on_base
      on(:base)
    end    

    # call-seq: on(attribute)
    #
    # * Returns nil, if no errors are associated with the specified +attribute+.
    # * Returns the error message, if one error is associated with the specified +attribute+.
    # * Returns an array of error messages, if more than one error is associated with the specified +attribute+.
    def on(attribute)
      return nil if errors[attribute.to_sym].nil?
      errors[attribute.to_sym].size == 1 ? errors[attribute.to_sym].first : errors[attribute.to_sym]
    end

    # Rails 3 API for errors, always return array.
    def [](attribute)
      errors[attribute.to_sym] || []
    end

    def add(attribute, message) #:nodoc:
      errors[attribute.to_sym] = [] if errors[attribute.to_sym].nil?
      errors[attribute.to_sym] << message
    end

    def merge!(errors) #:nodoc:
      errors.each_pair{|k, v| add(k,v)}
      self
    end

    # call-seq: replace(attribute)
    #
    # * Replaces the errors value for the given +attribute+
    def replace(attribute, value)
      errors[attribute.to_sym] = value
    end

    # call-seq: raw(attribute)
    #
    # * Returns an array of error messages associated with the specified +attribute+.
    def raw(attribute)
      errors[attribute.to_sym]
    end

    def errors #:nodoc:
      @errors ||= {}
    end

    def count #:nodoc:
      errors.values.flatten.size
    end

    # call-seq: full_messages -> an_array_of_messages
    #
    # Returns an array containing the full list of error messages.
    def full_messages
      full_messages = []

      errors.each_key do |attribute|
        errors[attribute].each do |msg|
          next if msg.nil?
          
          # Try for a translation in locale files
          if msg.is_a? Symbol
            if Object.const_defined? "I18n" # Not all places this is used will include I18n support
              msg = I18n.t msg, :scope => [:errors, :messages], :default => humanize(msg.to_s)
            else
              msg = humanize(msg.to_s)
            end
          end

          if attribute.to_s == "base"
            full_messages << msg
          else
            full_messages << humanize(attribute.to_s) + " " + msg
          end
        end
      end
      full_messages
    end

    def humanize(lower_case_and_underscored_word) #:nodoc:
      lower_case_and_underscored_word.to_s.gsub(/_id$/, "").gsub(/_/, " ").capitalize
    end
  end
end