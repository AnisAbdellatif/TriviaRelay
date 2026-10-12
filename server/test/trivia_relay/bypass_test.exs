defmodule TriviaRelay.BypassTest do
  use ExUnit.Case, async: false

  alias TriviaRelay.Bypass

  setup do
    Application.put_env(:trivia_relay, :admin_password, "test-admin")
    on_exit(fn -> Application.delete_env(:trivia_relay, :admin_password) end)
  end

  test "a code redeems once, for a bearer that names the device" do
    {:ok, code} = Bypass.create_code()
    assert {:ok, bearer} = Bypass.redeem(code, "device.with.dots")
    assert Bypass.verify_bearer(bearer) == {:ok, "device.with.dots"}
    assert Bypass.redeem(code, "another") == {:error, :already_used}
  end

  test "deleting a redeemed code revokes its bearer" do
    {:ok, code} = Bypass.create_code()
    {:ok, bearer} = Bypass.redeem(code, "device")
    Bypass.delete_code(code)
    assert Bypass.verify_bearer(bearer) == :error
  end

  test "a bearer altered in any part is refused" do
    {:ok, code} = Bypass.create_code()
    {:ok, bearer} = Bypass.redeem(code, "device")
    [c, d, e, mac] = String.split(bearer, ".")
    other = Base.url_encode64("other", padding: false)

    for forged <- [
          Enum.join([c, other, e, mac], "."),
          Enum.join([c, d, "9999999999999", mac], "."),
          Enum.join([c, d, e, String.duplicate("0", 64)], ".")
        ] do
      assert Bypass.verify_bearer(forged) == :error
    end
  end

  test "an unknown code is not found" do
    assert Bypass.redeem("nope", "device") == {:error, :not_found}
  end
end
