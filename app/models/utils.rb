class Utils
  SPLITTER = " | ".freeze
  SEPARATOR = ", ".freeze
  REGEXP_SPLITTER = "|".freeze

  # Returns the hash digest of the given string.
    def self.digest(string)
      cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
      BCrypt::Password.create(string, cost: cost)
    end

    # Returns a random token.
    def self.new_token(n = nil)
      n ? SecureRandom.urlsafe_base64(n) : SecureRandom.urlsafe_base64
    end

    # # Returns an alphanumeric token with values a-z A-Z and 0-9
    def self.new_alphanumeric_token(n = 12)
      token = new_token(n)
      i = SecureRandom.random_number(allowedChars.size)
      token.gsub!(/[-_]/, allowedChars[i])
      return token
    end

    def self.format_search_key_words(key_words)
      if key_words.at(SEPARATOR).present?

        key_words = key_words.split(SEPARATOR)
        key_words.each{ |keyword| keyword.strip! }
        key_words = key_words.join(REGEXP_SPLITTER)

      else
        key_words = "%#{key_words.strip}%"
      end
    end

    private
      def self.allowedChars
        # do not use l nor I because they are pretty the same with Roboto Font
        %w[a b c d e f g h i j k m n o p q r s t u v w x y z
          A B C D E F G H J K L M N O P Q R S T U V W X Y Z
          0 1 2 3 4 5 6 7 8 9]
      end
end
