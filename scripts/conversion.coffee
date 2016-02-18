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
    return (val / data.rates[from] * data.rates[to]).toFixed(2)

  robot.hear /(?:what's |what is |how much is )?([^\d])?([\d,\.]+)? ?([^ \?]+)?(?: in ([^ \?]+))?/, (res) ->
    val = parseFloat(res.match[2].replace(',', '.'))
    prefix = res.match[1]
    suffix = res.match[3]
    from = SYMBOLS[prefix] || SYMBOLS[suffix] || suffix
    to = res.match[4]
    to = SYMBOLS[to] || to
    ufrom = from.toUpperCase()
    uto = if to then to.toUpperCase() else undefined

    # If both units are currencies, run a lookup
    if ufrom in CURRENCIES and (uto in CURRENCIES or uto is undefined)
      lookup_currencies (data) ->
        if uto
          val2 = convert_currency data, val, ufrom, uto
          res.reply "#{val} #{ufrom} would be... #{val2} #{uto}. Do note that my sources only update once per day, so this may be a little bit old."
        else
          usd = convert_currency data, val, ufrom, "USD"
          eur = convert_currency data, val, ufrom, "EUR"
          gbp = convert_currency data, val, ufrom, "GBP"
          jpy = convert_currency data, val, ufrom, "JPY"
          res.reply "#{val} #{ufrom} would be $#{usd}, €#{eur}, £#{gbp} or ¥#{jpy}. Do note that my sources only update once per day, so this may be a little bit old."
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
