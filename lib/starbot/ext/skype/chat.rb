require 'skype/chat'

module Skype
  class Chat
    class << self
      def create(user, *users, &blk)
        users.unshift(user)
        Api.invoke("CHAT CREATE") do |resp|
          if (match = Regexp.new("^CHAT (\#.*) STATUS (DIALOG|MULTI_SUBSCRIBED)$").match(resp))
            new(match.captures[0]).tap do |c| 
              c.invite(users[0], *users[1..-1]) { yield c if block_given? }
            end
          end # match = //.match(resp)
        end #  |resp|
      end # create(user, *users)
      
      def leave(chat, &blk)
        block_given? ? Api.invoke("ALTER CHAT #{chat} LEAVE", &blk) : Api.invoke("ALTER CHAT #{chat} LEAVE")
      end
      def close(chat, &blk)
        block_given? ? Api.invoke("ALTER CHAT #{chat} DISBAND", &blk) : Api.invoke("ALTER CHAT #{chat} DISBAND")
      end
    end # << self
    
    
    alias :id :chatname
    
    def get_props(&blk)
      return unless block_given?
      name do |n|
        adder do |a|
          members do |m|
            topic do |t|
              friendlyname do |f|
                timestamp do |ts|
                  mystatus do |ms|
                    props                = {}
                    props[:name]         = n
                    props[:addr]         = a
                    props[:members]      = m.split(" ").map{|mid| ::Starbot::Contact.new(mid, "") }
                    props[:topic]        = t
                    props[:friendlyname] = f
                    props[:timestamp]    = ts
                    props[:mystatus]     = ms
                    yield props
                  end #  |ms|
                end #  |ts|
              end #  |f|
            end #  |t|
          end #  |m|
        end #  |a|
      end #  |n|
    end # load_props(&blk)
    
    def name(&blk)
      return unless block_given?
      get_property('NAME', &blk)
    end
    
    def timestamp(&blk)
      return unless block_given?
      get_property('TIMESTAMP') { |ts| yield Time.at(ts.to_i) }
    end
    
    def adder(&blk)
      return unless block_given?
      get_property('ADDER', &blk)
    end
    
    def status(&blk)
      return unless block_given?
      get_property('STATUS', &blk)
    end
    
    def posters(&blk)
      return unless block_given?
      get_property('POSTERS', &blk)
    end
    
    def members(&blk)
      return unless block_given?
      get_property('MEMBERS', &blk)
    end
    
    def topic(&blk)
      return unless block_given?
      get_property('TOPIC', &blk)
    end
    
    def chatmessages(&blk)
      return unless block_given?
      get_property('CHATMESSAGES', &blk)
    end
    
    def activemembers(&blk)
      return unless block_given?
      get_property('ACTIVEMEMBERS', &blk)
    end
    
    def friendlyname(&blk)
      return unless block_given?
      get_property('FRIENDLYNAME', &blk)
    end
    
    # User’s current status in chat. Possible values are:
    #   CONNECTING – status set when the system is trying to connect to the chat.
    #   WAITING_REMOTE_ACCEPT – set when a new user joins a public chat. When the chat has “participants need 
    #                           authorization to read messages” option, the MYSTATUS property of a new applicant 
    #                           will remain in this status until he gets accepted or rejected by a chat administrator. 
    #                           Otherwise user’s MYSTATUS will automatically change to either LISTENER or USER, 
    #                           depending on public chat options.
    #   ACCEPT_REQUIRED – this status is used for shared contact groups functionality.
    #   PASSWORD_REQUIRED – status set when the system is waiting for user to supply the chat password.
    #   SUBSCRIBED – set when user joins the chat.
    #   UNSUBSCRIBED – set when user leaves the chat or chat ends.
    #   CHAT_DISBANDED – status set when the chat is disbanded.
    #   QUEUED_BECAUSE_CHAT_IS_FULL – currently the maximum number of people in the same chat is 100.
    #   APPLICATION_DENIED – set when public chat administrator has rejected user from joining.
    #   KICKED – status set when the user has been kicked from the chat. Note that it is possible for the user to 
    #            re-join the chat after being kicked.
    #   BANNED – status set when the user has been banned from the chat.
    #   RETRY_CONNECTING – status set when connect to chat failed and system retries to establish connection.
    def mystatus(&blk)
      return unless block_given?
      get_property('MYSTATUS', &blk)
    end
    
    def set_topic(tpc, &blk)
      block_given? ? Api.invoke("ALTER CHAT #{@chatname} SETTOPIC #{tpc}", &blk) : Api.invoke("ALTER CHAT #{@chatname} SETTOPIC #{tpc}")
    end # set_topic(tpc, &blk)
    
    def leave(&blk)
      block_given? ? Api.invoke("ALTER CHAT #{@chatname} LEAVE", &blk) : Api.invoke("ALTER CHAT #{@chatname} LEAVE")
    end
    
    def invite(user, *users, &blk)
      users.unshift(user)
      block_given? ? Api.invoke("ALTER CHAT #{@chatname} ADDMEMBERS #{users.join(", ")}", &blk) : Api.invoke("ALTER CHAT #{@chatname} ADDMEMBERS #{users.join(", ")}")
    end # invite(user, *users, &blk)
    
  private
  
    def get_property(property, &block)
      return unless block_given?
      Api.invoke("GET CHAT #{@chatname} #{property}") do |message|
        message.split[3..-1].tap{|r| r.nil? ? yield(nil) : yield(r.join(' ')) }
      end
    end    
  end # class::Chat
end # module::Skype
