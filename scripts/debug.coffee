util = require 'util'

module.exports = (robot) ->

  robot.respond /debug dump(.*)/i, (res) ->
    console.log util.inspect(res.message, { depth: 2 })
