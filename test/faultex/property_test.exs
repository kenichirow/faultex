defmodule Faultex.PropertyTest do
  use ExUnit.Case
  use ExUnitProperties

  # -- Generators --

  defp header_gen do
    gen all key <- string(:alphanumeric, min_length: 1, max_length: 20),
            value <- string(:alphanumeric, min_length: 1, max_length: 40) do
      {String.downcase(key), value}
    end
  end

  defp header_list_gen do
    uniq_list_of(header_gen(), min_length: 0, max_length: 10, uniq_fun: fn {k, _} -> k end)
  end

  defp path_segment_gen do
    one_of([
      map(string(:alphanumeric, min_length: 1, max_length: 10), &String.downcase/1),
      map(string(:alphanumeric, min_length: 1, max_length: 10), &("*" <> &1)),
      map(string(:alphanumeric, min_length: 1, max_length: 10), &(":" <> &1))
    ])
  end

  defp path_gen do
    gen all segments <- list_of(path_segment_gen(), min_length: 1, max_length: 5) do
      "/" <> Enum.join(segments, "/")
    end
  end

  defp injector_with_percentage_gen(percentage) do
    one_of([
      constant(%Faultex.Injector.ErrorInjector{percentage: percentage}),
      constant(%Faultex.Injector.SlowInjector{percentage: percentage}),
      constant(%Faultex.Injector.RejectInjector{percentage: percentage})
    ])
  end

  defp injector_with_resp_delay_gen(resp_delay) do
    one_of([
      constant(%Faultex.Injector.ErrorInjector{resp_delay: resp_delay}),
      constant(%Faultex.Injector.SlowInjector{resp_delay: resp_delay}),
      constant(%Faultex.Injector.RejectInjector{resp_delay: resp_delay})
    ])
  end

  # -- Properties --

  describe "sampled?/1" do
    property "returns boolean for any valid percentage" do
      check all p <- integer(0..100) do
        assert is_boolean(Faultex.Matcher.sampled?(p))
      end
    end

    property "converges to expected ratio over many trials" do
      check all p <- integer(1..99) do
        n = 1000
        hits = Enum.count(1..n, fn _ -> Faultex.Matcher.sampled?(p) end)
        ratio = hits / n
        assert_in_delta ratio, p / 100, 0.1
      end
    end
  end

  describe "req_headers_match?/2" do
    property "returns true when expected is empty list" do
      check all req <- header_list_gen() do
        assert Faultex.Matcher.req_headers_match?(req, []) == true
      end
    end

    property "returns true when expected is nil" do
      check all req <- header_list_gen() do
        assert Faultex.Matcher.req_headers_match?(req, nil) == true
      end
    end

    property "returns true when expected is a subset of req_headers" do
      check all req <- uniq_list_of(header_gen(), min_length: 1, max_length: 10, uniq_fun: fn {k, _} -> k end),
                n <- integer(1..length(req)) do
        subset = Enum.take_random(req, n)
        assert Faultex.Matcher.req_headers_match?(req, subset) == true
      end
    end

    property "returns false when expected contains a header not in req_headers" do
      # header_gen produces alphanumeric-only keys, so "x--" prefix structurally guarantees no collision
      check all req <- header_list_gen(),
                suffix <- string(:alphanumeric, min_length: 1, max_length: 10),
                value <- string(:alphanumeric, min_length: 1, max_length: 40) do
        extra = {"x--" <> String.downcase(suffix), value}
        assert Faultex.Matcher.req_headers_match?(req, [extra]) == false
      end
    end
  end

  describe "build_path_match/1" do
    property "preserves segment count" do
      check all path <- path_gen() do
        segments = Faultex.Matcher.split(path)
        {_vars, path_match} = Faultex.Matcher.build_path_match(path)
        assert length(path_match) == length(segments)
      end
    end

    property "wildcard segments produce vars, literal segments do not" do
      check all path <- path_gen() do
        segments = Faultex.Matcher.split(path)
        {vars, _path_match} = Faultex.Matcher.build_path_match(path)

        expected_var_count =
          Enum.count(segments, fn seg ->
            String.starts_with?(seg, "*") or String.starts_with?(seg, ":")
          end)

        assert length(vars) == expected_var_count
      end
    end

    property "literal segments appear in path_match unchanged" do
      check all path <- path_gen() do
        segments = Faultex.Matcher.split(path)
        {_vars, path_match} = Faultex.Matcher.build_path_match(path)

        literals = Enum.filter(segments, fn seg ->
          not String.starts_with?(seg, "*") and not String.starts_with?(seg, ":")
        end)

        path_match_literals = Enum.filter(path_match, &is_binary/1)
        assert path_match_literals == literals
      end
    end
  end

  describe "validation" do
    property "percentage outside 0..100 raises ArgumentError for any injector type" do
      check all p <- one_of([integer(-10_000_000..-1), integer(101..10_000_000)]),
                injector <- injector_with_percentage_gen(p) do
        assert_raise ArgumentError, fn ->
          Faultex.Matcher.do_build_matcher(injector)
        end
      end
    end

    property "valid percentage does not raise for any injector type" do
      check all p <- integer(0..100),
                injector <- injector_with_percentage_gen(p) do
        {matcher, _injector} = Faultex.Matcher.do_build_matcher(injector)
        assert %Faultex.Matcher{} = matcher
      end
    end

    property "negative resp_delay raises ArgumentError for any injector type" do
      check all d <- integer(-10_000_000..-1),
                injector <- injector_with_resp_delay_gen(d) do
        assert_raise ArgumentError, fn ->
          Faultex.Matcher.do_build_matcher(injector)
        end
      end
    end

    property "non-positive resp_status raises ArgumentError" do
      check all s <- integer(-10_000_000..0) do
        assert_raise ArgumentError, fn ->
          Faultex.Matcher.do_build_matcher(%Faultex.Injector.ErrorInjector{resp_status: s})
        end
      end
    end
  end

  describe "sampled?/1 with custom RNG" do
    setup do
      on_exit(fn -> Application.delete_env(:faultex, :rand_uniform) end)
    end

    property "custom RNG returning value < percentage always yields true" do
      check all p <- integer(1..100) do
        Application.put_env(:faultex, :rand_uniform, fn _max -> p - 1 end)
        assert Faultex.Matcher.sampled?(p) == true
      end
    end

    property "custom RNG returning value >= percentage always yields false" do
      check all p <- integer(0..99) do
        Application.put_env(:faultex, :rand_uniform, fn _max -> p end)
        assert Faultex.Matcher.sampled?(p) == false
      end
    end
  end

  describe "do_build_matcher/1" do
    property "built ErrorInjector always has non-nil response fields" do
      check all status <- one_of([constant(nil), positive_integer()]),
                body <- one_of([constant(nil), string(:alphanumeric, max_length: 50)]),
                delay <- one_of([constant(nil), integer(0..100)]) do
        injector = %Faultex.Injector.ErrorInjector{
          resp_status: status,
          resp_body: body,
          resp_delay: delay
        }

        {_matcher, built} = Faultex.Matcher.do_build_matcher(injector)

        assert is_integer(built.resp_status) and built.resp_status > 0
        assert is_binary(built.resp_body)
        assert is_list(built.resp_headers)
        assert is_integer(built.resp_delay) and built.resp_delay >= 0
      end
    end

    property "non-nil input values are preserved as-is" do
      check all status <- positive_integer(),
                body <- string(:alphanumeric, min_length: 1, max_length: 50),
                delay <- integer(0..10_000) do
        injector = %Faultex.Injector.ErrorInjector{
          resp_status: status,
          resp_body: body,
          resp_delay: delay
        }

        {_matcher, built} = Faultex.Matcher.do_build_matcher(injector)

        assert built.resp_status == status
        assert built.resp_body == body
        assert built.resp_delay == delay
      end
    end
  end
end
