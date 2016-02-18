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

  lookup_currencies = (cb) ->
    robot.http('https://api.fixer.io/latest?base=USD')
      .get() (err, httpres, body) ->
        data = JSON.parse body
        data.rates[data.base] = 1.0 # Base currency maps 1:1 to itself (duh)
        cb data

  convert_currency = (data, val, from, to) ->
    return val / data.rates[from] * data.rates[to]

  robot.hear /(?:what's |what is |how much is )?([^\d])?([\d,\.]+)? ?([^ \?]+)? in ([^ \?]+)/, (res) ->
    val = parseFloat(res.match[2].replace(',', '.'))
    prefix = res.match[1]
    suffix = res.match[3]
    from = SYMBOLS[prefix] || SYMBOLS[suffix] || suffix
    to = res.match[4]
    to = SYMBOLS[to] || to

    # If both units are currencies, run a lookup
    if from in CURRENCIES and to in CURRENCIES
      lookup_currencies (data) ->
        val2 = convert_currency data, val, from, to
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
        res.reply "Unless I misheard, #{val} #{from} = #{math_to} #{to}."
      catch error
        res.reply error
      return

  robot.hear /(?:what's |what is |how much is )?([^\d])?([\d,\.]+)? ?([^ ]+)?\??$/, (res) ->
    val = parseFloat(res.match[2].replace(',', '.'))
    prefix = res.match[1]
    suffix = res.match[3]
    from = SYMBOLS[prefix] || SYMBOLS[suffix] || suffix

    if from in CURRENCIES
      lookup_currencies (data) ->
        usd = (convert_currency data, val, from, "USD").toFixed(2)
        eur = (convert_currency data, val, from, "EUR").toFixed(2)
        gbp = (convert_currency data, val, from, "GBP").toFixed(2)
        jpy = (convert_currency data, val, from, "JPY").toFixed(2)
        res.reply "#{val} #{from} would be $#{usd}, €#{eur}, £#{gbp} or ¥#{jpy}. Do note that my sources only update once per day, so this may be a little bit old."
