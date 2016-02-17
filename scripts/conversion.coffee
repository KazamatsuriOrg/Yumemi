math = require 'mathjs'

module.exports = (robot) ->

  robot.hear /(what's |what is |how much is )?([\$]?[\d,\.]+[\€\¥\£]?) ?(\w+) in ([^ ]+)/, (res) ->
    val = parseFloat(res.match[2].replace(',', '.'))
    from = res.match[3]
    to = res.match[4]

    # Try unit conversion using math.js first
    try
      math_from = math.unit val, from
    catch error
    if math_from
      try
        math_to = math_from.toNumber to
        res.reply "#{val} #{from} = #{math_to} #{to}"
      catch error
        res.reply error
