defmodule TriviaRelay.Sporcle.EnvelopeTest do
  use ExUnit.Case, async: true

  alias TriviaRelay.Sporcle.Envelope

  # Reference bytes from the scraper's sporcle/protocol.py, which was verified
  # byte for byte against captured traffic. The JSON is passed through as the
  # scraper wrote it (Python's spacing) so the envelope around it can be compared.

  @answer_json ~s(["answer_question", {"questionIndex": 3, "wagerAmount": 0, "guessText": "Tunis"}])
  @answer_hex "6708c80118ffffffffffffffffff012808300138027a515b22616e737765725f7175657374696f6e222c207b227175657374696f6e496e646578223a20332c20227761676572416d6f756e74223a20302c2022677565737354657874223a202254756e6973227d5d"

  @start_hex "2408c80118ffffffffffffffffff012808300138027a0e5b2273746172745f67616d65225d"

  @login_player ~s({"isHost": true, "teamName": "Tester", "mascotType": "none", "mascotCustomImageUrl": "", "hatType": "None", "clientVersion": "1.5.15.297", "sporcleHandle": "Tester", "platform": {"os": "android", "brand": "google", "manufacturer": "Google", "systemVersion": "17"}, "playerId": "sporcle_id//abc123", "deviceId": "0123456789abcdef"})
  @login_hex "8b0318ffffffffffffffffff01300138027aca027b226973486f7374223a20747275652c20227465616d4e616d65223a2022546573746572222c20226d6173636f7454797065223a20226e6f6e65222c20226d6173636f74437573746f6d496d61676555726c223a2022222c202268617454797065223a20224e6f6e65222c2022636c69656e7456657273696f6e223a2022312e352e31352e323937222c202273706f72636c6548616e646c65223a2022546573746572222c2022706c6174666f726d223a207b226f73223a2022616e64726f6964222c20226272616e64223a2022676f6f676c65222c20226d616e756661637475726572223a2022476f6f676c65222c202273797374656d56657273696f6e223a20223137227d2c2022706c617965724964223a202273706f72636c655f69642f2f616263313233222c20226465766963654964223a202230313233343536373839616263646566227df2012c0a2a70736573732d30303030303030302d313131312d323232322d333333332d343434343434343434343434"
  @session_id "psess-00000000-1111-2222-3333-444444444444"

  # A server message: the same envelope with the sender's peer id (7) in field 3.
  @server_hex "4608c80118072808300138027a395b2267616d655f7175657374696f6e222c207b227175657374696f6e496e646578223a20302c20227175657374696f6e223a2022513f227d5d"

  defp hex(h), do: Base.decode16!(h, case: :lower)

  test "a game message matches the captured envelope" do
    assert Envelope.game_json(@answer_json) == hex(@answer_hex)
  end

  test "an event with no payload is a one-element array" do
    assert Envelope.game("start_game") == hex(@start_hex)
  end

  test "login matches the captured envelope" do
    assert Envelope.login_json(@login_player, @session_id) == hex(@login_hex)
  end

  test "decodes a server message, reading field 3 as the signed sender" do
    {[body], ""} = Envelope.split(hex(@server_hex))
    assert {:ok, msg} = Envelope.decode(body)
    assert msg.event == "game_question"
    assert msg.payload == %{"questionIndex" => 0, "question" => "Q?"}
    assert {1, 200} in msg.fields
    assert {3, 7} in msg.fields
  end

  test "reads -1 back from a ten-byte varint" do
    {[body], ""} = Envelope.split(Envelope.game("x", %{}))
    assert {:ok, %{fields: fields}} = Envelope.decode(body)
    assert {3, -1} in fields
  end

  test "keeps every field of a login, including the nested session id" do
    {[body], ""} = Envelope.split(hex(@login_hex))
    assert {:ok, msg} = Envelope.decode(body)
    assert msg.event == nil
    {30, nested} = List.keyfind(msg.fields, 30, 0)
    assert Envelope.fields(nested) == {:ok, [{1, @session_id}]}
  end

  test "split holds back an incomplete message" do
    whole = Envelope.game("a", 1) <> Envelope.game("b", 2)
    partial = binary_part(whole, 0, byte_size(whole) - 3)
    assert {[_], rest} = Envelope.split(partial)
    assert {[_, _], ""} = Envelope.split(whole)
    assert byte_size(rest) > 0
  end

  test "undecodable bytes are an error, not a crash" do
    assert Envelope.decode(<<0xFF>>) == :error
  end
end
