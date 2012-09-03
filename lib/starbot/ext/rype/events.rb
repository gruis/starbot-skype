require 'rype/events'

module Rype
  class Events
    class << self
      def callbacks
        @callbacks ||= Hash.new{|hash,scope| hash[scope] = {} }
      end # callbacks

      def on(event)
        case event
        when :chatmessage_received
          Rype::Api.instance.on_notification("CHATMESSAGE (.*) STATUS RECEIVED") do |chatmessage_id|
            yield Chatmessage.new(chatmessage_id)
          end # |chatmessage_id|

        when :chats_received
          Rype::Api.instance.on_notification("CHATS (.*)") do |chatlist|
            yield chatlist.split(', ').map { |chatname| Chat.new(chatname) }
          end # |chatlist|

        when :users_received
          Rype::Api.instance.on_notification("USERS (.*)$") do |user_ids|
            users = user_ids.split(",").map do |user_id|
              user_id.strip!
              User.users.find{|u| u.id == user_id } ||  User.new(user_id)
            end
            yield users
          end # |user_ids|

        end # event
      end # on(event)

      # registers a callback for a particular id in a scope
      # @example
      #   Rype::Events.watch_until(:buddystatus, 'simulacrejp') do |user_id, status|
      #     # ...
      #     done? ? true : false
      #   end #  |user_id, status|
      def watch_until(scope, id, &blk)
        (callbacks[scope][id] ||= []).push(blk)
      end # watch_until(scope, id, &blk)


      def initialize_listeners
        mutex = Mutex.new
        Rype::Events.on(:chats_received) do |chats|
          mutex.synchronize { Rype::Chat.chats = chats }
        end # |chats|

        umutex = Mutex.new
        Rype::Events.on(:users_received) do |users|
          umutex.synchronize { users.each{|u| Rype::User.users.push(u) unless Rype::Users.users.include?(u) } }
        end #  |users|

        Rype::Api.instance.on_notification("USER (.*) BUDDYSTATUS (.*)") do |user_id, bstatus|
          if callbacks[:buddy_status][user_id].is_a?(Array)
            bstatus = bstatus.to_i
            callbacks[:buddy_status][user_id].clone.each do |callback|
              remove = callback.call(user_id, bstatus)
              # requires the .clone above
              callbacks[:buddy_status][user_id].delete(callback) if remove
            end #  |callback|
          end # callbacks[:buddy_status][user_id].is_a?(Array)
        end # |user_id, bstatus|
      end # initialize_listeners

    end # class << self
  end # class::Events
end # module::Rype
