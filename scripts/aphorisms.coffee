module.exports = (robot) ->

  robot.hear /aphorism\:? \"([^\"]*)\" ?[- ]*(.*)/i, (res) ->
    text = res.match[1]
    name = res.match[2]
    b64data = new Buffer(text + '\0' + name).toString('base64').replace('=', '');

    res.reply "http://aphorisms.kazamatsuri.org/?#{b64data}"
