math = require 'mathjs'

module.exports = (robot) ->

  CURRENCIES = ['AUD', 'BGN', 'BRL', 'CAD', 'CHF', 'CNY', 'CZK', 'DKK', 'GBP', 'HKD', 'HRK', 'HUF', 'IDR', 'ILS', 'INR', 'JPY', 'KRW', 'MXN', 'MYR', 'NOK', 'NZD', 'PHP', 'PLN', 'RON', 'RUB', 'SEK', 'SGD', 'THB', 'TRY', 'ZAR', 'EUR', 'USD']

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

  lookup_currency = (val, from, to, cb) ->
    robot.http('https://api.fixer.io/latest?base=USD')
      .get() (err, httpres, body) ->
        data = JSON.parse body
        data.rates[data.base] = 1.0 # Base currency maps 1:1 to itself (duh)
        cb val / data.rates[from] * data.rates[to]

  robot.hear /(what's |what is |how much is )?([^\d])?([\d,\.]+)? ?([^ ]+)? in ([^ \?]+)/, (res) ->
    val = parseFloat(res.match[3].replace(',', '.'))
    prefix = res.match[2]
    suffix = res.match[4]
    from = SYMBOLS[prefix] || SYMBOLS[suffix] || res.match[4]
    to = res.match[5]
    to = SYMBOLS[to] || to

    # If both units are currencies, run a lookup
    if from in CURRENCIES and to in CURRENCIES
      lookup_currency val, from, to, (val2) ->
        val2_fix = val2.toFixed(2)
        res.reply "#{val} #{from} would be... #{val2_fix} #{to}. Do note that my sources only update once per day, so this may be a little bit old."
      return

    # Try unit conversion using math.js first
    try
      math_from = math.unit val, from
    catch error
    if math_from
      try
        math_to = math_from.toNumber to
        res.reply "#{val} #{from} = #{math_to} #{to}."
      catch error
        res.reply error
      return
