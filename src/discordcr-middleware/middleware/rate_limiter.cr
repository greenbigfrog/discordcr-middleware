require "rate_limiter"

module DiscordMiddleware
  # Enum for specifying which event attribute should be used
  # for rate limiting, in order to have per-user, per-channel,
  # or a per-guild rate limit.
  enum RateLimiterKey
    UserID
    ChannelID
    GuildID
  end

  # Middleware for performing rate limiting on message events. Rate limiting
  # can be configured to be per-user, per-channel, or per-guild by passing
  # a `RateLimiterKey` option.
  #
  # If the client has a cache enabled, it will be
  # used to resolve the guild to be rate limited on.
  #
  # If `message` contains the substring `"%time%"` it will be replaced
  # with the remaining time until the rate limit expires.
  # ```
  # limiter = RateLimiter(UInt64).new
  #
  # # Limit 3 events per second
  # limiter.bucket(:foo, 3_u32, 1.seconds)
  #
  # middleware = DiscordMiddleware::RateLimiter.new(
  #   limiter,
  #   :foo,
  #   DiscordMiddleware::RateLimiterKey::ChannelID
  #   "Slow down! Try again in %time%."
  # )
  #
  # client.on_message_create(middleware) do |payload, context|
  #   # Post memes, but not too quickly per-channel
  # end
  # ```
  class RateLimiter
    include DiscordMiddleware::CachedRoutes

    def initialize(@limiter : ::RateLimiter(Discord::Snowflake), @bucket : Symbol,
                   @key : RateLimiterKey = RateLimiterKey::UserID,
                   @message : String? = nil)
    end

    private def rate_limit_reply(client, channel_id, time)
      if message = @message
        content = message.gsub("%time%", time.to_s)
        client.create_message(channel_id, content)
      end
    end

    def call(payload : Discord::Message, context : Discord::Context)
      client = context[Discord::Client]

      case key = @key
      when RateLimiterKey::UserID
        if time = @limiter.rate_limited?(@bucket, payload.author.id)
          rate_limit_reply(client, payload.channel_id, time)
          return
        end
      when RateLimiterKey::ChannelID
        if time = @limiter.rate_limited?(@bucket, payload.channel_id)
          rate_limit_reply(client, payload.channel_id, time)
          return
        end
      when RateLimiterKey::GuildID
        if guild_id = get_channel(client, payload.channel_id).guild_id
          if guild = get_guild(client, guild_id)
            if time = @limiter.rate_limited?(@bucket, payload.channel_id)
              rate_limit_reply(client, payload.channel_id, time)
              return
            end
          end
        end
      end

      yield
    end
  end
end
