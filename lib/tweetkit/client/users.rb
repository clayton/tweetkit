module Tweetkit
  class Client
    module Users
      def follow(id, **options)
        post "users/#{id}/follow", **options
      end
    end
  end
end
