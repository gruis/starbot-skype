require 'rype/chatmessage'

module Rype
  class Chatmessage
    alias :name :chat

   def get_props(&blk)
     return unless block_given?
     timestamp do |ts|
      users do |us|
        from_dispname do |dn|
          from_handle do |hn|
            body do |bd|
              props               = {}
              props[:timestamp]   = ts
              props[:users]       = us
              props[:displayname] = dn
              props[:handle]      = hn
              props[:body]        = bd
              yield props
            end #  |bd|
          end #  |hn|
        end #  |dn|
      end #  |us|
     end #  |ts|
   end # get_props(&blk)

    def timestamp(&blk)
      return unless block_given?
      get_property('TIMESTAMP') { |ts| yield Time.at(ts.to_i) }
    end

    # skypename of the originator of the chatmessage.
    def from_handle(&blk)
      return unless block_given?
      get_property('FROM_HANDLE', &blk)
    end

    # displayed name of the originator of the chatmessage.
    def from_dispname(&blk)
      return unless block_given?
      get_property('FROM_DISPNAME', &blk)
    end

    # message type, for example MESSAGE 21 TYPE TEXT .
    # Possible values:
    #   SETTOPIC – change of chat topic
    #   SAID – IM
    #   ADDEDMEMBERS – invited someone to chat
    #   SAWMEMBERS – chat participant has seen other members
    #   CREATEDCHATWITH – chat to multiple people is created
    #   LEFT – someone left chat; can also be a notification if somebody cannot be added to chat
    #   POSTEDCONTACTS – system message that is sent or received when one user sends contacts to
    #                    another. Added in protocol 7.
    #   GAP_IN_CHAT – messages of this type are generated locally, during synchronization, when
    #                 a user enters a chat and it becomes apparent that it is impossible to update
    #                 user’s chat history completely. Chat history is kept only up to maximum of
    #                 400 messages or 2 weeks. When a user has been offline past that limit,
    #                 GAP_IN_CHAT notification is generated. Added in protocol 7.
    #   SETROLE – system messages that are sent when a chat member gets promoted or demoted. Refer
    #             to ALTER CHATMEMBER SETROLETO command for more info on how to change chat member
    #             roles. Added in protocol 7.
    #   KICKED – system messages that are sent when a chat member gets kicked. Refer to ALTER CHAT
    #            KICK command for more information. Added in protocol 7.
    #   KICKBANNED – system messages that are sent when a chat member gets banned. Refer to ALTER
    #                CHAT KICKBAN command for more information. Added in protocol 7.
    #   SETOPTIONS – system messages that are sent when chat options are changed. Refer to ALTER
    #                CHAT SETOPTIONS command for more information. Added in protocol 7.
    #   SETPICTURE – system messages that are sent when a chat member has changed the public chat
    #                topic picture. Added in protocol 7.
    #   SETGUIDELINES – system messages that are sent when chat guidelines are changed. Refer to
    #                   ALTER CHAT SETGUIDELINES command for more information. Added in protocol 7.
    #   JOINEDASAPPLICANT – notification message that gets sent in a public chat with
    #                       JOINERS_BECOME_APPLICANTS options, when a new user joins the chat. See
    #                       ALTER CHAT SETOPTIONS command for more information on chat options.
    #                       Added in protocol 7.
    #   UNKNOWN – unknown message type, possibly due to connecting to Skype with older protocol.
    def type(&blk)
      return unless block_given?
      get_property('TYPE', &blk)
    end # type(&blk)

    # message status, for example MESSAGE 21 STATUS QUEUED .
    # Possible values:
    #   SENDING – message is being sent
    #   SENT – message was sent
    #   RECEIVED – message has been received
    #   READ – message has been read
    def status(&blk)
      return unless block_given?
      get_property('STATUS', &blk)
    end # status(&blk)

    def leavreason(&blk)
      return unless block_given?
      get_property('LEAVEREASON', &blk)
    end # leavereason(&blk)

    def users(&blk)
      return unless block_given?
      get_property('users', &blk)
    end # users(&blk)

    def is_editable(&blk)
      return unless block_given?
      get_property('IS_EDITABLE', &blk)
    end # is_editable(&blk)

    def edited_by(&blk)
      return unless block_given?
      get_property('EDITED_BY', &blk)
    end # edited_by(&blk)

    def edited_timestamp(&blk)
      return unless block_given?
      get_property('EDITED_TIMESTAMP', &blk)
    end # edited_by(&blk)

    def options(&blk)
      return unless block_given?
      get_property('OPTIONS', &blk)
    end # options(&blk)

    def role(&blk)
      return unless block_given?
      get_property('ROLE', &blk)
    end # role(&blk)

  end # class::Chatmessage
end # module::Rype
