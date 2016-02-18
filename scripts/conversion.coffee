math = require 'mathjs'

module.exports = (robot) ->

  SYMBOLS =
    '$':    'USD'
    'A$':   'AUD'
    'C$':   'CAD'
    'Can$': 'CAD'
    'HK$':  'HKD'
    'NZ$':  'NZD'
    'S$':   'SGD'
    'US$':  'USD'
    'R$':   'BRL'
    '€':    'EUR'
    'kr':   'SEK'
    'Dkr':  'DKK'
    'Nkr':  'NOK'
    '£':    'GBP'
    '₤':    'GBP'
    '₽':    'RUB'
    '¥':    'JPY'
    '円':   'JPY'
    'yen':  'JPY'

  RATES = {}

  lookup_currency = (from, to, cb) ->
    unless RATES
      robot.http('https://api.fixer.io/latest?base=USD')
        .get() ()

  robot.hear /(what's |what is |how much is )?([^\d])?([\d,\.]+)? ?([^ ]+)? in ([^ \?]+)/, (res) ->
    val = parseFloat(res.match[3].replace(',', '.'))
    prefix = res.match[2]
    suffix = res.match[4]
    from = SYMBOLS[prefix] || SYMBOLS[suffix] || res.match[4]
    to = res.match[5]
    to = SYMBOLS[to] || to

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

    # Give up!
    res.reply "I'm sorry, I don't know how to convert #{from} into #{to}..."
