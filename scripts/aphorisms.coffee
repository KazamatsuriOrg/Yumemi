module.exports = (robot) ->

  robot.respond /aphorism\:? \"([^\"]*)\" [-\w]*(.*)/i, (res) ->
    text = res.match[1]
    name = res.match[2]

    text64 = new Buffer(text).toString('base64');
    name64 = new Buffer(name).toString('base64');

    res.reply "http://aphorisms.kazamatsuri.org/?#{text64}?#{name64}"
