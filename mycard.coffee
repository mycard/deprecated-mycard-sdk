mycard =
  card_usages_key: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_="
  card_usages_decode: (encoded)->
    result = []
    return result if !encoded
    for i in [0...encoded.length] by 5
      decoded = 0
      for char in encoded.substr(i, 5)
        decoded = (decoded << 6) + @card_usages_key.indexOf(char)
      side = !!(decoded >> 29)
      count = decoded >> 27 & 0x3
      card_id = decoded & 0x07FFFFFF
      result.push {card_id: card_id, side: side, count: count}
    result
  card_usages_equal: (card_usages1, card_usages2)->
    main = {}
    side = {}
    for cards_usage in card_usages1
      if cards_usage.side
        if side[cards_usage.card_id]
          side[cards_usage.card_id] += cards_usage.count
        else
          side[cards_usage.card_id] = cards_usage.count
      else
        if main[cards_usage.card_id]
          main[cards_usage.card_id] += cards_usage.count
        else
          main[cards_usage.card_id] = cards_usage.count
    for cards_usage in card_usages2
      if cards_usage.side
        if side[cards_usage.card_id]
          side[cards_usage.card_id] -= cards_usage.count
        else
          return false
      else
        if main[cards_usage.card_id]
          main[cards_usage.card_id] -= cards_usage.count
        else
          return false

    for card_id, count of main
      return false if count
    for card_id, count of side
      return false if count
    true


module.exports = mycard







#old
@mycard = {}
@mycard.room_name = (name, password, pvp = false, rule = 0, mode = 0, start_lp = 8000, start_hand = 5, draw_count = 1, enable_priority = false, no_check_deck = false, no_shuffle_deck = false) ->
  if rule != 0 or start_lp != 8000 or start_hand != 5 or draw_count != 1
    result = "#{rule}#{mode}#{if enable_priority then 'T' else 'F'}#{if no_check_deck then 'T' else 'F'}#{if no_shuffle_deck then 'T' else 'F'}#{start_lp},#{start_hand},#{draw_count},"
  else if mode == 2
    result = "T#"
  else if pvp and mode == 1
    result = "PM#"
  else if pvp
    result = "P#"
  else if mode == 1
    result = "M#"
  else
    result = ""
  result += name
  result = encodeURIComponent(result)
  if password
    result += '$' + encodeURIComponent(password)
  result

#127.0.0.1:8087/test
@mycard.room_string = (ip,port,room,username,password, _private, server_auth)->
  result = ''
  if username
    result += encodeURIComponent(username)
    if password
      result += ':' + encodeURIComponent(password)
    result += '@'
  result += ip + ':' + port + '/' + room
  if _private
    result += '?private=true'
    if server_auth
      result += '&server_auth=true'
  else if server_auth
    result += '?server_auth=true'
  result

#http://my-card.in/rooms/127.0.0.1:8087/test
@mycard.room_url = (ip,port,room,username,password, _private, server_auth)->
  result = 'http://my-card.in/rooms/' + @room_string(ip,port,room,username,password, _private, server_auth)

#mycard://127.0.0.1:8087/test
@mycard.room_url_mycard = (ip,port,room,username,password, _private, server_auth)->
  result = 'mycard://' + @room_string(ip,port,room,username,password, _private, server_auth)

@mycard.join = (ip,port,room,username,password, _private, server_auth)->
  window.location.href = @room_url_mycard(ip,port,room,username,password, _private, server_auth)

@mycard.load_card_usages_from_cards = (cards)->
  result = []
  last_id = 0
  for card_id in cards
    if card_id
      if card_id == last_id
        count++
      else
        result.push {id: Math.random(), card_id: last_id, side: false, count: count} if last_id
        last_id = card_id
        count = 1
    else
      throw '无效卡组'
  result.push {id: Math.random(), card_id: last_id, side: false, count: count} if last_id
  result

@mycard.load_decks_from_replay = (replay_file, callback)->
  form_data = new FormData();
  form_data.append('replay', replay_file);
  $.ajax
    url: 'http://my-card.in/replays/new.yuyu',
    type: 'POST'
    data: form_data
    cache: false
    contentType: false,
    processData: false
    success: (data)->
      for deck_yuyu in data.match(/Playerpos\d\?.*?\|ALLDECK\|.*?\|END\|/g)
        deck_yuyu = deck_yuyu.match(/Playerpos(\d)\?(.*?)\|ALLDECK\|(.*?)\|END\|/)
        name = "#{deck_yuyu[1]}_#{deck_yuyu[2]}"
        cards = (card_id for card_yuyu in deck_yuyu[3].split('|') when card_id = parseInt(card_yuyu.split('?')[1]))
        callback name: name, card_usages: mycard.load_card_usages_from_cards cards