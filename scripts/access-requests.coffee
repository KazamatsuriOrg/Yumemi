util = require 'util'

i = (o) -> util.inspect o, { colors: true }

module.exports = (robot) ->

  # Constants
  THREAD_ID = 2000
  ROLE_NAME = "Member"
  TRUST_LEVEL = 2
  TRUST_LEVEL_NAME = "member"

  # Errors and replies
  ERR_ALREADY_A_MEMBER = "You appear to be a verified member already. If you require assistance, please alert a staff member with a blue name."
  ERR_INVALID_THREAD = "In order to verify your identity, please link a post made in the following thread. Be sure to mention your Discord username in it: https://forum.kazamatsuri.org/t/kazamatsuri-discord-chat/2000"
  ERR_INVALID_POST = "I apologize, but the post you have referred me to doesn't seem to exist... To obtain a valid link, please click the timestamp in the top right, and copy the link it gives you."
  ERR_NO_MENTION = "Hm, it doesn't appear as though you have mentioned your Discord username in your forum post... perhaps you did not spell it correctly?"
  ERR_TRUST_LEVEL = "I'm sorry, but I cannot let you in until you have reached the '#{TRUST_LEVEL_NAME}' trust level. To raise your trust level, please participate on the forum for a few days, and it should come naturally. You may confirm your trust level on your forum user page at any time."

  ERR_NO_SUCH_ROLE = "I'm so sorry, I appear to be misconfigured... I cannot appear to locate the '#{ROLE_NAME}' role! Please alert a staff member (with a blue name) as soon as possible! @_@"

  ERR_FORUM_BROKEN = "I apologize, but I couldn't reach the forum... could it have gone down?"
  ERR_FORUM_GIBBERISH = "I'm sorry, but the forum appears to have given me some data I can't understand... You may try again, but if it keeps up, please alert a staff member with a blue name."

  ERR_DISCORD_ERROR = "I'm so sorry, something appears to be broken, as I am unable to grant you access! >_< ({0})"

  MSG_WELCOME = "Your identity has been verified, welcome!"

  # Listen for posts in #access-requests
  robot.listen(
    (msg) ->
      msg.room.name == 'access-requests'
    (res) ->
      server = res.envelope.room.server
      user = res.envelope.user.id

      # Extract the post ID; abort if there's no forum link
      match = res.message.text.match(/forum.kazamatsuri.org\/t\/?([^\/]+)?\/(\d+)\/(\d+)/i)
      return unless match
      thread_id = parseInt(match[2])
      post_id = parseInt(match[3])

      # Abort if the user is already a member
      if server.rolesOfUser(user).find ((role) -> role.name == ROLE_NAME)
        res.reply ERR_ALREADY_A_MEMBER
        return

      # Abort if the wrong thread is linked
      if thread_id != THREAD_ID
        res.reply ERR_INVALID_THREAD
        return

      # Find the Member role
      role = server.roles.get('name', ROLE_NAME)
      unless role
        res.reply ERR_NO_SUCH_ROLE
        return

      # Get the post from Discourse
      robot.http("https://forum.kazamatsuri.org/t/#{thread_id}/#{post_id}.json")
        .get() (err, httpres, body) ->
          if err
            res.reply ERR_FORUM_BROKEN
            return

          try
            thread_data = JSON.parse body
          catch err
            res.reply ERR_FORUM_GIBBERISH
            return

          post_data = thread_data.post_stream.posts.find (post) -> post.post_number == post_id
          unless post_data
            res.reply ERR_INVALID_POST
            return

          if post_data.cooked.indexOf(user.username) == -1
            # console.log post_data.cooked
            # console.log user.username
            res.reply ERR_NO_MENTION
            return

          robot.http("https://forum.kazamatsuri.org/users/#{post_data.username}.json")
            .get() (err, httpres, body) ->
              if err
                res.reply ERR_FORUM_BROKEN
                return

              try
                profile_data = JSON.parse body
              catch error
                res.reply ERR_FORUM_GIBBERISH
                return

              user_data = profile_data.user
              unless user_data.trust_level >= TRUST_LEVEL
                res.reply ERR_TRUST_LEVEL
                return

              server.client.addMemberToRole user, role, (err) ->
                if err
                  res.reply ERR_DISCORD_ERROR.replace('{0}', err)
                  return

                res.reply MSG_WELCOME
  )
