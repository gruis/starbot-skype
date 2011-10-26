require 'skype/events'

module Skype
  class User
    module BuddyStatus
      # never been in contact list.
      NEVERINLIST = 0
      # deleted from contact list. (read-write)
      DELFROMLIST = 1
      # pending authorisation. (read-write)
      PENDINGAUTH = 2
      # added to contact list.
      INLIST      = 3
    end # module::BuddyStatus
    
    
    class << self
      def users
        @users ||= []
      end # users
      
      def friends
        @friends ||= []
        Api.invoke("SEARCH FRIENDS") do |resp|
          if (match = Regexp.new("^USERS (.*)$").match(resp))
            match.captures[0].split(",").each do |user_id|
              user_id.strip!
              if (known = users.find{|u| u.is_a?(User) && u.id == user_id })
                @friends.push(known) unless @friends.include?(known)
              else
                new(user_id).tap do |u| 
                  @friends.push(u)
                  @users.push(u)
                end
              end # known
            end #  |user_id|
          end # (match = Regexp.new("^USERS (.*)$").match(resp))
          yield @friends if block_given?
        end #  |resp|
        @friends
      end # friends
      
    end # class << self
    
    
    attr_reader :id
    
    def initialize(id)
      @id = id
    end # initialize(username)
    
    def get_props(&blk)
      return unless block_given?
      fullname do |fn|
        buddystatus do |bs|
          is_authorized? do |auth|
            props                  = {}
            props[:fullname]       = fn
            props[:buddystatus]    = bs
            props[:is_authorized?] = auth
            yield props
          end #  |auth|
        end #  |bs|
      end #  |fn|
    end # get_props(&blk)
    
    def handle
      @id
    end
    def fullname(&blk)
      return unless block_given?
      get_property('FULLNAME') { |fn| yield fn }
    end
    def buddystatus(&blk)
      return unless block_given?
      get_property('BUDDYSTATUS') { |bs| yield bs.to_i }
    end
    def is_authorized?(&blk)
      return unless block_given?
      get_property('ISAUTHORIZED') { |auth| yield auth == "TRUE" }
    end
    def is_blocked?(&blk)
      return unless block_given?
      get_property('ISBLOCKED') { |ib| yield ib == "TRUE" }
    end
    def onlinestatus(&blk)
      return unless block_given?
      get_property('ONLINESTATUS') { |bs| yield bs.to_i }
    end
    
    # Send an authorization request to the User.
    # If the request is approved yield to a given block.
    def request_authorization(msg = "Please authorize me", &blk)
      return unless block_given?
      Skype::Events.watch_until(:buddy_status, @id) do |user_id, bstatus|
        bstatus == BuddyStatus::INLIST ? true.tap{ yield(bstatus) } : false
      end #  |user_id, bstatus|

      Api.invoke("SET USER #{@id} BUDDYSTATUS 2 #{msg}")
    end # request_authorization(&blk)
    
  private
    def get_property(property, &block)
      return unless block_given?
      Api.invoke("GET USER #{@id} #{property}") do |message|
        yield message.split[3..-1].join(' ')
      end # |message|
    end # get_propery

  end # class::User
end # module::Skype
