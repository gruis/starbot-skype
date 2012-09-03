require 'logger'
require 'starbot/ext/rype'
require 'starbot/transport'
require 'rype'

class Starbot
  module Transport
    class Skype
      include Transport

      def initialize(bot, defroom, opts = {})
        setup(bot, defroom, opts)
        watch_rooms
        watch_msgs
        ::Rype::Api.instance.verbose = opts[:verbose]
        ::Rype.attach
        refresh_rooms(opts[:leave_one_on_one])
        refresh_contacts
      end # initialize(opts = {})

      # Send a message directly to a contact.
      def sayto_contact(contact, msg)
        @logger.debug("sayto_contact(#{contact.respond_to?(:id) ? contact.id : contact}, #{msg})")
        unless msg.nil? || msg.empty?
          if contact.is_a?(String)
            ::Rype.chat(contact).send_message(msg.force_encoding('BINARY'))
          else
            rms = @bot.room_list.find_with_only_user(contact)
            if !rms[0].nil?
              ::Rype.chat(rms[0].id).send_message(msg.force_encoding('BINARY'))
            else
              ::Rype::Chat.create(contact.id) do |room|
                ::Rype.chat(room.id).send_message(msg.force_encoding('BINARY'))
              end
            end # rms[0].nil?
          end # contact.is_a?(String)
        end # msg.nil? || msg.empty?
        nil
      end # sayto_contact(contact, msg)

      # Send a message to a room.
      def sayto_room(room, msg)
        ::Rype.chat(room.id).send_message(msg.force_encoding('BINARY')) unless msg.nil? || msg.empty?
        nil
      end # sayto_room(room, msg)

      def register_sayloud
        @bot.on(:sayloud) { |msg| @bot.say("/me #{msg}") unless msg.nil? || msg.empty? }
      end # register_sayloud

      def register_sayloudto
        @bot.on(:sayloudto) { |u,msg| @bot.sayto(u, "/me #{msg}") unless msg.nil? || msg.empty? }
      end # register_sayloud

      def leave_room(room_id)
        ::Rype::Chat.new(room_id).leave
      end # leave_room(room_id)

      def invite_room(rid, user, *users, &blk)
        blk.nil? ? ::Rype::Chat.new(rid).invite(user, *users) : ::Rype::Chat.new(rid).invite("#{user}", *users, &blk)
      end # invite_room(rid, user, *users, &blk)

      def start_room(name, uid, *uids)
        ::Rype::Chat.create(uid, *uids) do |cht|
          cht.set_topic(name) do
            cht.get_props do |cprops|
              yield(cht.id, cprops) if block_given?
            end #  |cprops|
          end # set_topic
        end #  |cht|
      end # start_room(name, uid, *uids)

      def when_authorized(user_id)
        user = ::Rype::User.users.find{|u| u.id == user_id} || ::Rype::User.new(user_id)
        user.is_authorized? do |authed|
          if authed
            yield
          else
            @logger.debug("requesting authorization from #{user_id}")
            user.request_authorization { yield }
          end # authed
        end #  |authed|
      end # when_authorized(user_id)




      # Retrieve an store the known contacts (buddies)
      def refresh_contacts
        ::Rype::User.friends do |friends|
          friends.each do |friend|
            friend.get_props do |props|
              @bot.contact_list.create(friend.id, props[:fullname]).tap do |contact|
                case props[:status]
                when ::Rype::User::BuddyStatus::NEVERINLIST
                  contact.status = :notinlist
                when ::Rype::User::BuddyStatus::DELFROMLIST
                when ::Rype::User::BuddyStatus::PENDINGAUTH
                  contact.status = :waiting
                when ::Rype::User::BuddyStatus::INLIST
                  contact.status = :inlist
                end # props[:status]

                contact.status = :authorized if props[:is_authorized?]
              end # |contact|
            end #  |props|
          end #  |friend|
        end # |friends|
      end # refresh_contacts

      # Retrieve and store the known rooms
      def refresh_rooms(leave_one_on_one = false)
        ::Rype::Chat.all do |chats|
          chats.each do |chat|
            chat.get_props do |cprops|
              next if cprops[:mystatus] == "CHAT_DISBANDED" || cprops[:members].count <= 1
              if !leave_one_on_one
                @bot.room_list.create(chat.id, cprops[:topic], cprops[:members], cprops[:timestamp])
              else
                @bot.room_list.create(chat.id, cprops[:topic], cprops[:members], cprops[:timestamp]).tap do |room|
                  if room.users.count == 2
                    @logger.debug("closing one-on-one chat in #{room.id} with #{room.users.count} users: #{room.users.inspect}")
                    ::Rype::Chat.close(room.id)
                    @bot.room_list.leave(room.id)
                  else
                    #@logger.debug("room #{room.id} contains #{room.users.count} members: #{room.users.inspect}")
                  end # r.users.count == 2
                end #  |room|
              end # !leave_one_on_one
            end # |cprops|
          end #  |chat|
        end #  |chats|
      end # refresh_rooms

      # Watch for new rooms and register them as the show up
      def watch_rooms
        ::Rype::Api.instance.on_notification("CHAT (\#.*) STATUS (DIALOG|MULTI_SUBSCRIBED)$") do |name,type|
          @logger.debug("+++++++ new chat #{name} ++++++")
          ::Rype::Chat.new(name).tap do |chat|
            chat.get_props { |cprops|  @bot.room_list.create(chat.id, cprops[:topic], cprops[:members], cprops[:timestamp]) }
          end #  |chat|
        end #  |name,type|
      end # watch_rooms

      def watch_msgs
        ::Rype.on(:chatmessage_received) do |chatmessage|
          chatmessage.chat do |chat|
            chatmessage.get_props do |mprops|
              chat.get_props do |cprops|
                msg = ::Starbot::Msg.new(mprops[:body],
                                         @bot.contact_list.create(mprops[:handle], mprops[:displayname]),
                                         mprops[:timestamp],
                                         @bot.room_list.create(chat.id, cprops[:topic], cprops[:members], cprops[:timestamp])
                                        )
                @logger.debug("msg: #{msg.inspect}")
                @bot.route(msg.txt, msg)
              end #  |cprops|
            end #  |mprops|
          end # |chat|
        end # |chatmessage|
      end # watch_msgs

    end # class::Rype
  end # module::Transport
end # class::Starbot
