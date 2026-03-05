defmodule Faultex.MatcherTest do
  use ExUnit.Case

  defmodule TestMatcher do
    use Faultex,
      injectors: [
        %Faultex.Injector.ErrorInjector{
          host: "*",
          path: "/api/users",
          method: "GET",
          percentage: 100,
          resp_status: 500,
          resp_body: "error"
        }
      ]
  end

  describe "catch-all match?/4" do
    test "returns {false, nil} for unmatched path" do
      assert {false, nil} = TestMatcher.match?("*", "GET", ["unknown"], [])
    end

    test "returns {false, nil} for unmatched method" do
      assert {false, nil} = TestMatcher.match?("*", "DELETE", ["api", "users"], [])
    end
  end

  describe "sampled?/1" do
    test "always returns true for percentage 100" do
      assert Faultex.Matcher.sampled?(100) == true
    end

    test "always returns false for percentage 0" do
      results = for _ <- 1..100, do: Faultex.Matcher.sampled?(0)
      assert Enum.all?(results, &(&1 == false))
    end

    test "returns mixed results for intermediate percentage with fixed seed" do
      :rand.seed(:exsss, {1, 2, 3})
      results = for _ <- 1..100, do: Faultex.Matcher.sampled?(50)
      true_count = Enum.count(results, & &1)
      assert true_count > 0
      assert true_count < 100
    end

    test "uses custom RNG from Application env" do
      Application.put_env(:faultex, :rand_uniform, fn _max -> 50 end)
      on_exit(fn -> Application.delete_env(:faultex, :rand_uniform) end)

      assert Faultex.Matcher.sampled?(51) == true
      assert Faultex.Matcher.sampled?(50) == false
    end

    test "percentage 100 bypasses custom RNG" do
      Application.put_env(:faultex, :rand_uniform, fn _max -> 100 end)
      on_exit(fn -> Application.delete_env(:faultex, :rand_uniform) end)

      assert Faultex.Matcher.sampled?(100) == true
    end

    test "falls back to :rand.uniform/1 when not configured" do
      Application.delete_env(:faultex, :rand_uniform)
      assert is_boolean(Faultex.Matcher.sampled?(50))
    end
  end

  describe "validate_injector!/1" do
    test "raises ArgumentError when percentage is negative" do
      assert_raise ArgumentError, ~r/percentage/, fn ->
        Faultex.Matcher.do_build_matcher(%Faultex.Injector.ErrorInjector{percentage: -1})
      end
    end

    test "raises ArgumentError when percentage exceeds 100" do
      assert_raise ArgumentError, ~r/percentage/, fn ->
        Faultex.Matcher.do_build_matcher(%Faultex.Injector.ErrorInjector{percentage: 101})
      end
    end

    test "raises ArgumentError when percentage is not an integer" do
      assert_raise ArgumentError, ~r/percentage/, fn ->
        Faultex.Matcher.do_build_matcher(%Faultex.Injector.ErrorInjector{percentage: "50"})
      end
    end

    test "raises ArgumentError when resp_delay is negative" do
      assert_raise ArgumentError, ~r/resp_delay/, fn ->
        Faultex.Matcher.do_build_matcher(%Faultex.Injector.ErrorInjector{resp_delay: -1})
      end
    end

    test "raises ArgumentError when resp_status is negative" do
      assert_raise ArgumentError, ~r/resp_status/, fn ->
        Faultex.Matcher.do_build_matcher(%Faultex.Injector.ErrorInjector{resp_status: -1})
      end
    end

    test "raises ArgumentError for SlowInjector with invalid percentage" do
      assert_raise ArgumentError, ~r/percentage/, fn ->
        Faultex.Matcher.do_build_matcher(%Faultex.Injector.SlowInjector{percentage: 150})
      end
    end

    test "raises ArgumentError for RejectInjector with invalid resp_delay" do
      assert_raise ArgumentError, ~r/resp_delay/, fn ->
        Faultex.Matcher.do_build_matcher(%Faultex.Injector.RejectInjector{resp_delay: -1})
      end
    end

    test "raises ArgumentError for plain map with invalid percentage" do
      assert_raise ArgumentError, ~r/percentage/, fn ->
        Faultex.Matcher.do_build_matcher(%{percentage: 200})
      end
    end
  end

  describe "do_build_matcher/1 for RandomInjector" do
    test "builds RandomInjector with child injectors" do
      injector = %Faultex.Injector.RandomInjector{
        path: "/api",
        injectors: [
          %Faultex.Injector.ErrorInjector{resp_status: 500},
          %Faultex.Injector.ErrorInjector{resp_status: 503}
        ]
      }

      {matcher, built} = Faultex.Matcher.do_build_matcher(injector)
      assert %Faultex.Matcher{} = matcher
      assert %Faultex.Injector.RandomInjector{} = built
      assert length(built.injectors) == 2

      [first, second] = built.injectors
      assert %Faultex.Injector.ErrorInjector{resp_status: 500} = first
      assert %Faultex.Injector.ErrorInjector{resp_status: 503} = second
    end

    test "raises ArgumentError when injectors is empty" do
      assert_raise ArgumentError, ~r/injectors/, fn ->
        Faultex.Matcher.do_build_matcher(%Faultex.Injector.RandomInjector{injectors: []})
      end
    end

    test "raises ArgumentError when injectors is nil" do
      assert_raise ArgumentError, ~r/injectors/, fn ->
        Faultex.Matcher.do_build_matcher(%Faultex.Injector.RandomInjector{injectors: nil})
      end
    end
  end

  describe "do_build_matcher/1 for ChainInjector" do
    test "builds ChainInjector with child injectors" do
      injector = %Faultex.Injector.ChainInjector{
        path: "/api",
        injectors: [
          %Faultex.Injector.SlowInjector{resp_delay: 100},
          %Faultex.Injector.ErrorInjector{resp_status: 503, resp_body: "timeout"}
        ]
      }

      {matcher, built} = Faultex.Matcher.do_build_matcher(injector)
      assert %Faultex.Matcher{} = matcher
      assert %Faultex.Injector.ChainInjector{} = built
      assert length(built.injectors) == 2

      [first, second] = built.injectors
      assert %Faultex.Injector.SlowInjector{resp_delay: 100} = first
      assert %Faultex.Injector.ErrorInjector{resp_status: 503} = second
    end

    test "raises ArgumentError when injectors is empty" do
      assert_raise ArgumentError, ~r/injectors/, fn ->
        Faultex.Matcher.do_build_matcher(%Faultex.Injector.ChainInjector{injectors: []})
      end
    end
  end

  describe "req_headers_match?/2" do
    test "returns true when expected headers is empty list" do
      assert Faultex.Matcher.req_headers_match?([{"a", "1"}], []) == true
    end

    test "returns true when expected headers is nil" do
      assert Faultex.Matcher.req_headers_match?([{"a", "1"}], nil) == true
    end

    test "returns true when request contains expected header" do
      req = [{"content-type", "application/json"}, {"x-fault", "yes"}]
      assert Faultex.Matcher.req_headers_match?(req, [{"x-fault", "yes"}]) == true
    end

    test "returns false when request lacks expected header" do
      req = [{"content-type", "application/json"}]
      assert Faultex.Matcher.req_headers_match?(req, [{"x-fault", "yes"}]) == false
    end

    test "returns true when all expected headers are present" do
      req = [{"a", "1"}, {"b", "2"}, {"c", "3"}]
      assert Faultex.Matcher.req_headers_match?(req, [{"a", "1"}, {"b", "2"}]) == true
    end

    test "returns false when any expected header is missing" do
      req = [{"a", "1"}, {"c", "3"}]
      assert Faultex.Matcher.req_headers_match?(req, [{"a", "1"}, {"b", "2"}]) == false
    end
  end
end
